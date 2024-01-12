; Title: Light Show
; Description: Blink a series of LEDs in a pattern, on repeat indefinitely.
;   Makes use of timer interrupts to achieve the LED activation.
;   Will also have a squarewave running in the background.
; Author: Cody Somers, 11271716
; Date Created: Sept 26, 2022
; Last Edited: Oct 10, 2022
; Due Date: Oct 11, 2022
; Microcontroller: 8051 with Paulmon
; Variables:
;   Inputs: None
;   Outputs: Squarewave on P1.0. LED pattern on ports A and B

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
DB     "Assignment2V3",0	      ;max 31 characters, plus the zero

port_a EQU 0F800h           ; Location of port A
port_b EQU 0F801h           ; Location of port B
port_abc_pgm EQU 0F803h     ; Configuration byte for ports A,B,C

timer  EQU 200Bh            ; Location of Timer 0 ISR
ORG    timer
LCALL timerSubroutine       ; Subroutine call to below the squarewave code
RETI

ORG    locat+64             ; executable code begins here

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm     ; Configuration byte for ports A,B,C
MOV A, #128
MOVX @DPTR, A

;----------Initialize the Pins------------
    ; This sets up the interrupt timer to use the 16 bit timer with internal control.
    ; Sets the high and low so that it is has a 27ms delay.
SETB IE.7                   ; Enable interrupt
SETB IE.1                   ; Timer 0 interrupt enable
MOV TMOD, #01h              ; Turns it into a 16 bit timer, with internal control
MOV TH0, #03Dh              ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh              ; Timer low.

    ; Registers are all initialized to 1 so that they are ignored by DJNZ below
MOV R1, #01h                ; Loop counter for multiplication port A
MOV R2, #01h                ; Loop counter for multiplication port B
MOV R4, #01h                ; Loop counter for blinking lights
MOV R6, #01h                ; Loop counter for division port A
MOV R7, #01h                ; Loop counter for division port B

SETB TCON.4                 ; Turn Timer 0 on.
; TCON.0                    ; Could be used to set toggle edge or level triggered.

;----------------Old Code---------------
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
DJNZ R0,DELAY           ; Loop and decrement the register, which is acting as a counter

OFF:
MOV R0, #HALF_PERIOD    ; Move the constant back into the register, since R0 equals 0 at this point
CLR P1.0                ; Set the bit low

DELAY2:
DJNZ R0,DELAY2          ; Loop and decrement the register.
SJMP ON                 ; Jump back to the start of the program

;---------------New Code-----------------
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
    ; This is the main chunk of code that dictates where everything is going to go.
    ; If the program passes through all the DJNZ, the light show will reinitialize
    ; and start the pattern over again.
    ; This section sets the initial bytes in ports A,B to all be 0
    ; This also sets the registers, which act as counters for their respective programs.
    ; These registers are essentially hard coding the program to run a specific number
    ; of times before it is allowed to pass through all the DJNZ and reinitialize.
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
MOV R5, B                   ; Temporary register to get value of B (overflow)
CJNE R5, #01h, tempMultJMP  ; If B has a value then continue, else skip this portion of code
MOV DPTR, #port_b           ; Set port B
MOV A, #01h
MOVX @DPTR, A

tempMultJMP:                ; Where the CJNE from above jumps to
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

END                         ; End of program.
