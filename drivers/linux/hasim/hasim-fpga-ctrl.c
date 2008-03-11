//
// hasim-fpga-ctrl
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

#define PREFIX "/usr/hasim/"
#define PCIE_POWER PREFIX "dev/pcie_fpga_power0"
#define USB_PROG   PREFIX "dev/usb_programming_cable0"
#define RES_FILE   PREFIX "reservations/pcie_fpga0"

#define KERNEL_MOD      "pchnl"
#define KERNEL_MOD_PATH PREFIX "kernel/" KERNEL_MOD ".ko"
#define KERNEL_DEV      "/dev/" KERNEL_MOD

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <errno.h>
#include <pwd.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

typedef enum
{
    STATE_FREE,
    STATE_RESERVED,
    STATE_PCI_PROGRAM,
    STATE_PCI_ACTIVE,
    STATE_LAST              // Must be last
}
FPGA_STATE_T;


static int req_reserve = 0;
static int req_program_pci = 0;
static int req_activate_pci = 0;
static int req_drop_reservation = 0;
static int force = 0;
static int query_status = 0;



void error(char *msg)
{
    fprintf(stderr, "hasim-fpga-ctrl: %s\n", msg);
    exit(1);
}


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
      case STATE_PCI_PROGRAM:
        s = "Programming";
        break;
      case STATE_PCI_ACTIVE:
        s = "Active";
        break;
      default:
        s = "Unknown";
        break;
    }

    fprintf(f, "%s", s);
}


void do_system(char *cmd, char *arg)
{
    pid_t pid;

    pid = fork();
    if (pid == -1) error("fork() failed");

    if (pid != 0)
    {
        // Parent
        int status;
        wait(&status);
        if (WEXITSTATUS(status) != 0)
        {
            fprintf(stderr, "Exit status %d from \"%s %s\"\n",
                    WEXITSTATUS(status),
                    cmd, arg);
        }
    }
    else
    {
        // Child
        execl(cmd, cmd, arg, NULL);
        exit(1);
    }
}


//
// change_current_reservation --
//   Open the lock file and determine whether a transition from the current
//   reservation state to the new one is legal.  Update the reservation.
//
//   NOTE:  The lock file is left OPEN even though no handle is returned.
//          This is to make it impossible for another program to update the
//          state until this instance of the program exits.
//
void change_current_reservation(FPGA_STATE_T newState)
{
    int lockf;
    FILE *lf;
    struct passwd *pw;
    struct flock lock;
    uid_t owner;
    uid_t myUid;
    FPGA_STATE_T oldState;

    // Open the lock file.  Create it if needed.
    lockf = open(RES_FILE, O_RDWR | O_CREAT, 00644);
    if (lockf == -1) error("Failed to open lock file " RES_FILE);

    // Lock the file so no other processes can take over
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    lock.l_start = 0;
    lock.l_len = 0;
    if (fcntl(lockf, F_SETLK, &lock))
    {
        error("Failed to acquire lock on file " RES_FILE);
    }

    lf = fdopen(lockf, "rw+");
    if ((fscanf(lf, "%d %d", &owner, &oldState) != 2) ||
        (oldState >= STATE_LAST))
    {
        owner = 0;
        oldState = STATE_FREE;
    }

    myUid = getuid();
    
    if ((oldState != STATE_FREE) && (myUid != owner) && !force)
    {
        // Somebody else owns it
        pw = getpwuid(owner);
        if (pw == NULL)
        {
            error("Failed to map owner UID to name");
        }
        fprintf(stderr, "hasim-fpga-ctrl: FPGA locked by %s\n", pw->pw_name);
        exit(1);
    }

    if ((oldState == STATE_FREE) && (newState != STATE_RESERVED))
    {
        fprintf(stderr, "hasim-fpga-ctrl: Reservation required\n");
        exit(1);
    }
    else
    {
        // Update the state in the file.
        rewind(lf);
        if (fprintf(lf, "%d %d\n", myUid, newState) < 0)
        {
            error("Error writing to lock file " RES_FILE);
        }

        fflush(lf);
        ftruncate(lockf, ftell(lf));
    }

    //
    // Lock file is left OPEN.  See note in routine description.
    //
}

//
// current_reservation_state --
//   Print current reservation state
//
void current_reservation_state(FILE *of)
{
    FILE *lf;
    FPGA_STATE_T oldState;
    uid_t owner;

    lf = fopen(RES_FILE, "r");
    if (lf == NULL)
    {
        owner = 0;
        oldState = STATE_FREE;
    }
    else if ((fscanf(lf, "%d %d", &owner, &oldState) != 2) ||
             (oldState >= STATE_LAST))
    {
        owner = 0;
        oldState = STATE_FREE;
    }

    fprintf(of, "Current state: ");
    state_print(of, oldState);
    fprintf(of, "\n");

    if (oldState != STATE_FREE)
    {
        struct passwd *pw = getpwuid(owner);
        if (pw != NULL)
        {
            fprintf(of, "Current owner: %s\n", pw->pw_name);
        }
    }
}


//
// kernel_driver_is_loaded --
//   Return true if the kernel driver is loaded
//
int kernel_driver_is_loaded()
{
    int is_loaded = 0;
    char mod_name[128];
    FILE *mf = fopen("/proc/modules", "r");

    mod_name[sizeof(mod_name) - 1] = 0;

    if (mf == NULL) error("Failed to open /proc/modules");

    while (fscanf(mf, "%20s %*[^\n]", mod_name)> 0)
    {
        if (strcmp(mod_name, KERNEL_MOD) == 0)
        {
            is_loaded = 1;
            break;
        }
    }

    fclose(mf);

    return is_loaded;
}


//
// set_pci_state --
//   Tell the kernel to enable or disable the FPGA's PCIe bus
//
void set_pci_state(FPGA_STATE_T state)
{
    char req;
    int f;

    switch (state)
    {
      case STATE_PCI_PROGRAM:
        printf("hasim-fpga-ctrl: Turing off PCIe bus...\n");
        req = '0';
        break;
      case STATE_PCI_ACTIVE:
        printf("hasim-fpga-ctrl: Turing on PCIe bus...\n");
        req = '1';
        break;
      default:
        error("Unexpected argument to set_pci_state()");
    }


    if (state == STATE_PCI_PROGRAM)
    {
        //
        // Make sure the kernel driver is unloaded
        //
        if (kernel_driver_is_loaded())
        {
            printf("hasim-fpga-ctrl: Unloading kernel driver...\n");
            do_system("/sbin/rmmod", KERNEL_MOD_PATH);
        }
    }


    //
    // Change the PCI state
    //
    f = open(PCIE_POWER, O_WRONLY);
    if (f == -1) error("Failed to open PCIe power control file " PCIE_POWER);

    if (write(f, &req, 1) != 1)
    {
        error("Write failed to PCIe power control file " PCIE_POWER);
    }

    close(f);


    if (state == STATE_PCI_ACTIVE)
    {
        int trips;

        //
        // Let PCI settle
        //
        sleep(1);

        //
        // Make sure kernel driver is loaded
        //
        if (! kernel_driver_is_loaded())
        {
            printf("hasim-fpga-ctrl: Loading kernel driver...\n");
            do_system("/sbin/insmod", KERNEL_MOD_PATH);
        }

        //
        // Make the kernel driver accessible only to the current user
        //
        trips = 0;
        while (chmod(KERNEL_DEV, 00600) != 0)
        {
            trips += 1;
            if (trips == 15)
            {
                error("Kernel driver never built device file " KERNEL_DEV);
            }
            sleep(1);
        }

        chown(KERNEL_DEV, getuid(), -1);
    }
}


//
// set_prog_cable_access --
//   Pass true to enable and false to disable user access to the programming
//   cable.
//
void set_prog_cable_access(int user_access)
{
    int prot = user_access ? 00666 : 00444;
    char *msg = user_access ? "Enabling" : "Disabling";
    struct stat statb;

    if (stat(USB_PROG, &statb) == -1)
    {
        fprintf(stderr, "hasim-fpga-ctrl: Can't stat %s\n", USB_PROG);
        exit(1);
    }

    if ((statb.st_mode & 00777) != prot)
    {
        // Protection isn't what we want.  Change it.
        printf("hasim-fpga-ctrl: %s programming cable...\n", msg);
        if (chmod(USB_PROG, prot) == -1)
        {
            fprintf(stderr, "hasim-fpga-ctrl: Failed to change protection of %s\n", USB_PROG);
            exit(1);
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
void reserve()
{
    change_current_reservation(STATE_RESERVED);
    set_prog_cable_access(0);
}

    
//
// program_pci --
//   Disable the PCI bus in preparation for programming the FPGA.
//
//   Tasks:
//     - Disable PCI
//     - Grant user access to the programming cable
//
void program_pci()
{
    change_current_reservation(STATE_PCI_PROGRAM);
    set_pci_state(STATE_PCI_PROGRAM);
    set_prog_cable_access(1);
}


//
// activate_pci --
//   Enable the PCI bus after programming it.
//
//   Tasks:
//     - Disable access to the programming cable
//     - Enable PCI
//     - Load the kernel driver for the FPGA
//
void activate_pci()
{
    change_current_reservation(STATE_PCI_ACTIVE);
    set_prog_cable_access(0);
    set_pci_state(STATE_PCI_ACTIVE);
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
    change_current_reservation(STATE_FREE);
    set_prog_cable_access(0);
}


void usage()
{
    fprintf(stderr, "Usage: hasim-fpga-ctrl <--reserve |\n");
    fprintf(stderr, "                        --program |\n");
    fprintf(stderr, "                        --activate |\n");
    fprintf(stderr, "                        --drop-reservation\n");
    fprintf(stderr, "                        --status>\n\n");
    fprintf(stderr, "    --force may be specified to override other user's reservations\n");
    fprintf(stderr, "\n");
    current_reservation_state(stderr);
    exit(1);
}


int main(int argc, char *argv[])
{
    int opt;
    int opt_idx;

    while (1)
    {
        static struct option long_options[] =
        {
            { "program", 0, &req_program_pci, 1 },
            { "activate", 0, &req_activate_pci, 1 },
            { "reserve", 0, &req_reserve, 1 },
            { "drop-reservation", 0, &req_drop_reservation, 1 },
            { "force", 0, &force, 1 },
            { "status", 0, &query_status, 1 },
            { 0, 0, 0, 0 }
        };

        opt = getopt_long(argc, argv, "", long_options, &opt_idx);
        if (-1 == opt) break;
    }

    //
    // Verify that one option is chosen
    //
    if (req_reserve +
        req_program_pci +
        req_activate_pci +
        req_drop_reservation +
        query_status != 1)
    {
        usage();
    }

    if (req_reserve) reserve();
    if (req_program_pci) program_pci();
    if (req_activate_pci) activate_pci();
    if (req_drop_reservation) drop_reservation();
    if (query_status) current_reservation_state(stdout);

    exit(0);
}
