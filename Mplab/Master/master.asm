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
    Char	EQU	30	; Display character code
    Count EQU 31 ; Counter
    Num1_Tens EQU 32 ; Tens digit of the first number
    Num1_Unit EQU 33 ; Unit digit of the first number
    Num2_Tens EQU 34 ; Tens digit of the second number
    Num2_Unit EQU 35 ; Unit digit of the second number
    
; Program Begins ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG	0x00		; Default start address 
    NOP			; required for ICD mode
    GOTO    init
    

; Interrupt vector location ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG	0x04		; Interrupt vector location
;ISR:
 ;   GOTO    start
    ;
    ; Interrupt service routine 
    ; ToDo: Add interrupt service routine here
    ;
    RETFIE		; Return from interrupt



    


INCLUDE "LCDIS.INC"	; Include the LCD driver file
; Initialize the system ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init:
    
    BANKSEL	TRISB		; Select bank 1
    BSF TRISB, TRISB0
	CLRF	TRISD		; LCD output port

    BANKSEL INTCON
    BSF INTCON, GIE
    BSF INTCON, INTE

	BANKSEL PORTD		; Select bank 0
	MOVLW	0x01
	CLRF	PORTD		; Clear display outputs

    CALL    inid        ; Initialize LCD

    MOVLW    0x04        ; number of times to blink
    MOVWF    Count

	GOTO	start		; Jump to main program


    
; Main program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    BANKSEL PORTD		; Select bank 0
    DECFSZ  Count, 1    ; Decrement the counter and skip if zero
    ; make the print welcome blinking 3 times with 1 second delay
    GOTO   printWelcome

    MOVLW	0x03       ; wait for 3 seconds
    CALL	xseconds

    ; clear the display
    BCF	    Select, RS       ; Select command mode
    MOVLW    0x01	    ; clear display
    CALL    send	    ; and send code
    MOVLW	0x80	    ; position to home cursor
	CALL	send	    ; and send code

    ; Write "Number 1" in the first line
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
    CALL	send	    ; and send code
    ; make the cursor blinking
    MOVLW	0x0F
    CALL	send




 

 

loop
    GOTO loop



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

  
END


