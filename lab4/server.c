/*
 * Title: server.c
 * Author: Cody Somers
 * Date: Oct 14, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: This hosts the server. Here we start up the data collection task with a higher priority than the
 * accept client task. It creates the socket and listen command, then starts a task to accept the client
 * Important Aspects:
 * - Can change the priority of tasks
 * - Can change the domain, stream, protocol parameters
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

rtems_task acceptclient(rtems_task_argument a); // Tells the code that these functions exist somewhere
rtems_task datacollect(rtems_task_argument a);

rtems_task server(rtems_task_argument a) {
    rtems_status_code sc; // Error code, used for checking that all functions function without errors.
    rtems_id tid2; // id of datacollection
    rtems_id tid3; // id of acceptclient
    sc = rtems_task_create (rtems_build_name ('D','A','T','A'), //Creates datacollect
                            10, // Priority
                            RTEMS_MINIMUM_STACK_SIZE, // Stack size
                            RTEMS_PREEMPT|RTEMS_NO_TIMESLICE|RTEMS_NO_ASR|RTEMS_INTERRUPT_LEVEL(0), // Modes
                            RTEMS_NO_FLOATING_POINT|RTEMS_LOCAL, // Attributes
                            &tid2); // Task id
    if (sc != RTEMS_SUCCESSFUL) { // Checks for errors
        printf ("Can't create datacollect: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }
    sc = rtems_task_start( // Starts up Datacollection
            tid2, // Task id
            datacollect, // Function name (Entry Point)
            a); // Argument (unused)
    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start data collect: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

    // Create a socket
    // Has Internet domain, with continuous stream, and TCP protocol
    int s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s < 0) {
        perror("Can't create socket.");
        rtems_task_suspend(RTEMS_SELF);
    }

    // Create the server address
    struct sockaddr_in serverAddr;
    serverAddr.sin_port = htons(80); // Port
    serverAddr.sin_family = AF_INET; // Family type
    serverAddr.sin_addr.s_addr = INADDR_ANY; // Server address
    // Bind the socket
    int b = bind(s, (struct sockaddr *) &serverAddr, sizeof serverAddr);
    if (b < 0) {
        perror("Can't bind socket.");
        rtems_task_suspend(RTEMS_SELF);
    }

    int backlog = 10; // Increase this value if you have to. This is the maximum number of commands that can wait.
    // Listen for connections
    int l = listen(s, backlog);
    if (l < 0) {
        perror("Can't listen to the socket");
        rtems_task_suspend(RTEMS_SELF);
    }

    sc = rtems_task_create(rtems_build_name('A', 'C', 'P', 'T'), //Creates acceptclient
                           50, // Priority
                           RTEMS_MINIMUM_STACK_SIZE, // Stack size
                           RTEMS_PREEMPT | RTEMS_NO_TIMESLICE | RTEMS_NO_ASR | RTEMS_INTERRUPT_LEVEL(0), // Modes
                           RTEMS_NO_FLOATING_POINT | RTEMS_LOCAL, // Attributes
                           &tid3); // Task id
    if (sc != RTEMS_SUCCESSFUL) {
        printf("Can't create acceptclient: %s\n", rtems_status_text(sc));
        rtems_task_suspend(RTEMS_SELF);
    }
    sc = rtems_task_start( // Starts up acceptclient
            tid3, // Task id
            acceptclient, // Function name (Entry Point)
            s); // Argument socket
    if (sc != RTEMS_SUCCESSFUL) {
        printf ("Can't start acceptclient: %s\n", rtems_status_text (sc));
        rtems_task_suspend (RTEMS_SELF);
    }

    rtems_task_suspend (RTEMS_SELF);
}

/* end of 'server.c' file */