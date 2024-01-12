/*
 * RTEMS configuration/initialization
 * 
 * This program may be distributed and used for any purpose.
 * I ask only that you:
 *	1. Leave this author information intact.
 *	2. Document any changes you make.
 *
 * W. Eric Norum
 * Saskatchewan Accelerator Laboratory
 * University of Saskatchewan
 * Saskatoon, Saskatchewan, CANADA
 * eric@skatter.usask.ca

This file has been modified by Jay Forrest for the use of EP 414 laboratories
	Last modification: Oct. 12, 2010
 */

#include <bsp.h>
#include <rtems/rtems_bsdnet.h>
#include <stdio.h>
#include <stdlib.h>

rtems_task Init (rtems_task_argument argument);

/*
 * RTEMS Startup Task
 */
rtems_task Init (rtems_task_argument ignored)
{
	// Start the network
	rtems_bsdnet_initialize_network ();

	rtems_task_suspend (RTEMS_SELF);		//Suspend the initialization task
	exit(0);					//Exit program cleanly
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

/*
 * Network configuration
 */
#define NETWORK_TASK_PRIORITY	50
static struct rtems_bsdnet_ifconfig netdriver_config = {
	  RTEMS_BSP_NETWORK_DRIVER_NAME,
	  RTEMS_BSP_NETWORK_DRIVER_ATTACH,
	NULL,
	"128.233.79.8",				//this is the IP address of the board that this program will be run on, change accordingly
	"255.255.255.128"
};
struct rtems_bsdnet_config rtems_bsdnet_config = {
	&netdriver_config,	// Network interface
	NULL,  			// Do not use BOOTP to get network configuration, not entirely sure why...
	NETWORK_TASK_PRIORITY,  // Network task priority (der!)
	512*1024,		// MBUF space
	1024*1024,		// MBUF cluster space
	"EPBRD9",		//name of board (change accordingly)
	"usask.ca",		//domain name
	"128.233.79.3",		//gateway
	"128.233.3.1",		//log host
	"128.233.3.1",		//name server
	"128.233.3.1"		//ntp server
/**/
};

#define CONFIGURE_INIT
#include <rtems/confdefs.h>

/* end of include file */
