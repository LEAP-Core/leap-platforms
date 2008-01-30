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

#define KERNEL_MOD PREFIX "kernel/pchnl.ko"
#define KERNEL_DEV "/dev/pchnl"

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
    STATE_DISABLE_PCI,
    STATE_ENABLE_PCI,
    STATE_LAST              // Must be last
}
FPGA_STATE_T;


static int req_enable_pci = 0;
static int req_disable_pci = 0;
static int req_drop_reservation = 0;
static int force_unlock = 0;
static int query_state = 0;



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
      case STATE_DISABLE_PCI:
        s = "PCI Disabled";
        break;
      case STATE_ENABLE_PCI:
        s = "PCI Enabled";
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
void change_current_reservation(FPGA_STATE_T newState, int force)
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

    if ((oldState + 1 == newState) ||
        ((newState == STATE_FREE) && (force || (oldState == STATE_ENABLE_PCI))))
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
    else
    {
        fprintf(stderr, "hasim-fpga-ctrl: Illegal state transition (");
        state_print(stderr, oldState);
        fprintf(stderr, " -> ");
        state_print(stderr, newState);
        fprintf(stderr, ")\n");
        exit(1);
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
// set_pci_state --
//   Tell the kernel to enable or disable the FPGA's PCIe bus
//
void set_pci_state(FPGA_STATE_T state)
{
    char req;
    int f;

    switch (state)
    {
      case STATE_DISABLE_PCI:
        printf("hasim-fpga-ctrl: Turing off PCIe bus...\n");
        req = '0';
        break;
      case STATE_ENABLE_PCI:
        printf("hasim-fpga-ctrl: Turing on PCIe bus...\n");
        req = '1';
        break;
      default:
        error("Unexpected argument to set_pci_state()");
    }

    f = open(PCIE_POWER, O_WRONLY);
    if (f == -1) error("Failed to open PCIe power control file " PCIE_POWER);

    if (write(f, &req, 1) != 1)
    {
        error("Write failed to PCIe power control file " PCIE_POWER);
    }

    close(f);
}


//
// disable_pci --
//   Disable the PCI bus in preparation for programming the FPGA.
//
//   Tasks:
//     - Disable PCI
//     - Grant user access to the programming cable
//
void disable_pci()
{
    change_current_reservation(STATE_DISABLE_PCI, 0);
    set_pci_state(STATE_DISABLE_PCI);
    printf("hasim-fpga-ctrl: Enabling programming cable...\n");
    chmod(USB_PROG, 00666);
}


//
// enable_pci --
//   Enable the PCI bus after programming it.
//
//   Tasks:
//     - Disable access to the programming cable
//     - Enable PCI
//     - Load the kernel driver for the FPGA
//
void enable_pci()
{
    int trips;

    change_current_reservation(STATE_ENABLE_PCI, 0);

    printf("hasim-fpga-ctrl: Disabling programming cable...\n");
    chmod(USB_PROG, 00444);

    set_pci_state(STATE_ENABLE_PCI);

    printf("hasim-fpga-ctrl: Loading kernel driver...\n");
    do_system("/sbin/insmod", KERNEL_MOD);

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


//
// drop_reservation --
//   No longer using or programming the FPGA
//
//   Tasks:
//     - Disable access to the programming cable
//     - Remove the kernel driver for the FPGA
//
void drop_reservation(int force)
{
    change_current_reservation(STATE_FREE, force);

    printf("hasim-fpga-ctrl: Disabling programming cable...\n");
    chmod(USB_PROG, 00444);

    printf("hasim-fpga-ctrl: Unloading kernel driver...\n");
    do_system("/sbin/rmmod", KERNEL_MOD);
}


void usage()
{
    fprintf(stderr, "Usage: hasim-fpga-ctrl <--disable-pci |\n");
    fprintf(stderr, "                        --enable-pci |\n");
    fprintf(stderr, "                        --drop-reservation |\n");
    fprintf(stderr, "                        --force-unlock>\n");
    fprintf(stderr, "                        --state>\n");
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
            { "enable-pci", 0, &req_enable_pci, 1 },
            { "disable-pci", 0, &req_disable_pci, 1 },
            { "drop-reservation", 0, &req_drop_reservation, 1 },
            { "force-unlock", 0, &force_unlock, 1 },
            { "state", 0, &query_state, 1 },
            { "status", 0, &query_state, 1 },
            { 0, 0, 0, 0 }
        };

        opt = getopt_long(argc, argv, "", long_options, &opt_idx);
        if (-1 == opt) break;
    }

    //
    // Verify that one option is chosen
    //
    if (req_enable_pci +
        req_disable_pci +
        req_drop_reservation +
        force_unlock +
        query_state != 1)
    {
        usage();
    }

    if (req_enable_pci) enable_pci();
    if (req_disable_pci) disable_pci();
    if (req_drop_reservation) drop_reservation(0);
    if (force_unlock) drop_reservation(1);
    if (query_state) current_reservation_state(stdout);

    exit(0);
}
