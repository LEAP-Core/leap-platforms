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

// Foundation code for SW-only projects
// Instantiate the user application.
// Run the user application.

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

    // Initialize the application.
    APPLICATION  app     = new APPLICATION_CLASS(vp);

    app->Init(argc, argv);

    // transfer control to Application
    int ret_val = app->Run(argc, argv);

    // cleanup and exit
    delete app;

    return ret_val;
}
