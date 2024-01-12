; Title: Light Show
; Description: Blink a series of LEDs in a pattern, on repeat indefinitely.
;   Makes use of timer interrupts to achieve the LED activation.
;   Will also have a squarewave running in the background.
; Author: Cody Somers, 11271716
; Due Date: Oct 11,2022
; Variables:
;   Inputs: None
;   Outputs: Squarewave on P1.0. LED patter on ports A and B

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
DB     "Assignment2",0	       ;max 31 characters, plus the zero

port_a EQU 0F800h ; To use port A
port_b EQU 0F801h ; To use port B
port_abc_pgm EQU 0F803h ; To configure all abc ports


timer  EQU 200Bh               ;Location for ISR of Timer 0. 2000 location taken from Paulmon
ORG    timer
; So here we jump back to the main program, below the square wave stuff.
; Then we return back to here and continue on.
;LCALL timerSubroutine

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
MOV DPTR, #port_a
MOV R5, #80h
MOVX @DPTR, R5
;SETB P1.0               ; Set the pin to high
NOP                     ; Delay because of JMP at the end
NOP                     ; JMP is two cycles, so this is the second NOP here.

DELAY:
DJNZ R0,DELAY           ; Loop and decrement the register, which is acting as a counter

OFF:
MOV R0, #HALF_PERIOD    ; Move the constant back into the register, since R0 equals 0 at this point
MOV DPTR, #port_a
MOV R5, #00h
MOVX @DPTR, R5
;CLR P1.0                ; Set the bit low

DELAY2:
DJNZ R0,DELAY2          ; Loop and decrement the register.
SJMP ON                 ; Jump back to the start of the program

;---------------New Code-----------------

timerSubroutine:
; Reset the count on the timer. (set a little shorter to allow for delay from running commands)
MOV TH0, #03Dh ; Timer high. Set the timer to a 27ms delay
MOV TL0, #0DCh ; Timer low.

;----------Control Sequence------------
; Initialize the registers to be 0, but only do this when the pins reach all high
DJNZ R1, multiplication
DJNZ R4, multiplicationPortA
DJNZ R2, blinking
MOV A, #00h
MOV B, #02h
MOV P1, A ; Put A onto output port P1
MOV DPTR, #port_a
MOVX @DPTR, A
MOV R1, #09h ; This means that it will loop 8 times for P1 before it enters this routine again
MOV R4, #06h ; This is the 5 other pins in port A
MOV R2, #12h ; Set R2 so that it will jump into the blinking routine 18 times
MOV R3, #02h ; This is so that the timer runs twice. Once at 27ms, the other at 15ms.
SJMP theend

;------------Multiplication------------
multiplication:
MOV B, #02h ; Reset B value to 2
MUL AB ; Bit shift left.
INC A ; Increment A
; Do the above twice so that two pins turn on at once (Not implemented yet)
MOV P1, A ; Put R1 onto output port P1
SJMP theend

multiplicationPortA:
MOV R1, #01h ; Reset R1 so that it ignores the DJNZ command above
MOV B, #02h ; Reset B value to 2
MUL AB ; Bit shift left
INC A ; Increment A

MOV R5, B ; Temporary register to get value of B
CJNE R5, #01h, notFirst ; If this is the first value in Port A continue, else jmp
MOV DPTR, #port_a
MOV A, #03h
MOVX @DPTR, A
SJMP theend

notFirst:
MOV DPTR, #port_a
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
MOV A, P1 ; Put P1 in A so that it is all 1's or 0's.
CPL A ; Complement A
MOV P1, A ; Put A onto output port P1
MOV DPTR, #port_a
MOVX @DPTR, A
SJMP theend

theend:
RET

END                     ; End of program.
