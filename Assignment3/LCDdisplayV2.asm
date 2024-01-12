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

;--------Initialize LCD Screen--------
; The steps follow the timing guide. So we power on, wait for 15ms.
; Set the function in 8bit mode
; Wait again for 4.1ms
; Set the function in 8bit mode
; Wait again for 100us
; Set the function in 8bit mode one final time. Then the BF can be checked and
; the rest of the initialization process can happen.
; This involves setting it to 4bit mode, then clearing display etc.

initialize_LCD:
MOV R0, #200
MOV R1, #200
init_delay: ; Set for a 15ms delay
  DJNZ R0, init_delay
  MOV R0, #200
  DJNZ R1, init_delay

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h ; Necessary value that sets DB5,4 to high (also sets DB3high, but ignored)
MOVX @DPTR, A

; Wait for 4.3ms
MOV R0, #45
MOV R1, #45
init_delay2: ; Set for a 4.3ms delay
  DJNZ R0, init_delay2
  MOV R0, #45
  DJNZ R1, init_delay2

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h ; Necessary value that sets DB5,4 to high (also sets DB3high, but ignored)
MOVX @DPTR, A

; Wait for 100us
MOV R0, #250
init_delay3: ; Set for a 100us delay
  DJNZ R0, init_delay3

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h ; Necessary value that sets DB5,4 to high (also sets DB3high, but ignored)
MOVX @DPTR, A

; Wait for 4.3ms. This one might not be necessary
MOV R0, #45
MOV R1, #45
init_delay9: ; Set for a 4.3ms delay
  DJNZ R0, init_delay9
  MOV R0, #45
  DJNZ R1, init_delay9

; Set into 4-bit mode
ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #20h ; Sets it to 4-bit mode
MOVX @DPTR, A

; Set the rest of the stuff. Everything from this point on will be required to send or receive data twice.
;ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #2h ; Sets it to 4-bit mode
MOVX @DPTR, A
; Might need a busy check in here.
MOV DPTR, #lcd_command_wr
MOV A, #8h ; Sets it to 2 line display
MOVX @DPTR, A

; Turn on display, with cursor and blinking cursor disabled
ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #0h
MOVX @DPTR, A
; Might need a busy check in here.
MOV DPTR, #lcd_command_wr
MOV A, #0Ch
MOVX @DPTR, A

; Set shift mode to right display shift
ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #1h
MOVX @DPTR, A
; Might need a busy check in here.
MOV DPTR, #lcd_command_wr
MOV A, #0Ch
MOVX @DPTR, A

; Set display buffer RAM address. This sets the cursor to the beginning of the first line.
ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #8h
MOVX @DPTR, A
; Might need a busy check in here.
MOV DPTR, #lcd_command_wr
MOV A, #0h
MOVX @DPTR, A

; Set entry mode so that cursor moves to the right but display not shifted
ACALL busy_check
MOV DPTR, #lcd_command_wr
MOV A, #0h
MOVX @DPTR, A
; Might need a busy check in here.
MOV DPTR, #lcd_command_wr
MOV A, #6h
MOVX @DPTR, A

ACALL clear_disp

; Print the letter C
ACALL busy_check
MOV DPTR, #lcd_data_wr
MOV A, #4h ; Print the letter
MOVX @DPTR, A
MOV DPTR, #lcd_data_wr
MOV A, #3h ; Print the letter
MOVX @DPTR, A

SJMP theend




; swap command to get the second nibble.


;-----------Subroutines------------

; Code for checking that the LCD is not busy.
busy_check:
  MOV DPTR, #lcd_status_rd
  lcd_wait:
    MOVX A, @DPTR
    JNB acc.7, lcd_go
    MOVX A, @DPTR
    SJMP lcd_wait
    lcd_go:
    MOVX A, @DPTR
RET

; Clear the display on the board
clear_disp:
  ACALL busy_check
  MOV DPTR, #lcd_command_wr
  MOV A, #0h
  MOVX @DPTR, A
  ; Might need a busy check in here.
  MOV DPTR, #lcd_command_wr
  MOV A, #1h
  MOVX @DPTR, A
RET


;-------- Garbage below-------------
; Move the cursor to the home position
move_cursor_home:
  ;MOV R0, A ; Save value in A
  ACALL busy_check ; Check if busy
  MOV DPTR, #lcd_command_wr
  MOV A, #02h ; Move cursor to home position
  MOVX @DPTR, A
  ;MOV A, R0 ; Return value to A.
RET

theend:
END                         ; End of program.
