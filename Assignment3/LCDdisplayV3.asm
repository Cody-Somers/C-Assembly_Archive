; Title: LCDdisplay
; Description: This program will initialize the LCD display into 4 bit mode.
;   It will print my name and a fake business name to the display, before scrolling
;   both of the names off the screen to the right. After the names scroll across
;   they will flash on the left, then the right, then the centre and hold there.
;   After the process is finished it will repeat with the names swapped lines.
; Author: Cody Somers, 11271716
; Date Created: Oct 10, 2022
; Last Edited: Oct 28, 2022
; Due Date: Nov 1, 2022
; Microcontroller: 8051 with Paulmon
; Variables:
;   Inputs: None
;   Outputs: Writing display on the LCD

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
DB     "Assignment3V3",0	      ;max 31 characters, plus the zero

port_a EQU 0F800h           ; Location of port A
port_b EQU 0F801h           ; Location of port B
port_abc_pgm EQU 0F803h     ; Configuration byte for ports A,B,C

lcd_command_wr EQU 0FE00h   ; Write only
lcd_status_rd EQU 0FE01h    ; Read only
lcd_data_wr EQU 0FE02h      ; Write only
lcd_data_rd EQU 0FE03h      ; Read only

ORG    locat+64             ; executable code begins here

;-----------Configure Ports----------
MOV DPTR, #port_abc_pgm     ; Configuration byte for ports A,B,C
MOV A, #128
MOVX @DPTR, A

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

; Turn on display, with cursor and blinking cursor disabled
MOV A, #0Ch                 ; Set this back to 0Ch. Set to 0F for debug purposes
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


;-------Start of Main Program--------
; Description: This calls all the required subroutines in an infinite loop
;   that prints all the values to the screen in the required timings
; Variables: Uses A
;   Input: None
;   Output: Output on the LCD display

infinite_loop:
  ACALL print_name          ; Print my name to the first line
  MOV A, #0C0h              ; Set cursor to second line
  ACALL lcd_command
  ACALL print_business      ; Print business name to second line
  ACALL shift_right         ; Perform the shifting operation
  ACALL flash_name          ; Perform the name flashing operation

  ACALL print_business ; Print the business name on the first line
  MOV A, #0C0h              ; Set cursor to second line
  ACALL lcd_command
  ACALL print_name          ; Print my name to the second line
  ACALL shift_right         ; Perform the shifting operation
  ACALL flash_name2         ; Perform the name flashing operation

SJMP infinite_loop
; The only thing left to do is get a proper bit acc.7 check, but not sure how to do that
AJMP theend                 ; Never reached, but will exit the program. (debugging)

;--------End of Main Program----------


;-----------Strings-----------
; Description: Holds the strings for my name and the business name
; Variables: Strings stored in bytes of memory
;   Input: None
;   Output: None

cody_string:
DB " Cody Somers", 0

business_string:
DB " Tri-Flexa Designs", 0

;-----------Subroutines------------

;-----Flash Name-----
; Description: The two subroutines below will flash the names at left-justified,
;   right-justified, at 137ms, then hold in the centre for 3.4s.
;   The subroutines are identical except for the order of which they print the
;   business and name to the LCD.
; Variables: Uses A
;   Input: None
;   Output: Flashes the name left, right, centre on LCD
; Routine the flashes the program left, right, and centre
; Print name first, then business
flash_name:
  ; Set the display to be left aligned
  ACALL move_cursor_home    ; Align left
  ACALL timer_delay         ; Wait on 137ms
  ACALL clear_disp          ; Clear display
  ACALL timer_delay         ; Wait off 137ms

  ; Set the display to be right aligned
  MOV A, #089h              ; Set cursor to first line, right aligned
  ACALL lcd_command
  ACALL print_name          ; Print name
  MOV A, #0C3h              ; Set cursor to second line, right aligned
  ACALL lcd_command
  ACALL print_business      ; Print business

  ACALL timer_delay         ; Wait on 137ms
  ACALL clear_disp          ; Clear display
  ACALL timer_delay         ; Wait off 137ms

  ; Set the display to be centre aligned
  MOV A, #084h              ; Set cursor to first line, centred
  ACALL lcd_command
  ACALL print_name          ; Print name
  MOV A, #0C1h              ; Set cursor to second line, centred
  ACALL lcd_command
  ACALL print_business      ; Print business

  ACALL timer_delay2        ; Wait on 3.4s
  ACALL clear_disp          ; Clear everything
RET

; Routine the flashes the program left, right, and centre
; Print business, then name
flash_name2:
  ; Set the display to be left aligned
  ACALL move_cursor_home    ; Align left
  ACALL timer_delay         ; Wait on 137ms
  ACALL clear_disp          ; Clear display
  ACALL timer_delay         ; Wait off 137ms

  ; Set the display to be right aligned
  MOV A, #083h              ; Set cursor to first line, right aligned
  ACALL lcd_command
  ACALL print_business      ; Print business
  MOV A, #0C9h              ; Set cursor to second line, right aligned
  ACALL lcd_command
  ACALL print_name          ; Print name

  ACALL timer_delay         ; Wait on 137ms
  ACALL clear_disp          ; Clear display
  ACALL timer_delay         ; Wait off 137ms

  ; Set the display to be centre aligned
  MOV A, #081h              ; Set cursor to first line, centred
  ACALL lcd_command
  ACALL print_business      ; Print business
  MOV A, #0C4h              ; Set cursor to second line, centred
  ACALL lcd_command
  ACALL print_name          ; Print name

  ACALL timer_delay2        ; Wait on 3.4s
  ACALL clear_disp          ; Clear everything
RET

;-----Shift Right-----
; Description: This shifts the entire display to the right. Shifts it 20 times
;   which is the size of the display so that anything on the display runs off
;   to the right. Timing set by ticker_tape timer
; Variables: Uses R3, and A
;   Input: None
;   Output: Shifts the display right
shift_right:
  MOV R3, #21               ; The number of shifts to perform
  shift_loop:
  ; Set shift mode to right display shift
  ACALL ticker_tape         ; Slow down the tape speed
  MOV A, #1Fh               ; Set to 1C or 1F to perform right shift action
  ACALL lcd_command
  DJNZ R3, shift_loop       ; Loop R3 number of times
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

;-----Print Name-----
; Description: Loops through my name and print the characters to the board at the
;   current location of the cursor.
; Variables: Uses R2, R3, R4, and A
;   Input: None
;   Output: Prints entire string of my name to the LCD
; Prints my name to the board at the cursor location
print_name:
  MOV R2, #11               ; Number of letters in the string to print out
  MOV R3, #1                ; Register used for incrementing the DPTR to get proper character
  MOV R4, #1                ; Register used for keeping track of the number of loops
  print_name2:
  MOV A, R4                 ; R4 needs to be put in R3, but has to go through A
  MOV R3, A                 ; R3 now has the current character to output

  ACALL busy_check
  MOV DPTR, #cody_string    ; Move to the string of my name

  increment_name:
  INC DPTR                  ; Move to the next character
  DJNZ R3, increment_name   ; The character it moves to is determined by value in R3

  MOVX A, @DPTR             ; Move the character in string to A
  MOV DPTR, #lcd_data_wr    ; Move DPTR to data_wr
  MOVX @DPTR, A             ; Write character to board in two nibbles
  SWAP A
  MOVX @DPTR, A

  INC R4                    ; Increment loop counter so that R3 increases the number
                            ; of times it increments DPTR for character.
  DJNZ R2, print_name2      ; Go through R2 number of times.
RET

;-----Print Business-----
; Description: Loops through the business name and print the characters to the board at the
;   current location of the cursor.
; Variables: Uses R2, R3, R4, and A
;   Input: None
;   Output: Prints entire string of business name to the LCD
print_business:
  MOV R2, #17               ; Number of letters in the string to print out
  MOV R3, #1                ; Register used for incrementing the DPTR to get proper character
  MOV R4, #1                ; Register used for keeping track of the number of loops
  print_business2:
  MOV A, R4                 ; R4 needs to be put in R3, but has to go through A
  MOV R3, A                 ; R3 now has the current character to output

  ACALL busy_check
  MOV DPTR, #business_string ; Move to the business string

  increment_business:
  INC DPTR                  ; Move to the next character
  DJNZ R3, increment_business ; The character it moves to is determined by value in R3

  MOVX A, @DPTR             ; Move the character in string to A
  MOV DPTR, #lcd_data_wr    ; Move DPTR to data_wr
  MOVX @DPTR, A             ; Write character to board in two nibbles
  SWAP A
  MOVX @DPTR, A

  INC R4                    ; Increment loop counter so that R3 increases the number
                            ; of times it increments DPTR for character.
  DJNZ R2, print_business2  ; Go through R2 number of times.
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
  MOVX A, @DPTR             ; First 4 bits
  JNB acc.7, busy_go        ; If the data bit is not set, program is clear to return (busy_go)
  MOVX A, @DPTR             ; Second 4 bits. Not read but necessary for completeness
  SJMP busy_wait            ; Loop while busy flag is set
  busy_go:
  MOVX A, @DPTR             ; Second 4 bits. Ignored
  POP ACC                   ; Return value in A
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

theend:
END                         ; End of program.
