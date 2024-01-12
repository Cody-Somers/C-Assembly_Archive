/*
 * Title: initialize.c
 * Author: Cody Somers
 * Date: Oct 14, 2022
 * Last Edit: Nov 28, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Initializes multiple registers to set up the QADC function of the ColdFire. Initializes the timer for ISR
 * Important Aspects:
 * - Can change the channel outputs in the CCW
 * - Can change the initial settings of the timer (Also should change them in ISR)
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

rtems_task initialize(rtems_task_argument a){

    // Module Configuration Register
    // Turns off stop enable, and turns off debug mode.
    MCF5282_QADC_QADCMCR &= ~(MCF5282_QADC_QADCMCR_QSTOP | MCF5282_QADC_QADCMCR_QDBG); // 1 is idle. 0 is to operate normally

    // Port Data Registers
    // Sets the required pins to zero to function as analogue I/O devices
    MCF5282_QADC_PORTQA &= ~(MCF5282_QADC_PORTQA_PQA4 | MCF5282_QADC_PORTQA_PQA3 | MCF5282_QADC_PORTQA_PQA1 | MCF5282_QADC_PORTQA_PQA0); // Set the bits to 0 in PortQA
    MCF5282_QADC_PORTQB &= ~(MCF5282_QADC_PORTQB_PQB3 | MCF5282_QADC_PORTQB_PQB2 | MCF5282_QADC_PORTQB_PQB1 | MCF5282_QADC_PORTQB_PQB0); // Set the bits to 0 in PortQB

    // Data Direction Registers
    // Clearing a bit here sets the signal as an input.
    MCF5282_QADC_DDRQA &= ~(MCF5282_QADC_DDRQA_DDQA4 | MCF5282_QADC_DDRQA_DDQA3 | MCF5282_QADC_DDRQA_DDQA1 | MCF5282_QADC_DDRQA_DDQA0); // Set the DDRA to 0
    MCF5282_QADC_DDRQB &= ~(MCF5282_QADC_DDRQB_DDQB3 | MCF5282_QADC_DDRQB_DDQB2 | MCF5282_QADC_DDRQB_DDQB1 | MCF5282_QADC_DDRQB_DDQB0); // Set the DDRB to 0

    // Control Register 0
    // Sets QACR0 into internal multiplex mode, and sets the trigger so that ETRIG1 does Queue1, and ETRIG2 does Queue2
    MCF5282_QADC_QACR0 &= ~(MCF5282_QADC_QACR0_MUX | MCF5282_QADC_QACR0_TRG);

    // Control Register 1
    // Sets QACR1 so the MQ registers is 10001 which is software triggered continuous scan. Bit shifted left by 8.
    MCF5282_QADC_QACR1 |= (MCF5282_QADC_QACRx_MQ(0x11));

    // Control Register 2
    MCF5282_QADC_QACR2 = 0x007F; // Sets this to the default reset. Not needed but good for redundancy.

    // Queue Status Register 0
    MCF5282_QADC_QASR0 &= 0x0; // Set everything to 0 for robustness. Used to return the status

    // Conversion Command Word Table
    // Contains the output channels to the board
    // Can change the sample time. Higher is less noise, but lower is faster.
    MCF5282_QADC_CCW(0x0) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x0) |= (MCF5282_QADC_CCW_CHAN(0)); // This is PQB0
    MCF5282_QADC_CCW(0x0) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x0) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x1) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x1) |= (MCF5282_QADC_CCW_CHAN(1)); // This is PQB1
    MCF5282_QADC_CCW(0x1) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x1) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x2) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x2) |= (MCF5282_QADC_CCW_CHAN(2)); // This is PQB2
    MCF5282_QADC_CCW(0x2) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x2) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x3) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x3) |= (MCF5282_QADC_CCW_CHAN(3)); // This is PQB3
    MCF5282_QADC_CCW(0x3) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x3) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x4) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x4) |= (MCF5282_QADC_CCW_CHAN(52)); // This is PQA0
    MCF5282_QADC_CCW(0x4) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x4) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x5) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x5) |= (MCF5282_QADC_CCW_CHAN(53)); // This is PQA1
    MCF5282_QADC_CCW(0x5) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x5) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x6) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x6) |= (MCF5282_QADC_CCW_CHAN(55)); // This is PQA3
    MCF5282_QADC_CCW(0x6) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x6) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0
    MCF5282_QADC_CCW(0x7) &= 0x0; // Sets everything to 0 instead of undefined
    MCF5282_QADC_CCW(0x7) |= (MCF5282_QADC_CCW_CHAN(56)); // This is PQA4
    MCF5282_QADC_CCW(0x7) |= (MCF5282_QADC_CCW_IST(0x3)); // This sets the sample time
    MCF5282_QADC_CCW(0x7) &= ~(MCF5282_QADC_CCW_BYP | MCF5282_QADC_CCW_P); // This sets bypass and pause to 0


    // Chip Configuration Register. Sets SZEN (bit 6) to 0 to disable the SIZ1 function
    MCF5282_CCM_CCR &= ~(MCF5282_CCM_CCR_SZEN);
    // PortE pin assignment, setting port E2 to 0 to configure it into digital I/O port.
    MCF5282_GPIO_PEPAR &= ~(MCF5282_GPIO_PEPAR_PEPA2);
    // Sets data direction of pin E2 to output.
    MCF5282_GPIO_DDRE |= MCF5282_GPIO_SETx2;

    // Chip Configuration Register. Sets SZEN (bit 6) to 0 to disable the SIZ1 function
    MCF5282_CCM_CCR &= ~(MCF5282_CCM_CCR_SZEN);
    // PortE pin assignment, setting port E3 to 0 to configure it into digital I/O port.
    MCF5282_GPIO_PEPAR &= ~(MCF5282_GPIO_PEPAR_PEPA3);
    // Sets data direction of pin E3 to output.
    MCF5282_GPIO_DDRE |= MCF5282_GPIO_SETx3;

    // Sets up the timer
    // DTMR initial setup
    MCF5282_TIMER_DTMR(0) = 0;
    MCF5282_TIMER_DTMR(0) &= ~MCF5282_TIMER_DTMR_RST; // Disable the timer
    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_CLK_DIV1; // Internal bus clock divided by 1.
    MCF5282_TIMER_DTMR(0) &= ~MCF5282_TIMER_DTMR_FRR; // Put it into free run mode
    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_ORRI; // Enables interrupt on reaching reference value
    MCF5282_TIMER_DTMR(0) &= ~MCF5282_TIMER_DTMR_OM; // Just leaving this as 0. Don;t care about output
    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_CE_NONE; // Capture on rising edge.
    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_PS(0x00); // Set prescaler value. Set to 1 currently.

    // DTXMR initial setup
    MCF5282_TIMER_DTXMR(0) &= 0; // Clears the entire port. This sets DMA request off so interrupt occurs and increment timer by 1.

    // DTER initial setup
    MCF5282_TIMER_DTER(0) &= 0; // Clear entire port
    MCF5282_TIMER_DTER(0) |= 0x03; // Clear both the REF and CAP value by writing a one to it

    // DTRR initial setup
    MCF5282_TIMER_DTRR(0) &= 0xFFFF; // Sets up the maximum value that the timer should count up to.

    // DTCR is not used

    // DTCN initial setup
    MCF5282_TIMER_DTCN(0) &= 0; // Clear the counter register

    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_RST; // Enable the timer

    rtems_task_suspend (RTEMS_SELF);
}

/* end of 'initialize.c' file */
