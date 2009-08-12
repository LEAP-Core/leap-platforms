#ifndef __HARDWARE_DONE_H__
#define __HARDWARE_DONE_H__

#include <pthread.h>

/* Variables storing the hardware status. */
/* These variables should only be modified if this lock is held. */
/* Software can check if hardware is done as follows: */
/* First, check if hardwareFinished == 1. If so, it's done
/* (it finished before the software). Otherwise, sleep until you
/* receive the hardwareFinishedSignal. */

extern pthread_mutex_t hardwareStatusLock;
extern int             hardwareStarted;
extern int             hardwareFinished;
extern int             hardwareExitCode;
extern pthread_cond_t  hardwareFinishedSignal;


#endif
