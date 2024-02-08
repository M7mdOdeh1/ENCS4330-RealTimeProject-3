;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Project:   Simple Calculator   
;   File:   master.asm
;   Date:   2024-02-15
;   -----------------------------------
;   Authors:   Mohammed Owda
;              Mahmoud Hamdan
;              Yazeed Hamdan
;              Mohammad AbuShams
;   -----------------------------------
;   Inputs and Outputs:
;   Input:  2 numbers x 2 digits
;	Integer handling only  
;   Multiplication only
;   Output: 4 digits number
;   -----------------------------------
;   Description:
;   Master CPU will handle the Multiplication of the first number by the tenth digit of the second number
;   Auxiliary CPU will handle the Multiplication of the first number by the unit digit of the second number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   	   
    PROCESSOR 16F877A
    ;	Clock = XT 4MHz, standard fuse settings

    INCLUDE "P16F877A.INC"	; Include the 16F877 header file
    

	__CONFIG 0x3731	; 00011011100110001

    
; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;
    current_digit   EQU 30    ; Current digit to be incremented
    count           EQU 31            ; Counter
    num1_tens       EQU 32        ; Tens digit of the first number
    num1_unit       EQU 33        ; Unit digit of the first number
    num2_tens       EQU 34        ; Tens digit of the second number
    num2_unit       EQU 35        ; Unit digit of the second number
    timerCounter    EQU 36     ; Custom timer counter for 2-second detection
    position        EQU 37         ; Cursor position for the digit to be displayed
    state           EQU 38            ; State of input(1: first digit, 2: second digit, 4: third digit, 8: fourth digit, 16: finished)
    
; Program Begins ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG	0x00    ; Default start address 
    NOP         ; required for ICD mode
    GOTO    init
    

; Interrupt vector location ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG	0x04		; Interrupt vector location
    NOP
    BCF     INTCON, GIE    ; disable global interrupt during the interrupt
    BTFSS   INTCON, INTF       ; Check if the interrupt is from INT0
    GOTO    timerInterrupt   ; Jump to Timer0 interrupt

buttonInterrupt:
    ; check if the state is 16 (the button is pressed after the result is displayed, so we need to reset the system)
    BANKSEL state
    BTFSC   state, 4
    GOTO    resetSystem



    CALL incrementCurrentDigit  ; increment the current digit
    
    BANKSEL current_digit
    MOVF    current_digit, W      ; Move the current digit to W
    ADDLW   0x30
    BSF     Select,RS	        ; Select data mode
    CALL    send                ; Send the current digit to the LCD

    ; move cursor to the current digit
    BCF     Select,RS	; Select command mode
    MOVF    position, W
    CALL    send

    CALL    resetTimer0            ; Reset Timer0
    BCF     INTCON, INTF            ; Clear the interrupt flag
    BSF     INTCON, GIE             ; enable global interrupt
    RETFIE



; Timer Interrupt Service Routine for 2-second delay detection
timerInterrupt:
    BANKSEL INTCON
	
	BANKSEL PORTA
	DECFSZ	timerCounter    ; Decrement the timer counter and check if 2 seconds have passed
    GOTO	skip            ; Skip the next step if 2 seconds have not passed

    ; if 2 seconds have passed 

    INCF    position, F     ; increment the cursor position to move the cursor to the next digit
    BCF     Select,RS	    ; Select command mode
    MOVF    position, W
    CALL    send            ; move cursor to the next digit

    ;

    ; check state to save the current digit in the appropriate variable
    BANKSEL state
    BTFSC   state, 0          ; check if the state is 1(first digit of the first number)
    GOTO    saveNum1Tens
    BTFSC   state, 1          ; check if the state is 2(second digit of the first number)
    GOTO    saveNum1Unit    
    BTFSC   state, 2          ; check if the state is 4(first digit of the second number)
    GOTO    saveNum2Tens    
    BTFSC   state, 3          ; check if the state is 8(second digit of the second number)
    GOTO    saveNum2Unit

;--------------------------------------------------------------------------------------------

; save the current digit in num1_tens
saveNum1Tens:
    BANKSEL num1_tens
    MOVF    current_digit, W
    MOVWF   num1_tens       ; save the current digit in num1_tens

    MOVLW   0x02
    MOVWF   state          ; change the state to 2 (entering the 2nd digit of the first number)

    GOTO    resetCurrentDigit

; save the current digit in num1_unit
saveNum1Unit:
    BANKSEL num1_unit
    MOVF    current_digit, W
    MOVWF   num1_unit       ; save the current digit in num1_unit

    MOVLW    0x04    
    MOVWF    state          ; change the state to 4 (entering the 1st digit of the second number)

    ; print "x" on the LCD
    BANKSEL PORTD		; Select bank 0
    BSF    Select,RS	; Select data mode
    MOVLW	'x'
    CALL	send

    ; increment the cursor position
    INCF    position, F     ; increment the cursor position to move the cursor to the next digit

    CALL    printNumber2     ; print "Number 2" on the LCD on the first line

    GOTO    resetCurrentDigit

; save the current digit in num2_tens
saveNum2Tens:
    BANKSEL num2_tens
    MOVF    current_digit, W
    MOVWF   num2_tens       ; save the current digit in num2_tens

    MOVLW    0x08
    MOVWF    state          ; change the state to 8 (entering the 2nd digit of the second number)

    GOTO    resetCurrentDigit

; save the current digit in num2_unit
saveNum2Unit:
    BANKSEL num2_unit
    MOVF    current_digit, W
    MOVWF   num2_unit       ; save the current digit in num2_unit

    MOVLW    0x10
    MOVWF    state          ; change the state to 16 (finished entering the second number)

    ; print "=" on the LCD
    BANKSEL PORTD		; Select bank 0
    BSF    Select,RS	; Select data mode
    MOVLW	'='
    CALL	send

    CALL    printResult ; print "Result" on the LCD on the first line

    ; hide the cursor
    BCF     Select,RS	; Select command mode
    MOVLW	0x0C
    CALL	send

    ; disable the Timer0 interrupt
    BANKSEL INTCON
    BCF     INTCON, TMR0IE  ; Disable Timer0 interrupt

    BANKSEL TMR0        
	CLRF    TMR0           ; Clear Timer0

    RETFIE

;--------------------------------------------------------------------------------------------

resetCurrentDigit:
    BANKSEL PORTD		; Select bank 0
    CLRF    current_digit      ; Reset the current digit to 0
    BSF     Select,RS	; Select data mode
    MOVLW	'0'         ; print the current digit
    CALL	send

    ; make the cursor pointing to the current digit
    BCF     Select,RS	; Select command mode
    MOVF    position, W
    CALL    send
    CALL    resetTimer0            ; Reset Timer0


skip:
    BANKSEL INTCON
    BSF     INTCON, GIE     ; enable global interrupt
    BCF     INTCON, T0IF    ; Clear TMR0 overflow flag
    BANKSEL TMR0        
	CLRF    TMR0           ; Clear Timer0
    
    RETFIE              ; Return from interrupt





INCLUDE "LCDIS.INC"	; Include the LCD driver file
; Initialize the system ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init:
    
    BANKSEL	TRISB		; Select bank 1
    BSF TRISB, TRISB0
	CLRF	TRISD		; LCD output port

	BANKSEL PORTD		; Select bank 0
	MOVLW	0x01
	CLRF	PORTD		; Clear display outputs

    CALL    inid        ; Initialize LCD

    MOVLW    0x05        ; number of times to blink
    MOVWF    count

    
	GOTO	start		; Jump to main program


    
; Main program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    BANKSEL PORTD		; Select bank 0
    DECFSZ  count, 1    ; Decrement the counter and skip if zero
    GOTO   printWelcome ; make the print welcome blinking 3 times with 1 second delay

    MOVLW	0x03       ; wait for 3 seconds
    CALL	xseconds

    CALL    clearDisplay    ; Clear the display and return the cursor to the home position
    
    CALL    printNumber1     ; print "Number 1" on the LCD
    
    CALL    initInterrupts  ; Initialize the interrupts and Timer0
    CALL    resetTimer0     ; Reset Timer0

    


 

loop
    GOTO loop


; Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Reset the system
resetSystem:
    BANKSEL PORTD		; Select bank 0
    BCF    Select,RS	; Select command mode
    MOVLW    0x01	    ; clear display
    CALL    send	    ; and send code
    MOVLW	0x80	    ; position to home cursor
    CALL	send	    ; and send code

    CALL    printNumber1 ; print "Number 1" on the LCD

    ; initialize the interrupts
    CALL    initInterrupts
    CALL    resetTimer0

    RETURN

    

; Clear the display and return the cursor to the home position
clearDisplay:
    BANKSEL PORTD		; Select bank 0
    BCF	    Select, RS       ; Select command mode
    MOVLW    0x01	    ; clear display
    CALL    send	    ; and send code
    MOVLW	0x80	    ; position to home cursor
    CALL	send	    ; and send code 
    RETURN

; Initialize the interrupts and Timer0
initInterrupts:
    BANKSEL INTCON
    BSF INTCON, GIE     ; Enable global interrupt
    BSF INTCON, INTE   ; Enable external interrupt on RB0 pin
    BSF INTCON, TMR0IE  ; Enable Timer0 interrupt

    ; Initialize Timer0
    BANKSEL OPTION_REG
    MOVLW b'00000111'   ; Set Timer0 prescaler to 1:256
    MOVWF OPTION_REG 

    RETURN


resetTimer0:
	BANKSEL PORTA
	MOVLW D'30'
	MOVWF timerCounter
	BSF INTCON, T0IF    ; Clear the TMR0 overflow interrupt flag
	RETURN

; Write "Number 1" in the first line and make the cursor blinking on the second line
printNumber1:
    BANKSEL PORTD		; Select bank 0
    BSF    Select,RS	; Select data mode
    MOVLW	'N'
    CALL	send
    MOVLW	'u'
    CALL	send
    MOVLW	'm'
    CALL	send
    MOVLW	'b'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	'r'
    CALL	send
    MOVLW	' '
    CALL	send
    MOVLW	'1'
    CALL	send


    ; move cursor to the second line
    BCF     Select,RS	; Select command mode
    MOVLW	0xC0	    ; position to home cursor
    MOVWF   position    ; store the cursor position
    CALL	send	    ; and send code

    MOVLW    0x00       ; current digit
    MOVWF    current_digit
    
    BSF     Select,RS	; Select data mode
    MOVLW    '0'        ; print the current digit
    CALL    send

    ; make the cursor pointing to the current digit
    BCF     Select,RS	; Select command mode
    MOVF    position, W
    CALL    send

    ; make the cursor blinking
    MOVLW	0x0F
    CALL	send

    ; set the state to 1
    MOVLW    0x01
    MOVWF    state
    
    RETURN

; Write "2" instead of "1" in the first line and make the cursor blinking on the second line
printNumber2:
    BANKSEL PORTD		; Select bank 0
    BCF    Select,RS	; Select command mode
    MOVLW	0x87        ;position the cursor to 8th position in the first line
    CALL	send	    ; and send code

    BSF    Select,RS	; Select data mode
    MOVLW	'2'
    CALL	send

    ; return the cursor back to the second line to enter the second number
    BCF     Select,RS	; Select command mode
    MOVF    position, W ; move the cursor to previous position
    CALL    send

    RETURN

; Write "Result" in the first line
printResult:
    BANKSEL PORTD		; Select bank 0
    BCF    Select,RS	; Select command mode
    MOVLW	0x80        ;position the cursor to the first position in the first line
    CALL	send	    ; and send code

    BSF    Select,RS	; Select data mode
    MOVLW	'R'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	's'
    CALL	send
    MOVLW	'u'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	't'
    CALL	send
    MOVLW    ' '
    CALL    send
    MOVLW    ' '
    CALL    send

    

    RETURN

; print welcome message on the LCD
printWelcome:
    ; clear the display
    BCF	    Select, RS       ; Select command mode
    MOVLW    0x01	    ; clear display
    CALL    send	    ; and send code
    MOVLW	0x80	    ; position to home cursor
	CALL	send	    ; and send code 
    BSF    Select,RS	; Select data mode

    ; delay for 400ms to make the print blinking
    MOVLW   D'400'
    CALL    xms

    ; print "Welcome to" in the first line
    MOVLW	'W'		
    CALL	send		; and send code
    MOVLW	'e'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	'c'
    CALL	send
    MOVLW	'o'
    CALL	send
    MOVLW	'm'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	' '
    CALL	send
    MOVLW	't'
    CALL	send
    MOVLW	'o'
    CALL	send

    ; move cursor to the second line
    BCF     Select,RS	; Select command mode
    MOVLW	0xC0	    ; position to home cursor
    CALL	send	    ; and send code
    BSF     Select,RS	; Select data mode
    ; print "multiplication" in the second line
    MOVLW	'm'
    CALL	send
    MOVLW	'u'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	't'
    CALL	send
    MOVLW	'i'
    CALL	send
    MOVLW	'p'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	'i'
    CALL	send
    MOVLW	'c'
    CALL	send
    MOVLW	'a'
    CALL	send
    MOVLW	't'
    CALL	send
    MOVLW	'i'
    CALL	send
    MOVLW	'o'
    CALL	send
    MOVLW	'n'
    CALL	send

    ; delay for 1 second
    MOVLW	0x01
    CALL	xseconds

    GOTO    start 


; increment the current digit
incrementCurrentDigit:
    BANKSEL PORTA
    INCF    current_digit, F  ; Increment the current digit
    
    MOVLW   0x0A
    SUBWF   current_digit, W  ; Compare current digit with 10
    BTFSC   STATUS, Z         ; Skip next step if current digit is less than 10
    CLRF    current_digit     ; Reset the current digit to 0 if it 10 or more
    RETURN





  
END


