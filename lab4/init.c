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
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <rtems/rtems_bsdnet.h>

rtems_task initialize(rtems_task_argument a); // Tells the code that these functions exist somewhere
rtems_task server(rtems_task_argument a);

rtems_task Init(rtems_task_argument ignored){
    // Start the network
    rtems_bsdnet_initialize_network();
    rtems_status_code sc; // Error code, used for checking that all functions function without errors.
    rtems_id tid; // id of initialize
    rtems_id tid5; // id of server
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
    sc = rtems_task_start( // Starts up Initialization
            tid, // Task id
            initialize, // Function name (Entry Point)
            a); // Argument (unused)
    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start initialize: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

    sc = rtems_task_create (rtems_build_name ('S','E','R','V'), //Creates server
                            50, // Priority
                            RTEMS_MINIMUM_STACK_SIZE, //Stack size
                            RTEMS_PREEMPT | RTEMS_NO_TIMESLICE|RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
                            RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL, // Attributes
                            &tid5); // Task id
    if (sc != RTEMS_SUCCESSFUL) { // Checks for errors
        printf ("Can't create initialize: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }
    sc = rtems_task_start( // Starts up server
            tid5, // Task id
            server, // Function name (Entry Point)
            a); // Argument (unused)
    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start initialize: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

rtems_task_suspend (RTEMS_SELF); // Suspends program so that the other programs continue
exit(0);
}
/* configuration information */
#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER
#define CONFIGURE_MAXIMUM_TASKS            20
#define CONFIGURE_MAXIMUM_SEMAPHORES       20
#define CONFIGURE_RTEMS_INIT_TASKS_TABLE
#define CONFIGURE_USE_MINIIMFS_AS_BASE_FILESYSTEM
#define CONFIGURE_EXECUTIVE_RAM_SIZE	(512*1024)
#define CONFIGURE_LIBIO_MAXIMUM_FILE_DESCRIPTORS 20
#define CONFIGURE_INIT_TASK_STACK_SIZE	(10*1024)
#define CONFIGURE_INIT_TASK_PRIORITY	100
#define CONFIGURE_INIT_TASK_INITIAL_MODES (RTEMS_PREEMPT | \
                                           RTEMS_NO_TIMESLICE | \
                                           RTEMS_NO_ASR | \
                                           RTEMS_INTERRUPT_LEVEL(0))
/* end of configuration information */
/* end of 'init.c' file */

/*
 * Network configuration
 */
#define NETWORK_TASK_PRIORITY	50
static struct rtems_bsdnet_ifconfig netdriver_config = {
        RTEMS_BSP_NETWORK_DRIVER_NAME,
        RTEMS_BSP_NETWORK_DRIVER_ATTACH,
        NULL,
        "10.65.118.226",				//this is the IP address of the board that this program will be run on, change accordingly
        "255.255.255.0"                 // Was originally .128, changed to .0
};
struct rtems_bsdnet_config rtems_bsdnet_config = {
        &netdriver_config,	// Network interface
        NULL,  			// Do not use BOOTP to get network configuration, not entirely sure why...
        NETWORK_TASK_PRIORITY,  // Network task priority (der!)
        512*1024,		// MBUF space
        1024*1024,		// MBUF cluster space
        "EPBRD9",		//name of board (change accordingly)
        "usask.ca",		//domain name
        "10.65.118.1",	//gateway. The same as the IP, but with a 1 at the end.
        "128.233.3.1",		//log host
        "128.233.3.1",		//name server
        "128.233.3.1"		//ntp server
/**/
};

#define CONFIGURE_INIT
#include <rtems/confdefs.h>

/* end of include file */