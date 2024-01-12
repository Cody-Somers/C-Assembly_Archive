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
DB     "Assignment1_v2",0	     ;max 31 characters, plus the zero

ORG    locat+64                ;executable code begins here

; Title: Square Wave Generator
; Description: Will produce a square wave with a period of minimum 6.51us to as large as needed.
; Author: Cody Somers, 11271716
; Due Date: Sept 22,2022
; Variables:
;   Inputs: None
;   Outputs: P1.0 into a squarewave.

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
JMP ON                  ; Jump back to the start of the program

END                     ; End of program.
