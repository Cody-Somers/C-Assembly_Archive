/*
 * Title: communicate.c
 * Author: Cody Somers
 * Date: Oct 21, 2022
 * Last Edit: Dec 1, 2022
 * Microcontroller: ColdFire. ip: 10.65.118.226
 * Program: This creates the HTML webpage that the user sees. Displays the data collected from the joystick as well as
 * motor position.
 * Important Aspects:
 * - Learn HTML better to make it look pretty
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
float position;

rtems_task communicate(int s) { //This might have to be changed to type int or rtems_task_argument
    // Open a file that corresponds to the server and prints these values there, then kill self.
    FILE * fd;
    fd = fdopen(s, "r+");
    fprintf(fd, "HTTP/1.0 200\n");
    fprintf(fd, "Content-type: text/html\n\n");
    fprintf(fd, "<HTML>\n<HEAD>\n<TITLE>EP413 Data Acquisition Cody's Server</TITLE>\n</HEAD>\n<BODY>\n<H1>ADC VALUES</H1>\n");
    fprintf(fd, "<HR>\n\n"); // Horizontal line break
    fprintf(fd,"Channel 0: %i \n", outputArray[0]);
    fprintf(fd, "<BR>\n\n"); // Line break
    fprintf(fd,"Channel 1: %i \n", outputArray[1]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 2: %i \n", outputArray[2]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 3: %i \n", outputArray[3]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 4: %i \n", outputArray[4]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 5: %i \n", outputArray[5]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 6: %i \n", outputArray[6]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Channel 7: %i \n", outputArray[7]);
    fprintf(fd, "<BR>\n\n");
    fprintf(fd, "<BR>\n\n");
    fprintf(fd,"Motor Position: %.2f%c \n", position, 176);
    fprintf(fd, "<HR>\n</BODY>\n</HTML>");
    fclose(fd);
    rtems_task_delete(RTEMS_SELF);
}