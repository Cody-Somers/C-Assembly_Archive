/*
 * Title: taskb.c
 * Author: Cody Somers
 * Date: Sept 23, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Configures pins on board then:
 * - Waits for event from taskA, sets pin E2 to high, waits for event from taskA, sets pin E2 to low, repeat
 */

#include <bsp.h>
#include <stdlib.h>
#include <stdio.h>
#include <rtems/error.h>
#include <rtems.h>
#include "mcf5282.h"

rtems_task taskB(rtems_task_argument b){ // argument is unused

    // Chip Configuration Register. Sets SZEN (bit 6) to 0 to disable the SIZ1 function
    MCF5282_CCM_CCR &= ~(MCF5282_CCM_CCR_SZEN);
    // PortE pin assignment, setting port E2 to 0 to configure it into digital I/O port.
    MCF5282_GPIO_PEPAR &= ~(MCF5282_GPIO_PEPAR_PEPA2);
    // Sets data direction of pin E2 to output.
    MCF5282_GPIO_DDRE |= MCF5282_GPIO_SETx2;

    rtems_status_code sc; // Error code
    rtems_event_set output; // Event output, unused besides for necessity of a variable.

    for(;;) { // Infinite loop
        sc = rtems_event_receive(
                RTEMS_EVENT_0, // Event to wait for
                RTEMS_WAIT, // Wait for task
                RTEMS_NO_TIMEOUT, // Wait forever, no timeout
                &output); // Tell variable output when event has been received

        if (sc != RTEMS_SUCCESSFUL) { // Check success
            printf("Can't create event receive 1: %s\n", rtems_status_text(sc));
            rtems_task_suspend(RTEMS_SELF);
        }

        MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx2; // Set pin E2 to high

            sc = rtems_event_receive( // Same event parameters as above
                RTEMS_EVENT_0,
                RTEMS_WAIT,
                RTEMS_NO_TIMEOUT,
                &output);

        if (sc != RTEMS_SUCCESSFUL) {
            printf("Can't create event receive 2: %s\n", rtems_status_text(sc));
            rtems_task_suspend(RTEMS_SELF);
        }

        MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx2); // Set pin E2 to low
    }
}

/* end of 'taskb.c' file */
