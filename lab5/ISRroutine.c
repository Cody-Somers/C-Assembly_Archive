/*
 * Title: ISRroutine.c
 * Author: Cody Somers
 * Date: Nov 25, 2022
 * Last Edit: Dec 1, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: Resets the ISR timer. The length of which is specified based on the position of the joystick. Sends the proper
 * series of high/low to get a stepper motor to function properly.
 * Important Aspects:
 * - Equations dictate the length of the timer, which states how fast the motor should spin.
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
int step = 1;
float position = 0;

rtems_isr ISRroutine(rtems_vector_number v) {

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
    // We have x2 as A, and x3 as B
    // Timer equations are linear equations. One from x = 0,460 y = 400,10 and the other x = 560,1020 y = 10,400
    if(outputArray[7] < 460){
        MCF5282_TIMER_DTRR(0) &= (int)(80000000/(-0.84782608695652*(outputArray[7])+400)); // Sets up the maximum value that the timer should count up to.
        if(step == 1){
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx3; // Pin B on
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx2; // Pin A on
            step++;
            position += 3.6; // Position in degrees
        }
        else if(step == 2){
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx3; // Pin B on
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx2); // Pin A off
            step++;
            position += 3.6; // Position in degrees
        }
        else if(step == 3){
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx3); // Pin B off
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx2); // Pin A off
            step++;
            position += 3.6; // Position in degrees
        }
        else{
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx3); // Pin B off
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx2; // Pin A on
            step = 1;
            position += 3.6; // Position in degrees
        }
        if(position >= 360){
            position = 0; // Position in degrees
        }
    }
    else if(outputArray[7] > 560){
        MCF5282_TIMER_DTRR(0) &= (int)(80000000/(0.84782608695652*(outputArray[7])-464.7826)); // Sets up the maximum value that the timer should count up to.
        if(step == 1){
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx3; // Pin B on
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx2; // Pin A on
            step = 4;
            position -= 3.6; // Position in degrees
        }
        else if(step == 2){
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx3; // Pin B on
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx2); // Pin A off
            step--;
            position -= 3.6; // Position in degrees
        }
        else if(step == 3){
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx3); // Pin B off
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx2); // Pin A off
            step--;
            position -= 3.6; // Position in degrees
        }
        else{
            MCF5282_GPIO_PORTE &= ~(MCF5282_GPIO_SETx3); // Pin B off
            MCF5282_GPIO_PORTE |= MCF5282_GPIO_SETx2; // Pin A on
            step--;
            position -= 3.6; // Position in degrees
        }
        if(position <= 0){
            position = 360; // Position in degrees
        }
    }
    else{
        // Just a default value to check the position frequently.
        MCF5282_TIMER_DTRR(0) &= 0xFFFF; // Sets up the maximum value that the timer should count up to.
    }
    // DTCR is not used

    // DTCN initial setup
    MCF5282_TIMER_DTCN(0) &= 1; // Clear the counter register

    MCF5282_TIMER_DTMR(0) |= MCF5282_TIMER_DTMR_RST; // Enable the timer
}