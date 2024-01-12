/*
 * Starts taskA and taskB, then ends self.
 */

#include <bsp.h>

#include <stdlib.h>
#include <stdio.h>

#include <rtems/error.h>
rtems_task taskA(rtems_task_argument a);
rtems_task taskB(rtems_task_argument b);

rtems_task Init(
  rtems_task_argument ignored
)
{
rtems_status_code sc;
rtems_id tid;
rtems_id tid2;
rtems_task_argument a;
rtems_task_argument b;

sc = rtems_task_create (rtems_build_name ('T','S','K','A'),
	50,
	RTEMS_MINIMUM_STACK_SIZE,
	RTEMS_PREEMPT|RTEMS_NO_TIMESLICE|RTEMS_NO_ASR|
                                       RTEMS_INTERRUPT_LEVEL(0),
        RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL,
        &tid);

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create task: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
}

sc = rtems_task_create (rtems_build_name ('T','S','K','B'),
        100,
        RTEMS_MINIMUM_STACK_SIZE,
	RTEMS_PREEMPT|RTEMS_NO_TIMESLICE|RTEMS_NO_ASR|
                                       RTEMS_INTERRUPT_LEVEL(0),
        RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL,
        &tid2);

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create task: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
}

sc = rtems_task_start(
        tid,
        taskA,
	a
);

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create task: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
   }

sc = rtems_task_start(
        tid2,
        taskB,
        b
);

if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't create task: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
   }
rtems_task_suspend (RTEMS_SELF);
}
/* configuration information */

/* NOTICE: the clock driver is explicitly disabled */
#define CONFIGURE_APPLICATION_DOES_NOT_NEED_CLOCK_DRIVER

#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER

#define CONFIGURE_MAXIMUM_TASKS            3

#define CONFIGURE_MAXIMUM_SEMAPHORES       5

#define CONFIGURE_RTEMS_INIT_TASKS_TABLE

#define CONFIGURE_USE_MINIIMFS_AS_BASE_FILESYSTEM

#define CONFIGURE_INIT

#include <rtems/confdefs.h>

/* end of configuration information */


/* end of 'init.c' file */
