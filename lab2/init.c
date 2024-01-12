/*
 * Title: Init.c
 * Author: Cody Somers
 * Date: Sept 23, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Creates and starts taskA and taskB, then suspends self.
 * Important Aspects:
 * - Can change the priority of taskA and taskB
 * - Con change the microseconds per tick
 * - Configuration Information
 */

#include <bsp.h>
#include <stdlib.h>
#include <stdio.h>
#include <rtems/error.h>
#include <rtems.h>
#include "mcf5282.h"

rtems_task taskA(rtems_task_argument a); // Tells the code that these functions exist somewhere
rtems_task taskB(rtems_task_argument b);
rtems_id tid2; // id of taskB: Global Variable

rtems_task Init(rtems_task_argument ignored){
rtems_status_code sc; // Error code, used for checking that all functions function without errors.
rtems_id tid; // id of taskA
rtems_task_argument a; // These arguments are unused but necessary for the program to function
rtems_task_argument b;

sc = rtems_task_create (rtems_build_name ('T','S','K','A'), //Creates TaskA
	100, // Priority
	RTEMS_MINIMUM_STACK_SIZE, // Stack size
	RTEMS_PREEMPT|RTEMS_NO_TIMESLICE | RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
        RTEMS_NO_FLOATING_POINT | RTEMS_LOCAL, // Attributes
        &tid); // Task id

if (sc != RTEMS_SUCCESSFUL){ // Check for errors
        printf ("Can't create taskA: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
}

sc = rtems_task_create (rtems_build_name ('T','S','K','B'), //Creates TaskB
  50, // Priority
  RTEMS_MINIMUM_STACK_SIZE, // Stack size
	RTEMS_PREEMPT|RTEMS_NO_TIMESLICE | RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
        RTEMS_NO_FLOATING_POINT | RTEMS_LOCAL, // Attributes
        &tid2); // Task id

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create taskB: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
}

sc = rtems_task_start( // Starts up TaskA
        tid, // Task id
        taskA, // Function name (Entry Point)
        a); // Argument (unused)

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start taskA: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
   }

sc = rtems_task_start( // Starts up TaskB
        tid2, // Task id
        taskB, // Function name (Entry Point)
        b); // Argument (unused)

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start taskB: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
   }
rtems_task_suspend (RTEMS_SELF); // Suspend program so that taskA and taskB continue to function.
}

/* configuration information */
/* NOTICE: the clock driver is explicitly enabled */
#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER
#define CONFIGURE_MICROSECONDS_PER_TICK 1000 // 1.000 millisecond

#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER

#define CONFIGURE_MAXIMUM_TASKS            3

#define CONFIGURE_MAXIMUM_SEMAPHORES       5

#define CONFIGURE_RTEMS_INIT_TASKS_TABLE

#define CONFIGURE_USE_MINIIMFS_AS_BASE_FILESYSTEM

#define CONFIGURE_INIT

#include <rtems/confdefs.h>
/* end of configuration information */

/* end of 'init.c' file */
