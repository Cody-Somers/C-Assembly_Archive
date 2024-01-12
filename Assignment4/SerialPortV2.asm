; Title: Serial Port
; Description:
;
; Author: Cody Somers, 11271716
; Date Created: Nov 19, 2022
; Last Edited: Nov 19, 2022
; Due Date: Nov 29, 2022
; Microcontroller: 8051 with Paulmon
; Variables:
;   Inputs:
;   Outputs:

;---------Initialize Board----------
locat  EQU 8000h                ;Location for this program
ORG    locat

DB     0A5h,0E5h,0E0h,0A5h      ;signature bytes
DB     35,255,0,0               ;id (35=prog)
DB     0,0,0,0                  ;prompt code vector
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;reserved
DB     0,0,0,0                  ;user defined
DB     255,255,255,255          ;length and checksum (255=unused)
DB     "Assignment4V2",0	      ;max 31 characters, plus the zero

; Sometimes the button makes it where you can't type after it has been pressed
; Not sure what's up with that but yeah.
extern_0  EQU 2003h            ; Location of External 0 ISR
ORG    extern_0
LCALL busy_check
LCALL clear_disp
; This sets the initial registers for the length of the display lines.
MOV R3, #20
MOV R4, #2
RETI

; This can be deleted
timer_1  EQU 201Bh            ; Location of Timer 1 ISR
ORG    timer_1
;LCALL LCD_Subroutine       ; Subroutine call to below the squarewave code
RETI

RI_TI  EQU 2023h            ; Location of whatever ISR this is
ORG    RI_TI
LCALL LCD_Subroutine       ; Subroutine call to below the squarewave code
RETI

ORG    locat+64             ; executable code begins here

; Pins on board
port_a EQU 0F800h           ; Location of port A
port_b EQU 0F801h           ; Location of port B
port_abc_pgm EQU 0F803h     ; Configuration byte for ports A,B,C

; LCD commands
lcd_command_wr EQU 0FE00h   ; Write only
lcd_status_rd EQU 0FE01h    ; Read only
lcd_data_wr EQU 0FE02h      ; Write only
lcd_data_rd EQU 0FE03h      ; Read only

; Serial I/O
cout EQU 30h
cin EQU 32h
esc EQU 3Eh

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm     ; Configuration byte for ports A,B,C
MOV A, #128
MOVX @DPTR, A

;----------Initialize the Pins------------
; This sets up the interrupt timer to use the 16 bit timer with internal control.
; Sets the high and low so that it is has a 27ms delay.
SETB IE.7                   ; Enable interrupt
;SETB IE.3                   ; Timer 1 interrupt enable
SETB IE.4                   ; Serial Port interrupt enable
SETB IE.0                   ; External Interrupt 0 interrupt enable
; The TMOD value needs to be changed when the second timer is enabled. To 21h.
MOV TMOD, #20h              ; Turns it into a 8 bit timer (auto-reload) for T1, with internal control
MOV SCON, #50h ; This sets the serial port to Mode 1. Set to 70h for multiprocessor
MOV TH1, #250               ; Timer high. Set the timer to a
MOV TL1, #00h
ANL PCON, #7Fh ; This is just to ensure that the first bit is set to zero. Otherwise baud x2
; Still need to set up the priority level with IP here.
CLR TI
CLR RI
CLR T0 ; This turns it so that the second serial port will work
SETB TCON.6                 ; Turn Timer 1 on.

; This sets the initial registers for the length of the display lines.
MOV R3, #20
MOV R4, #2

; Set the priorities here
; Clear LCD even when typing
; Should always be able to type and get a response > than square/light show.


;--------Initialize LCD Screen--------
; Description: These steps follow the timing guide.
;   We power on, wait for 15ms.
;   Set the function in 8bit mode
;   Wait again for 4.1ms
;   Set the function in 8bit mode
;   Wait again for 100us
;   Set the function in 8bit mode one final time. Then the BF can be checked and
;   the rest of the initialization process can happen:
;     This involves setting it to 4bit mode, then clearing display etc.
; Variables: Uses A and DPTR
;   Input: None
;   Output: Initialize the board into 4 bit mode

initialize_LCD:
; Wait for 15ms
ACALL init_delay_sequence
ACALL init_delay_sequence
ACALL init_delay_sequence
ACALL init_delay_sequence

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h                 ; Necessary value that sets DB5,4 to high
MOVX @DPTR, A

; Wait 4.2ms
ACALL init_delay_sequence

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h                 ; Necessary value that sets DB5,4 to high
MOVX @DPTR, A

; Wait 4.2ms (Only 100us necessary)
ACALL init_delay_sequence

; Function Set Command (8-bit interface)
MOV DPTR, #lcd_command_wr
MOV A, #30h                 ; Necessary value that sets DB5,4 to high
MOVX @DPTR, A

; Wait 4.2ms (Might not be necessary)
ACALL init_delay_sequence

; Set into 4-bit mode
MOV DPTR, #lcd_command_wr
MOV A, #20h                 ; Sets it to 4-bit mode
MOVX @DPTR, A

;-------Set initial parameters-------
; Description: The board is now initialized and the rest of the board is set
;   This puts it in 4-bit mode and 2 line display, cursor and blink disabled,
;   shift mode to right cursor shift(might not be used) initial address to write
;   which is first line of display, then entry mode(might not be used) so that cursor
;   moves right.
; Variables: Uses A and DPTR
;   Input: None
;   Output: Completes initialization of LCD

; Set the rest of the stuff. Everything from this point on will be required to send or receive data twice.
ACALL init_delay_sequence   ; Wait 4.2ms
MOV A, #28h                 ; Sets it to 4-bit mode and 2 line display
ACALL lcd_command           ; lcd_command is in 4-bit mode and only works as such

; Clear the display
ACALL clear_disp

; Turn on display, with cursor and blinking cursor enabled
MOV A, #0Fh                 ; Set this back to 0Fh. Set to 0Ch to turn off
ACALL lcd_command

; Set shift mode to right cursor shift
MOV A, #10h                 ; Set to 14 or 10. Seems to have no difference
ACALL lcd_command

; Set display buffer RAM address. This sets the cursor to the beginning of the first line.
MOV A, #80h                 ; Set to 80
ACALL lcd_command

; Set entry mode so that cursor moves to the right but display not shifted
MOV A, #06h                 ; Set to 06
ACALL lcd_command

;-----------Start of SquareWave Code---------------
HALF_PERIOD EQU 4      ; User defined constant
    ; Running this value at
    ; 1 would give a period of 6.510us
    ; 32 gives a period of 73.80us, which is 36.90us high and low.
    ; 227 gives a period of 499.0us.
    ; These values are all wrong. Play around with this to get the proper period.

ON:
MOV R0, #HALF_PERIOD    ; Move the constant into the register
SETB P1.0               ; Set the pin to high
NOP                     ; Delay because of JMP at the end
NOP                     ; JMP is two cycles, so this is the second NOP here.

DELAY:
DJNZ R0,DELAY           ; Loop and decrement the register, which is acting as a counter

OFF:
MOV R0, #HALF_PERIOD    ; Move the constant back into the register, since R0 equals 0 at this point
CLR P1.0                ; Set the bit low

DELAY2:
DJNZ R0,DELAY2          ; Loop and decrement the register.

SJMP ON                 ; Jump back to the start of the program
; This is an infinite loop, nothing will run beyond this point in the code.
;-------End of SquareWave Code----------

;-------Start of LCD Program--------
; Description: Takes user input and prints it to LCD screen
; Variables: Uses A
;   Input: None
;   Output: Output on the LCD display

LCD_Subroutine:
ACALL user_input
MOV TH1, #250               ; Timer high. Set the timer to a
MOV TL1, #00h
RET
AJMP theend                 ; Never reached, but will exit the program. (debugging)

;--------End of LCD Program----------





;-----------Subroutines------------

;-----Check X-Y Position-----
; So for this I think I'm just going to have a register that counts up from 1 to 20
; Then when it reaches the max it switches the values to either #80h or #0C0h
; depending on if we want the first or the second line. This will use two registers
; It uses registers r3 and r4, which means these registers can not be used by anything else
; otherwise the count is disrupted. Could also store in b.

; This will return outside the same value put into the accumulator as the user typed
user_input:
  ;LCALL cin
  CLR TI
  CLR RI
  MOV A, SBUF
  ACALL busy_check
  MOV DPTR, #lcd_data_wr
  MOVX @DPTR, A
  SWAP A
  MOVX @DPTR, A
  SWAP A ; This second swap here is so that the ACC value is the right way around again
  PUSH ACC
  ACALL check_cursor_position
  POP ACC
RET

check_cursor_position:
  DJNZ R3, x_good
  MOV R3, #20   ; 20 characters on a line

  MOV A, #0C0h                 ; Set to second line
  ACALL lcd_command

  DJNZ R4, y_good
  MOV R4, #2    ; 2 lines of characters

  MOV A, #80h                 ; Set to first line
  ACALL lcd_command

  x_good:
  y_good:
RET


;-----LCD Command-----
; Description: This is the 4 bit action the performs a write to the command
;   register. Saves space for repetition.
; Variables: Uses A and DPTR
;   Input: The value of A needs to be set before calling this subroutine
;   Output: Puts the command given in A to the command write
lcd_command:
  ACALL busy_check          ; Checks if busy
  MOV DPTR, #lcd_command_wr ; Moves to command_wr
  MOVX @DPTR, A             ; First four bits (high bits 7-4)
  SWAP A                    ; Swap
  MOVX @DPTR, A             ; Second four bits (low bits 3-0)
RET

;-----Clear Display-----
; Description: A specific command that sets A to the appropriate value for clearing
;   the display.
; Variables: Uses A
;   Input: None
;   Output: Clears the display on the board
clear_disp:
  MOV A, #01h               ; Command for clear
  ACALL lcd_command         ; Perform action
RET

;-----Move Cursor Home-----
; Description: Returns the position of the screen to its original position
; Variables: Uses A
;   Input: None
;   Output: Returns screen position to home
; Move the cursor to the home position
move_cursor_home:
  MOV A, #02h               ; Move cursor to home position
  ACALL lcd_command
RET

;-----Busy Check-----
; Description: Checks the busy flag and only allows the program to continue if
;   the busy flag is not set.
; Variables: Uses A
;   Input: None
;   Output: Time delay
busy_check:
  PUSH ACC                  ; Store value in A
  MOV DPTR, #lcd_status_rd  ; Move to status register
  busy_wait:
    MOVX A, @DPTR           ; First 4 bits
    JNB acc.7, busy_go      ; If the data bit is not set, program is clear to return (busy_go)
    MOVX A, @DPTR           ; Second 4 bits. Not read but necessary for completeness
    SJMP busy_wait          ; Loop while busy flag is set
  busy_go:
    MOVX A, @DPTR           ; Second 4 bits. Ignored
    POP ACC                 ; Return value in A
RET

;---------Delay Timers---------
; Description:The timers all function the same, they just have a different duration.
;   For every full decrement of the first register, the second (or third) register
;   will only decrement once. Since the DJNZ takes two clock cycles, the total number
;   of clock cycles taken by a timer can be found by 2*R0*R1, with each clock
;   cycle being roughly 0.5us
; Variables: Makes use of R0, R1 and R2
;   Inputs: None
;   Outputs: Time delay

; A timer used for the initialization phase
init_delay_sequence:
  ; Wait for 4.3ms
  MOV R0, #45               ; Divided by 2
  MOV R1, #90
  init_delay:               ; Set for a 4.3ms delay
    DJNZ R0, init_delay
    MOV R0, #45
    DJNZ R1, init_delay
RET

; A timer for the blinking left, right portion
timer_delay:
  ; Wait for 137ms
  MOV R0, #121              ; Divided by 2
  MOV R1, #58
  MOV R2, #18
  delay_timer:              ; Set for a 137ms delay
    DJNZ R0, delay_timer
    MOV R0, #121
    DJNZ R1, delay_timer
    MOV R1, #58
    DJNZ R2, delay_timer
RET

; A timer for holding in the centre
timer_delay2:
  ; Wait for 3.4s
  MOV R0, #88               ; Divided by 2
  MOV R1, #178
  MOV R2, #200
  delay_timer2:             ; Set for a 3.4s delay
    DJNZ R0, delay_timer2
    MOV R0, #88
    DJNZ R1, delay_timer2
    MOV R1, #178
    DJNZ R2, delay_timer2
RET

; A timer that changes how quickly the names shift across the screen.
ticker_tape:
  ; Wait for however long/short you want that looks good
  MOV R0, #75
  MOV R1, #75
  MOV R2, #75
  delay_ticker:
    DJNZ R0, delay_ticker
    MOV R0, #75
    DJNZ R1, delay_ticker
    MOV R1, #75
    DJNZ R2, delay_ticker
RET

;--------Useless Stuff for Later Reference----------
; Print the letter C
ACALL busy_check
MOV DPTR, #lcd_data_wr
MOV A, #43h ; Print the letter
MOVX @DPTR, A
SWAP A
MOVX @DPTR, A

; For some reason this needed to be outside of the subroutine call. idk why
; This works, but not sure where to put it since if it's within a subroutine
; or ISR it does not function as intended.
CJNE A, #1Bh, escape_not_pressed
LJMP theend
escape_not_pressed:

theend:
END                         ; End of program.
