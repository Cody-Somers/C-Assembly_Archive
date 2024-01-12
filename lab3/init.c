/*
 * Title: init.c
 * Author: Cody Somers
 * Date: Oct 14, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Creates and starts two tasks (initialize and datacollect), then suspends self.
 * Important Aspects:
 * - Can change the priority of tasks
 * - Configuration Information
 */

#include <bsp.h>
#include <stdlib.h>
#include <stdio.h>
#include <rtems/error.h>
#include <rtems.h>
#include "mcf5282.h"

rtems_task initialize(rtems_task_argument a); // Tells the code that these functions exist somewhere
rtems_task datacollect(rtems_task_argument a);

rtems_task Init(rtems_task_argument ignored){
    rtems_status_code sc; // Error code, used for checking that all functions function without errors.
    rtems_id tid; // id of initialize
    rtems_id tid2; // id of datacollection
    rtems_task_argument a; // Unused variable, but necessary

    sc = rtems_task_create (rtems_build_name ('I','N','I','T'), //Creates initialize
	    50, // Priority
        RTEMS_MINIMUM_STACK_SIZE, //Stack size
	    RTEMS_PREEMPT | RTEMS_NO_TIMESLICE|RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
        RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL, // Attributes
        &tid); // Task id

    if (sc != RTEMS_SUCCESSFUL) { // Checks for errors
            printf ("Can't create initialize: %s\n", rtems_status_text (sc));
            rtems_task_suspend (RTEMS_SELF);
    }

    sc = rtems_task_create (rtems_build_name ('D','A','T','A'), //Creates datacollect
        50, // Priority
        RTEMS_MINIMUM_STACK_SIZE, // Stack size
        RTEMS_PREEMPT|RTEMS_NO_TIMESLICE|RTEMS_NO_ASR|RTEMS_INTERRUPT_LEVEL(0), // Modes
        RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL, // Attributes
        &tid2); // Task id

    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create datacollect: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

    sc = rtems_task_start( // Starts up Initialization
            tid, // Task id
            initialize, // Function name (Entry Point)
            a); // Argument (unused)

    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start initialize: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

    sc = rtems_task_start( // Starts up Datacollection
            tid2, // Task id
            datacollect, // Function name (Entry Point)
            a); // Argument (unused)

    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start data collect: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

rtems_task_suspend (RTEMS_SELF); // Suspends program so that the other programs continue
}
/* configuration information */
/* NOTICE: the clock driver is explicitly enabled */
#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER

#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER

#define CONFIGURE_MAXIMUM_TASKS            3

#define CONFIGURE_MAXIMUM_SEMAPHORES       5

#define CONFIGURE_RTEMS_INIT_TASKS_TABLE

#define CONFIGURE_USE_MINIIMFS_AS_BASE_FILESYSTEM

#define CONFIGURE_INIT

#include <rtems/confdefs.h>
/* end of configuration information */

/* end of 'init.c' file */
