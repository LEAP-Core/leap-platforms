//
// leap-fpga-ctrl
//
//   Control the user's ability to program an FPGA.  This program will be
//   setuid root so it can enable/disable buses, change protections on
//   FPGA programming devices and manage reservations of FPGAs to avoid
//   interrupting active experiments.
//
//   The program controls many things:
//     - The PCIe bus
//     - Access to a programming cable
//     - Access to the FPGA's kernel device driver
//
//   Author: Michael Adler
//

#define CFG_FILE   CONFDIR "/config"
#define CONFIG_DIR SCRIPTSDIR "/"
#define RES_DIR    LOCKDIR "/"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <error.h>
#include <pwd.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include "iniparser.h"

typedef enum
{
    STATE_FREE,
    STATE_RESERVED,
    STATE_PROGRAM,
    STATE_ACTIVE,
    STATE_RESET,
    STATE_LAST              // Must be last
}
FPGA_STATE_T;

typedef enum
{
    SHOW_STATE_ALL,
    SHOW_STATE_STATUS,
    SHOW_STATE_SIGNATURE
}
FPGA_SHOW_STATE_T;

static int opt_debug = 0;
static int opt_force = 0;

//
// Configuration file database
//
static dictionary *cfg = NULL;

//
// State for chosen device extracted from configuration file
//
static int cfg_id = 0;
static char *cfg_name = NULL;
static char *cfg_class = NULL;
static int  cfg_has_script = 0;
static char *cfg_fpga_dev = NULL;
static char *cfg_bus_id = NULL;
static char *cfg_prog_cable_id = NULL;
static char cfg_res_file[1024];

void state_print(FILE *f, FPGA_STATE_T state)
{
    char *s;

    switch (state)
    {
      case STATE_FREE:
        s = "Free";
        break;
      case STATE_RESERVED:
        s = "Reserved";
        break;
      case STATE_PROGRAM:
        s = "Programming";
        break;
      case STATE_ACTIVE:
        s = "Active";
        break;
      default:
        s = "Unknown";
        break;
    }

    fprintf(f, "%s", s);
}


// ========================================================================
//
// Invoke configuration helper script
//
// ========================================================================

void invoke_helper_script(FPGA_STATE_T state)
{
    pid_t pid;
    struct stat statb;
    char script[1024];
    char *cmd;

    //
    // Not all state changes cause the script to be run
    //
    switch (state)
    {
      case STATE_PROGRAM:
        cmd = "program";
        break;

      case STATE_ACTIVE:
        cmd = "activate";
        break;

      default:
        return;
    }

    //
    // Nothing to do if there is no script
    //

    if (! cfg_has_script) {
        if (opt_debug)
        {
            fprintf(stderr, "No device specific configuration script needed\n");
        }

        return;
    }

    if ((strlen(CONFIG_DIR) + strlen(cfg_class) + 1) >= sizeof(script))
    {
        error(1, 0, "Error - Configuration script path too long");
    }

    strcpy(script, CONFIG_DIR);
    strcat(script, cfg_class);

    // Does the file exist?
    if ((stat(script, &statb) == -1) ||
        ! S_ISREG(statb.st_mode))
    {
        error(1, 0, "Error - Requested control script not found");
    }

    if (opt_debug)
    {
        fprintf(stderr, "Invoking device specific configuration script\n");
    }

    pid = fork();
    if (pid == -1) error(1, 0, "Error - fork() failed");

    if (pid != 0)
    {
        // Parent waits for the child to exit and checks status
        int status;
        wait(&status);
        if (WEXITSTATUS(status) != 0)
        {
            error(1, 0, "Error - %s - exit status %d", script, WEXITSTATUS(status));
        }
    }
    else
    {
        // Child
        char idbuf[16];
        if (snprintf(idbuf, sizeof(idbuf), "%d", cfg_id) >= sizeof(idbuf))
        {
            error(1, errno, "Error - cfg_id too large (%d)", cfg_id);
        }

        if (cfg_fpga_dev != NULL)
        {
            execl(script, script, cmd, idbuf, cfg_fpga_dev, NULL);
        }
        else 
        {
            execl(script, script, cmd, idbuf, NULL);
        }

        error(1, errno, "Error - Failed to execute script %s", script);
    }
}


// ========================================================================
//
// Configuration file access
//
// ========================================================================

//
// Get a configuration string given an FPGA device name and a key.
//
char *cfg_get_str(char *dev, char *key)
{
    char buf[1024];

    if (strlen(dev) + strlen(key) + 2 > sizeof(buf))
    {
        error(1, 0, "Error - cfg_get_str -- string too long");
    }

    strcpy(buf, dev);
    strcat(buf, ":");
    strcat(buf, key);

    return iniparser_getstring(cfg, buf, NULL);
}


//
// Load configuration for a specified FPGA device id.
//
void cfg_load_dev(int id)
{
    char *sec;
    char *has_script;

    if (id >= iniparser_getnsec(cfg))
    {
        error(1, 0, "Error - illegal device ID");
    }

    sec = iniparser_getsecname(cfg, id);

    cfg_id = id;
    cfg_name = sec;
    cfg_class = cfg_get_str(sec, "class");

    has_script = cfg_get_str(sec,"has_control_script");
    if (! has_script)
    {
        has_script = "no";
    }
    cfg_has_script = !strcmp(has_script,"yes");

    cfg_fpga_dev = cfg_get_str(sec, "dev");
    cfg_bus_id = cfg_get_str(sec, "bus_id");
    cfg_prog_cable_id = cfg_get_str(sec, "prog_cable_id");

    // Device-specific reservation lock file
    if (strlen(RES_DIR) + strlen(sec) + 1 > sizeof(cfg_res_file))
    {
        error(1, 0, "Error - reservation file path too long");
    }
    strcpy(cfg_res_file, RES_DIR);
    strcat(cfg_res_file, sec);
}


//
// Validate configuration file.
//
void cfg_validate()
{
    int i;

    int n_sec = iniparser_getnsec(cfg);
    if (n_sec == 0)
    {
        error(1, 0, "Error - Configuration file doesn't describe any devices.");
    }

    if (opt_debug)
    {
        fprintf(stderr, "Configuration file contents:\n");
        iniparser_dump(cfg, stderr);
        fprintf(stderr, "\n");
    }

    for (i = 0; i < n_sec; i++)
    {
        char *dev = iniparser_getsecname(cfg, i);

        if (cfg_get_str(dev, "class") == NULL)
        {
            error(1, 0, "Error - Device %s has no 'class' key", dev);
        }

        if ((cfg_get_str(dev, "kernel-module-name") != NULL) &&
            (cfg_get_str(dev, "kernel-module-path") == NULL))
        {
            error(1, 0, "Error - Device %s specifies kernel module name but no path", dev);
        }
    }
}


// ========================================================================
//
// Device management
//
// ========================================================================

//
// change_current_reservation --
//   Open the lock file and determine whether a transition from the current
//   reservation state to the new one is legal.  Update the reservation.
//
//   NOTE:  The lock file is left OPEN even though no handle is returned.
//          This is to make it impossible for another program to update the
//          state until this instance of the program exits.
//
int change_current_reservation(FPGA_STATE_T newState, char *newSignature)
{
    int lockf;
    FILE *lf;
    struct flock lock;
    uid_t owner;
    uid_t myUid;
    FPGA_STATE_T oldState;
    char signature[512];
    int nFields;
    int n_retry;

    // Open the lock file.  Create it if needed.
    lockf = open(cfg_res_file, O_RDWR | O_CREAT, 00644);
    if (lockf == -1)
    {
        error(1, 0, "Error - Failed to open lock file: %s", cfg_res_file);
    }

    // Lock the file so no other processes can take over
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    lock.l_start = 0;
    lock.l_len = 0;
    n_retry = 0;
    while (1)
    {
        if (! fcntl(lockf, F_SETLK, &lock))
        {
            // Got the lock
            break;
        }

        if (n_retry++ == 20)
        {
            error(1, 0, "Error - Failed to acquire lock file: %s", cfg_res_file);
        }

        sleep(1);
    }

    //
    // Read the current state
    //
    lf = fdopen(lockf, "rw+");
    nFields = fscanf(lf, "%d %d %511s", &owner, &oldState, signature);
    if ((nFields < 2) || (oldState >= STATE_LAST))
    {
        owner = 0;
        oldState = STATE_FREE;
    }

    //
    // Compute the new signature
    //
    if (newState == STATE_PROGRAM)
    {
        if (newSignature != NULL)
        {
            // Adding a signature.  Old state must also be PROGRAM.
            if (oldState != STATE_PROGRAM)
            {
                error(1, 0, "Error - Must be in PROGRAM state to add a signature");
            }
            strncpy(signature, newSignature, sizeof(signature));
            signature[sizeof(signature)-1] = 0;
        }
        else
        {
            signature[0] = 0;
        }
    }
    else if (newState == STATE_RESET)
    {
        // Drop old signature for reset
        signature[0] = 0;
        newState = STATE_FREE;
    }
    else if (nFields < 3)
    {
        // No old signature to preserve
        signature[0] = 0;
    }

    myUid = getuid();
    
    if (oldState != STATE_FREE)
    {
        struct passwd *pw = getpwuid(owner);

        if (myUid == owner)
        {
            // I already own the device.  Don't allow a reservation, since that
            // would allow me to think I've allocated the same device twice.
            if (newState == STATE_RESERVED)
            {
                close(lockf);
                return 0;
            }
        }
        else if (newState <= STATE_RESERVED)
        {
            // Trying to reserve a device locked by somebody else
            if (opt_force)
            {
                // Somebody else owns it, but we'll steal the reservation
                fprintf(stderr, "Stealing reservation from %s\n",
                        (pw != NULL) ? pw->pw_name : "<unknown user>");
            }
            else if (newState == STATE_RESERVED)
            {
                // Try a different device
                close(lockf);
                return 0;
            }
            else
            {
                error(1, 0, "Error - FPGA locked by %s", (pw != NULL) ? pw->pw_name : "<unknown user>");
            }
        }
        else
        {
            error(1, 0, "Error - FPGA locked by %s", (pw != NULL) ? pw->pw_name : "<unknown user>");
        }
    }

    if ((oldState == STATE_FREE) && (newState > STATE_RESERVED))
    {
        error(1, 0, "Error - Reservation required");
    }
    else
    {
        // Update the state in the file.
        rewind(lf);
        if (fprintf(lf, "%d %d %s\n", myUid, newState, signature) < 0)
        {
            error(1, 0, "Error - Error writing to lock file: %s", cfg_res_file);
        }

        fflush(lf);
        ftruncate(lockf, ftell(lf));
    }

    //
    // Lock file is left OPEN.  See note in routine description.
    //
    return 1;
}

//
// current_reservation_state --
//   Print current reservation state
//
void current_reservation_state(FILE *of, FPGA_SHOW_STATE_T show)
{
    FILE *lf;
    FPGA_STATE_T oldState;
    uid_t owner;
    char signature[512];
    int nFields = 0;

    lf = fopen(cfg_res_file, "r");
    if (lf == NULL)
    {
        owner = 0;
        oldState = STATE_FREE;
    }
    else if (((nFields = fscanf(lf, "%d %d %511s", &owner, &oldState, signature)) < 2) ||
             (oldState >= STATE_LAST))
    {
        owner = 0;
        oldState = STATE_FREE;
    }

    if (nFields >= 3)
    {
        signature[sizeof(signature)-1] = 0;
    }
    else
    {
        signature[0] = 0;
    }

    switch (show)
    {
      case SHOW_STATE_ALL:
        fprintf(of, "  Current state: ");
        state_print(of, oldState);
        fprintf(of, "\n");

        if (oldState != STATE_FREE)
        {
            struct passwd *pw = getpwuid(owner);
            if (pw != NULL)
            {
                fprintf(of, "  Current owner: %s\n", pw->pw_name);
            }
        }

        if (signature[0])
        {
            fprintf(of, "  Current signature: %s\n", signature);
        }
        break;

      case SHOW_STATE_STATUS:
        state_print(of, oldState);
        fprintf(of, "\n");
        break;

      case SHOW_STATE_SIGNATURE:
        if (signature[0])
        {
            fprintf(of, "%s\n", signature);
        }
        break;
    }
}


//
// set_fpga_device_access --
//   Pass true to enable and false to disable user access to the fpga device.
//
void set_fpga_device_access(int user_access, int quiet)
{
    int prot = user_access ? 00600 : 00400;
    char *msg = user_access ? "Enabling" : "Disabling";
    uid_t tgt_uid = user_access ? getuid() : 0;
    struct stat statb;

    if (cfg_fpga_dev == NULL) return;

    if (stat(cfg_fpga_dev, &statb) == -1)
    {
        if (errno == ENOENT) return;
        error(1, errno, "Error - FPGA device %s", cfg_fpga_dev);
    }

    if (((statb.st_mode & 00777) != prot) || (statb.st_uid != tgt_uid))
    {
        // Protection isn't what we want.  Change it.
        if (! quiet)
        {
            fprintf(stderr, " %s FPGA device %s access...\n", msg, cfg_name);
        }
        ;
        if ((chown(cfg_fpga_dev, tgt_uid, -1) == -1) ||
            (chmod(cfg_fpga_dev, prot) == -1))
        {
            error(1, 0, "Error - Failed to change protection of %s", cfg_fpga_dev);
        }
    }
}



//---------------------------------------------------------------------------
//
// Initiate requests
//
//---------------------------------------------------------------------------

//
// reserve --
//   Reserve an FPGA.
//
void reserve(char *class)
{
    int i;
    int res_id = -1;

    if (class == NULL)
    {
        error(1, 0, "Error - Reservation class must be specified with --reserve");
    }

    if (opt_debug)
    {
        fprintf(stderr, "Seeking FPGA of class %s\n", class);
    }

    for (i = 0; i < iniparser_getnsec(cfg); i++)
    {
        if (! strcmp(class, cfg_get_str(iniparser_getsecname(cfg, i), "class")))
        {
            if (opt_debug)
            {
                fprintf(stderr, "Device %s matches class %s\n",
                        iniparser_getsecname(cfg, i), class);
            }
            
            cfg_load_dev(i);

            if (change_current_reservation(STATE_RESERVED, NULL))
            {
                if (opt_debug) fprintf(stderr, "Reservation successful\n");
                res_id = i;
                break;
            }
        }
    }

    if (res_id == -1)
    {
        error(1, 0, "Error - Failed to find free device matching requested class");
    }

    set_fpga_device_access(0, 0);

    // Print the device ID.  Scripts invoking this program will use the device
    // ID in later requests.
    printf("%d\n", res_id);
}

    
//
// program_dev --
//   Disable the bus in preparation for programming the FPGA.
//
//   Tasks:
//     - Disable bus
//     - Grant user access to the programming cable
//
void program_dev()
{
    change_current_reservation(STATE_PROGRAM, NULL);
    set_fpga_device_access(0, 0);
    invoke_helper_script(STATE_PROGRAM);
}

//
// configure --
//   Runs an FPGA specific configuration script located in the CONFIG_DIR.
//
//   Tasks:
//     - Run arbitrary system configuration script for specific FPGA
//
void configure(const char* script)
{
    char *command;
}


//
// activate_dev --
//   Enable the device after programming it.
//
//   Tasks:
//     - Disable access to the programming cable
//     - Enable bus
//     - Load the kernel driver for the FPGA
//
void activate_dev()
{
    change_current_reservation(STATE_ACTIVE, NULL);
    invoke_helper_script(STATE_ACTIVE);
    set_fpga_device_access(1, 0);
}


//
// drop_reservation --
//   No longer using or programming the FPGA
//
//   Tasks:
//     - Disable access to the programming cable
//     - Remove the kernel driver for the FPGA
//
void drop_reservation()
{
    change_current_reservation(STATE_FREE, NULL);
    set_fpga_device_access(0, 0);
}


//
// reset --
//   Remove the programmed signature and drop any reservations
//
//   Tasks:
//     - Disable access to the programming cable
//     - Remove the kernel driver for the FPGA
//
void reset()
{
    change_current_reservation(STATE_RESET, NULL);
    set_fpga_device_access(0, 1);
}


//
// getconfig --
//   Print some piece of device configuration state needed by workload scripts.
//
void get_config(char *req)
{
    if (! strcmp(req, "dev"))
        printf("%s\n", cfg_fpga_dev ? cfg_fpga_dev : "");
    else if (! strcmp(req, "name"))
        printf("%s\n", cfg_name ? cfg_name : "");
    else if (! strcmp(req, "class"))
        printf("%s\n", cfg_class ? cfg_class : "");
    else if (! strcmp(req, "bus_id"))
        printf("%s\n", cfg_bus_id ? cfg_bus_id : "");
    else if (! strcmp(req, "prog_cable_id"))
        printf("%s\n", cfg_prog_cable_id ? cfg_prog_cable_id : "");
    else if (! strcmp(req, "id"))
        printf("%d\n", cfg_id);
    else
        error(1, 0, "Error - Unexpected getconfig request (%s)", req);
}


void usage()
{
    fprintf(stderr, "Usage: leap-fpga-ctrl <--reserve[=FPGA class] |\n");
    fprintf(stderr, "                       --program |\n");
    fprintf(stderr, "                       --activate |\n");
    fprintf(stderr, "                       --drop-reservation |\n");
    fprintf(stderr, "                       --reset |\n");
    fprintf(stderr, "                       --setsignature |\n");
    fprintf(stderr, "                       --getsignature |\n");
    fprintf(stderr, "                       --getconfig <param> |\n");
    fprintf(stderr, "                       --status>\n");
    fprintf(stderr, "                       [--device-id=<device number>]\n");
    fprintf(stderr, "                       [--debug]\n");
    fprintf(stderr, "                       [--force]\n\n");
    fprintf(stderr, "    --force may be specified to override other user's reservations\n");
    fprintf(stderr, "\n");
    exit(1);
}

int main(int argc, char *argv[])
{
    int opt;
    int opt_idx;
    char *signature = NULL;
    char *getconfig = NULL;

    static int req_reserve = 0;
    static char *req_reserve_class = NULL;
    static int req_program_dev = 0;
    static int req_activate_dev = 0;
    static int req_drop_reservation = 0;
    static int req_reset = 0;
    static int req_set_signature = 0;
    static int req_get_signature = 0;
    static int req_get_state = 0;
    static int req_get_config = 0;
    static int query_status = 0;
    static int req_dev_id = -1;

    enum OPTS
    {
        OPT_DUMMY,          // 0 position -- not used
        OPT_RESERVE,
        OPT_SIGNATURE,
        OPT_GET_CONFIG,
        OPT_DEVICE_ID
    };

    // Load the config file
    cfg = iniparser_load(CFG_FILE);
    if (cfg == NULL)
    {
        error(1, 0, "Error - configuration file load failed");
    }

    while (1)
    {
        static struct option long_options[] =
        {
            { "program", no_argument, &req_program_dev, 1 },
            { "activate", no_argument, &req_activate_dev, 1 },
            { "reserve", optional_argument, NULL, OPT_RESERVE },
            { "drop-reservation", no_argument, &req_drop_reservation, 1 },
            { "reset", no_argument, &req_reset, 1 },
            { "force", no_argument, &opt_force, 1 },
            { "debug", no_argument, &opt_debug, 1 },
            { "status", no_argument, &query_status, 1 },
            { "setsignature", required_argument, NULL, OPT_SIGNATURE },
            { "getsignature", no_argument, &req_get_signature, 1 },
            { "getstate", no_argument, &req_get_state, 1 },
            { "getconfig", required_argument, NULL, OPT_GET_CONFIG },
            { "device-id", required_argument, NULL, OPT_DEVICE_ID },
            { 0, 0, 0, 0 }
        };

        opt = getopt_long(argc, argv, "", long_options, &opt_idx);
        if (-1 == opt) break;

        switch (opt)
        {
          case 0:
            // Simple argument
            break;

            //
            // --reserve takes an optional argument: the FPGA device class
            // to reserve.  If no argument is supplied then exactly one FPGA
            // device must be defined in the configuration file.
            //
          case OPT_RESERVE:
            req_reserve = 1;
            if (optarg)
            {
                req_reserve_class = strdup(optarg);
            }
            break;

          case OPT_SIGNATURE:
            req_set_signature = 1;
            signature = strdup(optarg);
            if (signature == NULL) error(1, 0, "Error - strdup() failed");
            break;

          case OPT_GET_CONFIG:
            req_get_config = 1;
            getconfig = strdup(optarg);
            if (getconfig == NULL) error(1, 0, "Error - strdup() failed");
            break;

          case OPT_DEVICE_ID:
            req_dev_id = atoi(optarg);
            if ((req_dev_id < 0) || (req_dev_id >= iniparser_getnsec(cfg)))
            {
                error(1, 0, "Error - Illegal device id");
            }
            break;

          default:
            usage();
        }
    }

    //
    // Verify that one option is chosen
    //
    if (req_reserve +
        req_program_dev +
        req_activate_dev +
        req_drop_reservation +
        req_reset +
        req_set_signature +
        req_get_signature +
        req_get_state +
        req_get_config +
        query_status != 1)
    {
        usage();
    }

    // Check the configuration file
    cfg_validate();

    if (req_dev_id >= 0)
    {
        // Load details of requested device.
        cfg_load_dev(req_dev_id);
        if (req_reserve)
        {
            error(1, 0, "Error - --device-id may not be specified with --reserve");
        }
    }
    else if (iniparser_getnsec(cfg) == 1)
    {
        // Exactly one device is described.  Load it as the default.
        // This is mainly for compatibility with old scripts.
        cfg_load_dev(0);
        if (req_reserve_class == NULL)
        {
            req_reserve_class = cfg_get_str(iniparser_getsecname(cfg, 0), "class");
        }
    }
    else if (! req_reserve && ! query_status)
    {
        error(1, 0, "Error - --device-id must be specified");
    }

    if (req_reset) reset();
    if (req_reserve) reserve(req_reserve_class);
    if (req_program_dev) program_dev(signature);
    if (req_activate_dev) activate_dev();
    if (req_drop_reservation) drop_reservation();
    if (req_set_signature) change_current_reservation(STATE_PROGRAM, signature);
    if (req_get_signature) current_reservation_state(stdout, SHOW_STATE_SIGNATURE);
    if (req_get_state) current_reservation_state(stdout, SHOW_STATE_STATUS);
    if (req_get_config) get_config(getconfig);

    if (query_status)
    {
        //
        // Show status for all devices.
        //
        int d;
        for (d = 0; d < iniparser_getnsec(cfg); d++)
        {
            if (d != 0) printf("\n");
            printf("%s:\n", iniparser_getsecname(cfg, d));

            cfg_load_dev(d);
            current_reservation_state(stdout, SHOW_STATE_ALL);
        }
    }

    exit(0);
}
