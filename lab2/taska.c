/*
 * Title: taska.c
 * Author: Cody Somers
 * Date: Sept 23, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Configures pins on board then:
 * - Wait one clock tick, sets pin E3 to high, sends an event to taskB, sets pin E3 to low, repeat.
 */

#include <bsp.h>
#include <stdlib.h>
#include <stdio.h>
#include <rtems/error.h>
#include <rtems.h>
#include "mcf5282.h"

extern rtems_id tid2; // Retrieves the global variable for id of taskB

rtems_task taskA(rtems_task_argument a){ // argument is unused

    // Chip Configuration Register. Sets SZEN (bit 6) to 0 to disable the SIZ1 function
    MCF5282_CCM_CCR &= ~(MCF5282_CCM_CCR_SZEN);
    // PortE pin assignment, setting port E3 to 0 to configure it into digital I/O port.
    MCF5282_GPIO_PEPAR &= ~(MCF5282_GPIO_PEPAR_PEPA3);
    // Sets data direction of pin E3 to output.
    MCF5282_GPIO_DDRE |= MCF5282_GPIO_SETx3;

    rtems_status_code sc; // Error code

    for(;;) { // Infinite loop
        rtems_task_wake_after(1); // Wait for one clock tick. (Clock driver must be enabled)

        MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx3; // Set pin E3 to high

        sc = rtems_event_send( // Send an event
                tid2, // id of taskB
                RTEMS_EVENT_0); // Event being sent

        if (sc != RTEMS_SUCCESSFUL) { // Check success
            printf("Can't create task event send: %s\n", rtems_status_text(sc));
            rtems_task_suspend(RTEMS_SELF);
        }

        MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx3); // Set pin E3 to low
    }
}

/* end of 'taska.c' file */
