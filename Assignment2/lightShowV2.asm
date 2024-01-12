; Title: Light Show
; Description: Will produce a square wave with a period of minimum 6.51us to as large as needed.
;   From this it will also do some ISR routines that turn on some LEDs
; Author: Cody Somers, 11271716
; Due Date: Oct 11,2022
; Variables:
;   Inputs:
;   Outputs:

; Things to do, there is a 42ms instead of 27ms on the very last light in port B
; Still need to fix port A, but port B is doing the right thing
; With port A its because of the check condition waiting for 00h. So just play around with that.


locat  EQU 8000h               ;Location for this program
ORG    locat

DB     0A5h,0E5h,0E0h,0A5h     ;signiture bytes
DB     35,255,0,0              ;id (35=prog)
DB     0,0,0,0                 ;prompt code vector
DB     0,0,0,0                 ;reserved
DB     0,0,0,0                 ;reserved
DB     0,0,0,0                 ;reserved
DB     0,0,0,0                 ;user defined
DB     255,255,255,255         ;length and checksum (255=unused)
DB     "Assignment2V2",0	     ;max 31 characters, plus the zero

port_a EQU 0F800h ; To use port A
port_b EQU 0F801h ; To use port B
port_abc_pgm EQU 0F803h ; To configure all abc ports


timer  EQU 200Bh               ;Location for ISR of Timer 0. 2000 location taken from Paulmon
ORG    timer
; So here we jump back to the main program, below the square wave stuff.
; Then we return back to here and continue on.
LCALL timerSubroutine

RETI


ORG    locat+64                ;executable code begins here

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm
MOV A, #128
MOVX @DPTR, A

; This is how to use it
; MOV DPTR, #port_a
; MOV A, #0FFh
; MOVX @DPTR, A

;----------Initialize the Pins------------
SETB IE.7 ; Enable interrupt
SETB IE.1 ; Timer 0 interrupt enable
MOV TMOD, #01h ; Turns it into a 16 bit timer, with internal control
MOV TH0, #03Dh ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh ; Timer low.
;MOVX F800h, #80h

; Below are set to 1 so that they are ignored in the first time it goes through DJNZ
MOV R1, #01h ; Loop counter for initial pins
MOV R2, #01h ; Loop counter for blinking pins
MOV R4, #01h ; Loop counter for port A pins
MOV R6, #01h ; Loop counter for division port A
MOV R7, #01h ; Loop counter for division port B

SETB TCON.4 ; Turn Timer 0 on.
; TCON.0 ; could be set to toggle whether its edge or level triggered.


;----------------Old Code---------------

HALF_PERIOD EQU 32 ; User defined constant
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

tempDivisionPortB:
AJMP divisionPortB
tempDivisionPortA:
AJMP divisionPortA

timerSubroutine:
; Reset the count on the timer. (set a little shorter to allow for delay from running commands)
MOV TH0, #03Dh ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh ; Timer low.

;----------Control Sequence------------
; Initialize the registers to be 0, but only do this when the pins reach all high
DJNZ R1, multiplicationPortA
DJNZ R4, multiplicationPortB
DJNZ R2, blinking
DJNZ R7, tempDivisionPortB
DJNZ R6, tempDivisionPortA
MOV A, #00h
MOV B, #02h
MOV DPTR, #port_a
MOVX @DPTR, A
MOV DPTR, #port_b
MOVX @DPTR, A
MOV R1, #09h ; This means that it will loop 8 times for port A before it enters this routine again
MOV R4, #06h ; This is the 5 other pins in port B
MOV R2, #13h ; Set R2 so that it will jump into the blinking routine 18 times
MOV R3, #01h ; This is so that the timer runs twice. Once at 27ms, the other at 15ms. Ignored first time
MOV R6, #08h ; This means that it will loop 8 times for port A before it enters this routine again
MOV R7, #07h ; This is the 5 other pins in port B
AJMP theend

;------------Multiplication------------
multiplicationPortA:
MOV B, #02h ; Reset B value to 2
MUL AB ; Bit shift left.
INC A ; Increment A
; Do the above twice so that two pins turn on at once (Not implemented yet)
MOV DPTR, #port_a
MOVX @DPTR, A
SJMP theend

multiplicationPortB:
MOV R1, #01h ; Reset R1 so that it ignores the DJNZ command above
MOV B, #02h ; Reset B value to 2
MUL AB ; Bit shift left
INC A ; Increment A

MOV R5, B ; Temporary register to get value of B
CJNE R5, #01h, mulNotFirst ; If this is the first value in Port B continue, else jmp
MOV DPTR, #port_b
MOV A, #01h
MOVX @DPTR, A
SJMP theend

mulNotFirst:
MOV DPTR, #port_b
MOVX @DPTR, A
SJMP theend

;------------Blink the Pins-----------
blinking:
MOV R1, #01h ; Reset R1 so that it ignores the DJNZ command above
MOV R4, #01h ; Reset R4 so that it ignores the DJNZ command above
MOV TH0, #94h ; Timer high. Set the timer to a 15ms delay
MOV TL0, #30h ; Timer low.

DJNZ R3, theend
MOV TH0, #03Dh ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh ; Timer low.
MOV R3, #02h ; Reset the timer for twice
MOV DPTR, #port_a
MOVX A, @DPTR
CPL A ; Complement A
MOV DPTR, #port_a
MOVX @DPTR, A
MOV DPTR, #port_b
MOVX @DPTR, A
SJMP theend

;-----------Division------------
divisionPortB:
MOV R1, #01h ; Reset R1 so that it ignores the DJNZ command above
MOV R4, #01h ; Reset R4 so that it ignores the DJNZ command above
MOV R2, #01h ; Reset R2 so that it ignores the DJNZ command above

CJNE A, #00h, doDiv
MOV A, #0FFh ; Set it so that its what port A is supposed to be high as
MOV DPTR, #port_a
MOVX @DPTR, A
MOV A, #1Fh ; Set it so that its what port B is supposed to be high as
MOV DPTR, #port_b
MOVX @DPTR, A
SJMP theend

doDiv:
DEC A
MOV B, #02h ; Reset B value to 2
DIV AB ; Bit shift right.
MOV DPTR, #port_b
MOVX @DPTR, A
SJMP theend

divisionPortA:
MOV R1, #01h ; Reset R1 so that it ignores the DJNZ command above
MOV R4, #01h ; Reset R4 so that it ignores the DJNZ command above
MOV R2, #01h ; Reset R2 so that it ignores the DJNZ command above
MOV R7, #01h ; Reset R7 so that it ignores the DJNZ command above
DEC A
MOV B, #02h ; Reset B value to 2
DIV AB ; Bit shift right.

CJNE A, #00h, divNotFirst ; If this is the first value in Port A continue, else jmp
MOV DPTR, #port_a
MOV A, #7Fh
MOVX @DPTR, A
SJMP theend

divNotFirst:
MOV DPTR, #port_a
MOVX @DPTR, A
SJMP theend

theend:
RET

END                     ; End of program.
