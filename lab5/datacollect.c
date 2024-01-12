/*
 * Title: datacollect.c
 * Author: Cody Somers
 * Date: Oct 14, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Reads the Right Justified Unsigned Result Registers to get the output from the QADC
 * Important Aspects:
 * - Can change the refresh rate at which the data is collected
 * - Stores the values in a global variable
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

int outputArray[8]; // Global variable of output values from ADC

rtems_task datacollect(rtems_task_argument a){
    // List of all result registers for the eight channels
    for(;;){ // Infinite loop
        rtems_task_wake_after((int) rtems_clock_get_ticks_per_second()*0.2); // Wait for half a second
        // Update the result registers
        outputArray[0] = MCF5282_QADC_RJURR(0x0);
        outputArray[1] = MCF5282_QADC_RJURR(0x1);
        outputArray[2] = MCF5282_QADC_RJURR(0x2);
        outputArray[3] = MCF5282_QADC_RJURR(0x3);
        outputArray[4] = MCF5282_QADC_RJURR(0x4);
        outputArray[5] = MCF5282_QADC_RJURR(0x5);
        outputArray[6] = MCF5282_QADC_RJURR(0x6);
        outputArray[7] = MCF5282_QADC_RJURR(0x7);
    }
    rtems_task_suspend (RTEMS_SELF);
}

/* end of 'datacollect.c' file */
