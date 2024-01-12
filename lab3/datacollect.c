/*
 * Title: datacollect.c
 * Author: Cody Somers
 * Date: Oct 14, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Reads the Right Justified Unsigned Result Registers to get the output from the QADC
 * Important Aspects:
 * - Can change the refresh rate at which the data is collected
 */

#include <bsp.h>
#include <stdlib.h>
#include <stdio.h>
#include <rtems/error.h>
#include <rtems.h>
#include "mcf5282.h"

rtems_task datacollect(rtems_task_argument a){
    // List of all result registers for the eight channels
    int b = MCF5282_QADC_RJURR(0x0);
    int c = MCF5282_QADC_RJURR(0x1);
    int d = MCF5282_QADC_RJURR(0x2);
    int e = MCF5282_QADC_RJURR(0x3);
    int f = MCF5282_QADC_RJURR(0x4);
    int g = MCF5282_QADC_RJURR(0x5);
    int h = MCF5282_QADC_RJURR(0x6);
    int i = MCF5282_QADC_RJURR(0x7);
    for(;;){ // Infinite loop
        rtems_task_wake_after(rtems_clock_get_ticks_per_second()*2); // Wait for two seconds
        // Update the result registers
        b = MCF5282_QADC_RJURR(0x0);
        c = MCF5282_QADC_RJURR(0x1);
        d = MCF5282_QADC_RJURR(0x2);
        e = MCF5282_QADC_RJURR(0x3);
        f = MCF5282_QADC_RJURR(0x4);
        g = MCF5282_QADC_RJURR(0x5);
        h = MCF5282_QADC_RJURR(0x6);
        i = MCF5282_QADC_RJURR(0x7);
        // Output into the terminal
        printf("Channel 0 %i \n", b);
        printf("Channel 1 %i \n", c);
        printf("Channel 2 %i \n", d);
        printf("Channel 3 %i \n", e);
        printf("Channel 4 %i \n", f);
        printf("Channel 5 %i \n", g);
        printf("Channel 6 %i \n", h);
        printf("Channel 7 %i \n", i);
        printf("\n");
    }
    rtems_task_suspend (RTEMS_SELF);
}

/* end of 'datacollect.c' file */
