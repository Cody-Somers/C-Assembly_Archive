/*
 * Title: datacollect.c
 * Author: Cody Somers
 * Date: Nov 25, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program:
 * Important Aspects:
 *
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
rtems_task timersetup(rtems_task_argument a) {
    // This should have disabled the capture edge, put it in restart mode, then start the timer.
    MCF5282_TIMER_DTMR(0) &= MCF5282_TIMER_DTMR_CE_NONE | MCF5282_TIMER_DTMR_FRR | MCF5282_TIMER_DTMR_RST;
    // DTRRn put in the value to count up to.
    // DTCNn any write command to this will clear the register. Should be cleared before use
    MCF5282_TIMER_DTCN(0) &= 0;



}