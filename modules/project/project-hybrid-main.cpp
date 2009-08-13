#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>

#include "asim/syntax.h"

#include "asim/dict/init.h"

#include "asim/provides/command_switches.h"
#include "asim/provides/virtual_platform.h"
#include "asim/provides/low_level_platform_interface.h"
#include "asim/provides/application_env.h"
#include "asim/provides/model.h"


// =======================================
//           PROJECT MAIN
// =======================================

// Foundation code for HW/SW hybrid projects
// Instantiate the virtual platform and application environment.
// Run the user application through the application environment.

// globally visible variables
GLOBAL_ARGS globalArgs;

// main
int main(int argc, char *argv[])
{
    // Set line buffering to avoid fflush() everywhere.  stderr was probably
    // unbuffered already, but be sure.
    setvbuf(stdout, NULL, _IOLBF, 0);
    setvbuf(stderr, NULL, _IOLBF, 0);

    // parse args and place in global array
    globalArgs = new GLOBAL_ARGS_CLASS(argc, argv); // TODO: need a better story here

    // Initialize pthread conditions so we know
    // when the HW & SW are done.

    VIRTUAL_PLATFORM vp         = new VIRTUAL_PLATFORM_CLASS();
    APPLICATION_ENV  appEnv     = new APPLICATION_ENV_CLASS(vp);

    vp->Init(); // TODO: Does this want command line params?

    appEnv->InitApp(argc, argv);

    // transfer control to Application via Environment
    int ret_val = appEnv->RunApp(argc, argv);

    // Application's Main() exited => wait for hardware to be done.
    // The user can use a parameter to indicate the hardware never 
    // terminates (IE because it's a pure server).
    
    if (WAIT_FOR_HARDWARE && !hardwareFinished)
    {
        // We need to wait for it and it's not finished.
        // So we'll wait to receive the signal from the VP.

        // cout << "Waiting for HW..." << endl;
        pthread_mutex_lock(&hardwareStatusLock);
        pthread_cond_wait(&hardwareFinishedSignal, &hardwareStatusLock);
        pthread_mutex_unlock(&hardwareStatusLock);
    }

    // cout << "HW is done." << endl;
    // cleanup and exit
    delete appEnv;
    delete vp;

    return ret_val;
}