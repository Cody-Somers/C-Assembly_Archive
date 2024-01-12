/*
 * Title: datacollect.c
 * Author: Cody Somers
 * Date: Oct 21, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: An infinite loop that accepts clients, prints the client information to minicom: IP, Port, URL,
 * then communicates with the client
 * Important Aspects:
 * - Client information can be parsed here to check the URL and domain
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

rtems_task communicate(rtems_task_argument a);

rtems_task acceptclient(int s) { //This might have to be changed to type int or rtems_task_argument

    struct sockaddr_in clientAddr;
    // Enter an infinite loop looking to accept clients.
    for(;;) {
        int clientLen = sizeof clientAddr;
        // Accept Client
        int s1 = accept(s, (struct sockaddr *) &clientAddr, (socklen_t * ) & clientLen);
        if (s1 < 0) {
            perror("Can't accept connection.");
            rtems_task_suspend(RTEMS_SELF);
        }

        // Use %s when you reference the character thing below to print.
        char *clientIP = inet_ntoa(clientAddr.sin_addr); // Be careful, because any inet_ntoa will overwrite I think
        in_port_t clientPort = clientAddr.sin_port;
        char buff[500];
        int nread = read(s1, buff, sizeof buff);
        if(nread < 0 ){
            perror("Can't read the nread.");
            rtems_task_suspend(RTEMS_SELF);
        }

        //Print out port and IP, and URL (+ more) of the client to the terminal.
        printf("This is the IP of client %s \n", clientIP);
        printf("And this is the port %hu \n", clientPort);
        printf("Read %d bytes from server \n", nread);
        printf("Server message '%.*s'.\n",nread, buff);

        rtems_id tid4; // id of communicate
        rtems_status_code sc; // Error code, used for checking that all functions function without errors.
        sc = rtems_task_create(rtems_build_name('C', 'O', 'M', 'M'), //Creates communicate
                               50, // Priority
                               RTEMS_MINIMUM_STACK_SIZE, // Stack size
                               RTEMS_PREEMPT | RTEMS_NO_TIMESLICE | RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
                               RTEMS_NO_FLOATING_POINT | RTEMS_LOCAL, // Attributes
                               &tid4); // Task id
        if (sc != RTEMS_SUCCESSFUL) {
            printf("Can't create communicate: %s\n", rtems_status_text(sc));
            rtems_task_suspend(RTEMS_SELF);
        }
        sc = rtems_task_start( // Starts up Communicate
                tid4, // Task id
                communicate, // Function name (Entry Point)
                s1); // Argument socket
        if (sc != RTEMS_SUCCESSFUL) {
            printf("Can't start communicate: %s\n", rtems_status_text(sc));
            rtems_task_suspend(RTEMS_SELF);
        }
    }

}