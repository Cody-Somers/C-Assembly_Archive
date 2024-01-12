; Title: Light Show
; Description:
; Author: Cody Somers, 11271716
; Date Created: Oct 10, 2022
; Last Edited: Oct , 2022
; Due Date: Nov 1, 2022
; Microcontroller: 8051 with Paulmon
; Variables:
;   Inputs:
;   Outputs:

;---------Initialize Board----------
locat  EQU 8000h                ;Location for this program
ORG    locat

DB     0A5h,0E5h,0E0h,0A5h      ;signiture bytes
DB     35,255,0,0               ;id (35=prog)
DB     0,0,0,0                  ;prompt code vector
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;user defined
DB     255,255,255,255          ;length and checksum (255=unused)
DB     "Assignment3",0	      ;max 31 characters, plus the zero

port_a EQU 0F800h           ; Location of port A
port_b EQU 0F801h           ; Location of port B
port_abc_pgm EQU 0F803h     ; Configuration byte for ports A,B,C

lcd_command_wr EQU 0FE00h ; Write only
lcd_status_rd EQU 0FE01h ; Read only
lcd_data_wr EQU 0FE02h ; Write only
lcd_data_rd EQU 0FE03h ; Read only

ORG    locat+64             ; executable code begins here

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm     ; Configuration byte for ports A,B,C
MOV A, #128
MOVX @DPTR, A

;-----------Main Program------------
;ACALL busy_check
;ACALL configure_LCD
ACALL busy_check
ACALL clear_disp
ACALL busy_check
ACALL move_cursor_home

main_program: ; Infinite loop running the code
ACALL busy_check
MOV DPTR, #lcd_data_wr
MOV A, #21h ; Print the letter
MOVX @DPTR, A

ACALL busy_check
MOV DPTR, #lcd_data_wr
MOV A, #22h ; Print the letter
MOVX @DPTR, A

SJMP theend


;-----------Subroutines------------

; Code for checking that the LCD is not busy.
busy_check:
  ;MOV R0, A ; Save value in A
  MOV DPTR, #lcd_status_rd
  lcd_wait: MOVX A, @DPTR
    JB acc.7, lcd_wait
  ;MOV A, R0 ; Return value to A.
RET

; Move the cursor to the home position
move_cursor_home:
  ;MOV R0, A ; Save value in A
  ACALL busy_check ; Check if busy
  MOV DPTR, #lcd_command_wr
  MOV A, #02h ; Move cursor to home position
  MOVX @DPTR, A
  ;MOV A, R0 ; Return value to A.
RET

; Configure LCD for use
configure_LCD:
  ;MOV R0, A ; Save value in A

  ACALL busy_check
  MOV DPTR, #lcd_command_wr
  MOV A, #28h ; Configure the LCD to have 2 line display, 4 bit interface, 5x7 pixel
  MOVX @DPTR, A

  ACALL busy_check
  MOV DPTR, #lcd_command_wr
  MOV A, #0Ch ; Turn on display, with cursor and blinking cursor disabled
  MOVX @DPTR, A

  ACALL busy_check
  MOV DPTR, #lcd_command_wr
  MOV A, #1Ch ; Right shift the display
  MOVX @DPTR, A

  ;ACALL busy_check
  ;MOV DPTR, #lcd_command_wr
  ;MOV A, #80h ; Set display buffer RAM address. This sets the cursor to the beginning of the first line.
  ;MOVX @DPTR, A

  ; May also have to set the entry mode here

  ;MOV A, R0 ; Return value to A
RET

; Clear the display on the board
clear_disp:
  ;MOV R0, A ; Save value in A
  ACALL busy_check ; Check if busy
  MOV DPTR, #lcd_command_wr
  MOV A, #01h ; Clears the display
  MOVX @DPTR, A
  ;MOV A, R0 ; Return value to A.
RET

theend:
END                         ; End of program.
