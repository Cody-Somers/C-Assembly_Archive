; Title: Serial Port
; Description: This program will print out any keyboard inputs onto the LCD. The
;   screen of the LCD can be cleared and cursor returned to the home position by
;   pressing the button connected to the board. In the background the board will be
;   outputting a light show with a predefined pattern and timing sequence, as well as
;   a square wave of 37us high and low periods on pin P1.0.
; Author: Cody Somers, 11271716
; Date Created: Nov 19, 2022
; Last Edited: Nov 26, 2022
; Due Date: Nov 29, 2022
; Microcontroller: 8051 with Paulmon
; Size: 583 bytes
; Variables: Uses all registers R0-R7, DTPR, and A/B.
;   Inputs: Takes in keyboard inputs, external reset button.
;   Outputs: Prints to the LCD, blinks LEDs in a predefined sequence, outputs a
;     square wave on pin P1.0.

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
DB     "Assignment4V3",0	      ;max 31 characters, plus the zero

;------ISR Locations------
extern_0  EQU 2003h         ; Location of External 0 ISR
ORG    extern_0
LCALL button_press          ; Subroutine call to clear screen
RETI

timer  EQU 200Bh            ; Location of Timer 0 ISR
ORG    timer
LCALL timerSubroutine       ; Subroutine call to blink the LEDs
RETI

RI_TI  EQU 2023h            ; Location of Serial ISR
ORG    RI_TI
LCALL LCD_Subroutine   ; Subroutine call to type to LCD
RETI

ORG    locat+64             ; executable code begins here

;------Constant Definitions--------
; Pins on board
port_a EQU 0F800h           ; Location of port A
port_b EQU 0F801h           ; Location of port B
port_abc_pgm EQU 0F803h     ; Configuration byte for ports A,B,C

; LCD commands
lcd_command_wr EQU 0FE00h   ; Write only
lcd_status_rd EQU 0FE01h    ; Read only
lcd_data_wr EQU 0FE02h      ; Write only
lcd_data_rd EQU 0FE03h      ; Read only

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm     ; Configuration byte for ports A,B,C
MOV A, #128
MOVX @DPTR, A

;----------Initialize the Pins------------
; This will set up all the interrupts as well as the timing sequence for the two
; timers that were used. Timer 0 is set to 16 bit timer with internal control while
; Timer 1 is set to 8 bit auto-reload mode.
SETB IE.7                   ; Enable all interrupts
SETB IE.4                   ; Serial Port interrupt enable
SETB IE.1                   ; Timer 0 interrupt enable
SETB IE.0                   ; External Interrupt 0 interrupt enable
SETB IP.4                   ; Sets serial interrupt priority high
SETB IP.0                   ; Sets external interrupt high
CLR IP.1                    ; Sets timer 0 interrupt low

MOV TMOD, #21h              ; Timer 0 = 16 bit, Timer 1 = 8 bit auto-reload
MOV SCON, #50h              ; This sets the serial port to Mode 1. Set to 70h for multiprocessor
MOV TH1, #250               ; Timer1 high. This sets the baud rate. Equation found manual
MOV TL1, #00h
MOV TH0, #03Dh              ; Timer0 high. Set the LED timer to a 27ms delay
MOV TL0, #0DCh              ; Timer0 low.
ANL PCON, #7Fh              ; This is just to ensure that the first bit is set to zero. Otherwise baud x2

CLR TI                      ; Clear the serial interrupts
CLR RI
CLR T0                      ; This turns it so that the second serial port will work.
                            ; Disable this to use green port

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
;   This puts it in 4-bit mode and 2 line display, cursor and blink enabled,
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

SETB TCON.4                 ; Turn Timer 0 on.

;--------Set the Initial Register Values--------
;-----For LCD-----
; This register counts from 0 to 40 to check the current length of the LCD.
MOV R5, #00h                ; Turn on

;-----For LightShow-----
; Registers are all initialized to 1 so that they are ignored by DJNZ below
MOV R1, #01h                ; Loop counter for multiplication port A
MOV R2, #01h                ; Loop counter for multiplication port B
MOV R4, #01h                ; Loop counter for blinking lights
MOV R6, #01h                ; Loop counter for division port A
MOV R7, #01h                ; Loop counter for division port B

SETB TCON.6                 ; Turn Timer 1 on.

;-----------Start of SquareWave Code---------------
; Description: Creates a square wave of a changeable length on P1.0.
; Variables: Uses R0
;   Input: None
;   Output: Squarewave on pin P1.0
HALF_PERIOD EQU 32      ; User defined constant
    ; Running this value at
    ; 1 would give a period of 6.510us
    ; 32 gives a period of 73.80us, which is 36.90us high and low.
    ; 227 gives a period of 499.0us.

ON:
  MOV R0, #HALF_PERIOD    ; Move the constant into the register
  SETB P1.0               ; Set the pin to high
  NOP                     ; Delay because of JMP at the end
  NOP                     ; JMP is two cycles, so this is the second NOP here.

DELAY:
  DJNZ R0, DELAY          ; Loop and decrement the register, which is acting as a counter

OFF:
  MOV R0, #HALF_PERIOD    ; Move the constant back into the register, since R0 equals 0 at this point
  CLR P1.0                ; Set the bit low

DELAY2:
  DJNZ R0,DELAY2          ; Loop and decrement the register.

SJMP ON                   ; Jump back to the start of the program
; This is an infinite loop, nothing will run beyond this point in the code.
;-------End of SquareWave Code----------

;-------------ISR Routines-----------
; Since there is very limited space in the location of the ISR the main coordination
; of the ISRs occurs here.

;-----Button Press-----
; Description: Clears the LCD and returns cursor to home
;   When the external button is pressed this interrupt will occur.
; Variables: Uses A, DPTR, R5
;   Input: Button Press
;   Output: Clear screen, cursor moved to home.
button_press:
  PUSH ACC
  PUSH DPL
  PUSH DPH
  LCALL busy_check
  LCALL clear_disp          ; Clears the display and returns cursor to home
  MOV R5, #00               ; Reset the current saved position of the cursor
  POP DPH
  POP DPL
  POP ACC
RET

;-----LCD Sequence-----
; Description: Takes user input and prints it to LCD screen
;   When a key is pressed on the keyboard this interrupt will occur.
; Variables: Uses A, DPTR, R5
;   Input: Key press
;   Output: Output on the LCD display
LCD_Subroutine:
  PUSH ACC
  PUSH DPL
  PUSH DPH
  ACALL user_input          ; Subroutine call put typed key onto LCD.
  POP DPH
  POP DPL
  POP ACC
RET

;-----Light Show-----
; Description: Lights up LEDs in a predefined pattern and timing.
;   Interrupt occurs whenever Timer 0 reaches its max value
; Variables: Uses A, DPTR, R1,2,3,4,6,7
;   Input: None
;   Output: Light display
; The location of the actual subroutine is below the following subroutines and timers
; that were used for the LCD.

;-----------Subroutines------------

;-----User Input-----
; Description: Takes in the user input and prints it onto the display
; Variables: Uses A, DPTR
;   Input: Key press
;   Output: Change display
user_input:
  CLR TI                    ; Clear both interrupts so that next value can be read
  CLR RI
  MOV A, SBUF               ; Move serial key press into A
  ACALL busy_check          ; Checks if busy
  MOV DPTR, #lcd_data_wr    ; Positions DPTR to write to LCD
  MOVX @DPTR, A             ; First four bits (high bits 7-4)
  SWAP A                    ; Swap
  MOVX @DPTR, A             ; Second four bits (low bits 3-0)
  ACALL check_cursor_position ; Check that cursor is still on screen
RET

;-----Cursor Position Check-----
; Description: Checks the cursor position and ensures that the cursor remains on
;   the screen at all times.
; Variables: Uses A, DPTR, R5
;   Input: None
;   Output: Changes cursor position if off screen
check_cursor_position:
  CJNE R5, #19, do_not_switch
  MOV A, #0C0h              ; Set to second line if R5 (cursor position) is equal to 19
  ACALL lcd_command
  INC R5
RET
  do_not_switch:
    CJNE R5, #39, do_not_switch2
    MOV A, #80h             ; Set to first line if R5 (cursor position) is equal to 39
    ACALL lcd_command
    MOV R5, #00             ; Resets the cursor value back to 0.
RET
  do_not_switch2:
    INC R5
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

;-----------Start of Light Show Code-------------
; NOTE: Proper headers have not been added for everything. Remained the same as in assignment 2.
; Description: Lights up LEDs in a predefined pattern and timing.
;   Interrupt occurs whenever Timer 0 reaches its max value
; Variables: Uses A, DPTR, R1,2,3,4,6,7
;   Input: None
;   Output: Light display

; DJNZ can't jump far enough so I have it jumping up to here before performing
; an AJMP down to where it is supposed to go.
tempDivisionPortB:
AJMP divisionPortB
tempDivisionPortA:
AJMP divisionPortA

timerSubroutine:            ; ISR subroutine code begins below
MOV TH0, #03Dh              ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh              ; Timer low. Timer is set 60 cycles shorter to account for delay from running code

;----------Control Sequence------------
; Description: This is the main chunk of code that dictates where everything is going to go.
;   If the program passes through all the DJNZ, the light show will reinitialize
;   and start the pattern over again.
;   This section sets the initial bytes in ports A,B to all be 0
;   This also sets the registers, which act as counters for their respective programs.
;   These registers are essentially hard coding the program to run a specific number
;   of times before it is allowed to pass through all the DJNZ and reinitialize.
; Variables: Uses R1,2,3,4,6,7
;   Input: None
;   Output: None
DJNZ R1, multiplicationPortA
DJNZ R4, multiplicationPortB
DJNZ R2, blinking
DJNZ R7, tempDivisionPortB
DJNZ R6, tempDivisionPortA

MOV A, #00h
MOV DPTR, #port_a           ; Set port A to 0
MOVX @DPTR, A
MOV DPTR, #port_b           ; Set port B to 0
MOVX @DPTR, A

MOV R1, #06h                ; This loops through port A until the pins are all set to high
MOV R4, #03h                ; This loops for the five other pins in port B. Setting high
MOV R2, #13h                ; This enters the blinking routine 18 times to get four blinks
MOV R3, #01h                ; This is needed for running the timer twice. 27ms + 15ms = 42ms
MOV R7, #04h                ; This loops for the five pins in port B. Setting low
MOV R6, #05h                ; This loops through port A until the pins are all set to low

RET                         ; Exit the program

;------------Multiplication------------
    ; This sets the ports from 0's to 1's, incrementally, starting from PA.0 to
    ; PB.4, giving a total of 13 pins.
    ; It does this by multiplying the current value by two, which is the same
    ; as bit shifting left.
    ; The time between each light turning on is 27ms

;-----Port A-----
multiplicationPortA:        ; Start of multiplication port A sequence

    ; The centre pin must light up by itself, so if this is the first time that
    ; the port A is being incremented, only do a single bit shift once.
CJNE R1, #05h, secondMult   ; If first time, continue, else skip this portion of code
MOV B, #02h                 ; Reset B value to 2
MUL AB                      ; Bit shift left
INC A                       ; Increment A
MOV DPTR, #port_a           ; Set port A
MOVX @DPTR, A
RET                         ; Exit the program

secondMult:
    ; If this is not the first time that port A is being incremented, do two bit shifts
    ; It's done twice since we want two LEDs to light up at the same time
MOV B, #02h                 ; Reset B value to 2
MUL AB                      ; Bit shift left.
INC A                       ; Increment A
MOV B, #02h                 ; Reset B value to 2
MUL AB                      ; Bit shift left.
INC A                       ; Increment A
MOV DPTR, #port_a           ; Set port A
MOVX @DPTR, A

    ; If A overflows, we know that it set PA.7, and tried to set PB.0, however
    ; it couldn't. This sets PB.0 manually and sets accumulator to the appropriate
    ; value for it to continue in port B.
PUSH 06h
MOV R6, B                   ; Temporary register to get value of B (overflow)
CJNE R6, #01h, tempMultJMP  ; If B has a value then continue, else skip this portion of code
MOV DPTR, #port_b           ; Set port B
MOV A, #01h
MOVX @DPTR, A

tempMultJMP:                ; Where the CJNE from above jumps to
POP 06h
RET                         ; Exit the program

;-----Port B-----
multiplicationPortB:        ; Start of multiplication port B sequence
    ; This sets the remaining four bits in port B to high.
    ; This is controlled by R2 only letting it enter this loop twice.
MOV R1, #01h                ; Reset R1 so that it ignores the DJNZ control sequence
MOV B, #02h                 ; Reset B value to 2
MUL AB                      ; Bit shift left
INC A                       ; Increment A
MOV B, #02h                 ; Reset B value to 2
MUL AB                      ; Bit shift left
INC A                       ; Increment A
MOV DPTR, #port_b           ; Set port B
MOVX @DPTR, A
RET                         ; Exit the program

;------------Blink the Pins-----------
    ; This will blink all of the pins four times.
    ; It will be off for 42ms, and on for 42ms.
blinking:                   ; Start of blinking sequence
MOV R1, #01h                ; Reset R1 so that it ignores the DJNZ control sequence
MOV R4, #01h                ; Reset R4 so that it ignores the DJNZ control sequence
MOV TH0, #94h               ; Timer high. Set the timer to a 15ms delay
MOV TL0, #30h               ; Timer low. (40 cycles less to account for delay)

DJNZ R3, theend
    ; This either lets the program have a 15ms timer and do nothing, (set above)
    ; or it allows the program to pass, complements the bits, and sets the timer
    ; to 27ms instead. This gives a total time between each complement of 42ms.
MOV TH0, #03Dh              ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh              ; Timer low.
MOV R3, #02h                ; Reset R3 so that timer runs twice
MOV DPTR, #port_a
MOVX A, @DPTR               ; Get current value of port A and put in accumulator
CPL A                       ; Complement accumulator
MOV DPTR, #port_a           ; Set port A
MOVX @DPTR, A
MOV DPTR, #port_b           ; Set port B (sets all of port B, not just PB.0 -> PB.4)
MOVX @DPTR, A
RET                         ; Exit the program

;-----------Division------------
    ; This sets the ports from 1's to 0's, incrementally, starting from PB.4
    ; and moving down to PA.0, eventually turning all 13 pins off.
    ; It does this by dividing the current value by two, which is the same
    ; as bit shifting right.
    ; The time between each light turning off is 27ms
;-----Port B-----
divisionPortB:              ; Start of division port B sequence
MOV R1, #01h                ; Reset R1 so that it ignores the DJNZ control sequence
MOV R4, #01h                ; Reset R4 so that it ignores the DJNZ control sequence
MOV R2, #01h                ; Reset R2 so that it ignores the DJNZ control sequence

    ; After the pins have blinked it will end on a low sequence. The following will
    ; only be entered once, and it will set both ports A and B to the required values
    ; This is necessary since port B only uses the first five bits, so if it was set to
    ; all high then the division sequence would not function correctly.
CJNE A, #00h, doDivision    ; If immediately following blink sequence enter, else skip
MOV A, #0FFh                ; Set port A to its high value (all high)
MOV DPTR, #port_a
MOVX @DPTR, A
MOV A, #1Fh                 ; Set port B to its high value (00011111)
MOV DPTR, #port_b
MOVX @DPTR, A
RET                         ; Exit the program

doDivision:
    ; This will do actual division and decrement the port B register.
    ; The decrement occurs twice so that two pins turn off at once.
    ; It will only decrement as specified by R7, and PB.0 will be still set as high
    ; after this
DEC A                       ; Decrement A
MOV B, #02h                 ; Reset B value to 2
DIV AB                      ; Bit shift right.
DEC A                       ; Decrement A
MOV B, #02h                 ; Reset B value to 2
DIV AB                      ; Bit shift right.
MOV DPTR, #port_b           ; Set port A
MOVX @DPTR, A
RET                         ; Exit the program

;-----Port A-----
divisionPortA:              ; Start of division port A sequence
MOV R1, #01h                ; Reset R1 so that it ignores the DJNZ control sequence
MOV R4, #01h                ; Reset R4 so that it ignores the DJNZ control sequence
MOV R2, #01h                ; Reset R2 so that it ignores the DJNZ control sequence
MOV R7, #01h                ; Reset R7 so that it ignores the DJNZ control sequence
DEC A                       ; Decrement A
MOV B, #02h                 ; Reset B value to 2
DIV AB                      ; Bit shift right.

    ; This sets PB.0 and PA.7 manually to 0 and sets accumulator to the appropriate
    ; value for it to continue in port A.
CJNE A, #00h, divNotFirst   ; If immediately following port B sequence continue, else skip
MOV DPTR, #port_b           ; Set port B
MOV A, #00h
MOVX @DPTR, A
MOV DPTR, #port_a           ; Set port A
MOV A, #7Fh
MOVX @DPTR, A
RET                         ; Exit the program

divNotFirst:
    ; If not the first sequence then divide port A as standard procedure
DEC A                       ; Decrement A
MOV B, #02h                 ; Reset B value to 2
DIV AB                      ; Bit shift right.
MOV DPTR, #port_a           ; Set port A
MOVX @DPTR, A
RET                         ; Exit the program

theend:                     ; Used as a label to exit the program
RET

;----------End of Light Show Code------------

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

theend2:
END                         ; End of program.
