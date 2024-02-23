;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Project:   Simple Calculator   
;   File:   auxiliary.asm
;   Date:   2024-02-15
;   -----------------------------------
;
;   Auxiliary CPU will handle the Multiplication of the first number by the unit digit of the second number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    PROCESSOR 16F877A
    ;	Clock = XT 4MHz, standard fuse settings

    INCLUDE "P16F877A.INC"	; Include the 16F877 header file
    
	__CONFIG 0x3731	; 00011011100110001

; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    num1_unit	EQU			0x26
    num1_tens	EQU			0x27
    num2_unit   EQU			0x28
    result      EQU			0x30    ; 3 bytes for the result(hundreds, tens, and ones)
    res_mult    EQU			0x33    ; 2 bytes for the result of multiplication
    x           EQU			0x35    ; 1 byte for the first number
    y           EQU			0x36    ; 1 byte for the second number

; Program Begins ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG	0x00        ; Default start address 
    NOP             ; required for ICD mode
    GOTO    start   ; Jump to the start of the program
    

; Interrupt vector location ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG	0x04		; Interrupt vector location
    NOP
    GOTO    ISR

ISR:
    BANKSEL PORTD
    retfie 

INCLUDE "LCDIS.INC"	; Include the LCD driver file

; Main program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    
    BANKSEL TRISC
	movlw   0x00
	movwf   TRISC           ; portc is input 
    
	BANKSEL PORTC   
	movlw   0xFF      
	movwf   PORTC           ; set portc to 0xFF

    BANKSEL TRISC
	movlw   0xFF
	movwf   TRISC           ; portc is input  

    BANKSEL PORTC   
; keep iterating until a new value is received
loop11:
	XORWF   PORTC
	BTFSC   STATUS, Z   ; check if the number changed
	GOTO    loop11      ; if zero, it is the same number, keep iterating until a new value is received 
    
    MOVF    PORTC, W
    XORLW   0xFE
    BTFSC   STATUS, Z       ; check if the number is 0xFE
    GOTO    sendResult      ; if it is, then send the result 
    GOTO    ReceiveNumber   ; if not, recive the number

; Receive the first number and the second number
ReceiveNumber:

    BANKSEL PORTC    
	movf    PORTC, W
	andlw   b'11110000'     ; getting the upper nibble by anding with 11110000
	movwf   num1_tens
    SWAPF   num1_tens, F    ; swap the nibbles in order to make the 4-bits at the most right

	movf    PORTC, W
	andlw   b'00001111'     ; getting the lower nibble by anding with 00001111, here, no need to rotate
	movwf   num1_unit

    ; delay for 10ms
    MOVLW   0x0A
    CALL    xms

    BANKSEL PORTC
    MOVF    PORTC, W
    MOVWF   num2_unit       ; save the second number unit in num2_unit

    GOTO    firstMultiplication
backFromMultiply:

    ; test
    BANKSEL PORTD
    BSF     Select, RS       ; Select data mode
    MOVLW   0x30
    ADDWF   result+2, W
    CALL    send
    MOVLW   0x30
    ADDWF   result+1, W
    CALL    send
    MOVLW   0x30
    ADDWF   result, W
    CALL    send
    ; test

    GOTO    start


; Send the 3-digit result to PORTC
sendResult:
    BANKSEL TRISC
    MOVLW   0x00
    MOVWF   TRISC    ; portc is output
    
    BANKSEL PORTC
    SWAPF   result+2, W     ;swap the two nibbles of hundreds ans save it in W
    IORWF   result+1, W     ;put the tens in lower nibble of W
    

    MOVWF   PORTC   ; send the two most significant bits of the result in one shot

    ; delay for 10ms
    MOVLW   0x0A
    CALL    xms

    BANKSEL PORTC    
    MOVF    result, W
    MOVWF   PORTC       ; send the least significant bit
  

    ; delay for 32ms
    MOVLW   0x20
    CALL    xms

    BANKSEL PORTC

    GOTO    start


; find the multiplication of the first number and the unit digit of the second number
firstMultiplication:
    CLRF    result
    CLRF    result+1
    CLRF    result+2

    BANKSEL num2_unit
    MOVF    num2_unit, W
    MOVWF   y
    MOVF    num1_unit, W
    MOVWF   x
    CALL    multiplication  ; multiply num2_unit and num1_unit

    ; save the result in res_mult and res_mult+1
    BANKSEL res_mult
    MOVF    res_mult, W
    MOVWF   result
    MOVF    res_mult+1, W
    MOVWF   result+1

    BANKSEL num1_tens
    MOVF    num2_unit, W
    MOVWF   x
    MOVF    num1_tens, W
    MOVWF   y
    CALL    multiplication  ; multiply num2_unit and num1_tens

    ; add the result to the tens place of the result
    BANKSEL res_mult
    MOVF    res_mult, W
    ADDWF   result+1, F      ; add the result[0] to the tens place of the result
    MOVF    res_mult+1, W
    ADDWF   result+2, F      ; add the result[1] to the hundreds place of the result

    MOVF    result+1, W
    SUBLW   0x09
    BTFSS   STATUS, C           ; check if the tens is larger than 9
    GOTO    handle_carry_tens   ; if tens is larger than 9, handle the carry
    GOTO    backFromMultiply    ; if tens is not larger than 9, return



; handle the carry if res_tens is larger than 9
handle_carry_tens:
    BANKSEL result+1
    MOVLW   0x0A            
    SUBWF   result+1, F         ; subtract 10 from res_tens
    INCF    result+2, F         ; increment res_hundreds
    GOTO    backFromMultiply    ; return
    

; multiply value of x and y and store the result in res_mult
multiplication:
    BANKSEL res_mult
    CLRF    res_mult
    CLRF    res_mult+1

    MOVF    y, W
    BTFSC   STATUS, Z   
    GOTO    mult_end    ; If y is zero, return
         
mult_loop:
    MOVF    x, W       
    ADDWF   res_mult, F     ; Add x to the result
    
    ; check if the number is largaer than 9
    MOVF   res_mult, W
    SUBLW   0x09
    BTFSS   STATUS, C
    GOTO    fix_overflow
    DECFSZ  y, F            ; decrement y
    GOTO    mult_loop       ; repeat the loop
    GOTO    mult_end

fix_overflow:
    BANKSEL res_mult
    ; if the number is larger than 9, subtract 10 from it and increment the next byte 
    MOVLW   0x0A                       
    SUBWF   res_mult, F
    INCF    res_mult+1, F
    DECFSZ  y, F            ; decrement y
    GOTO    mult_loop       ; repeat the loop    
    GOTO    mult_end 

mult_end:

    RETURN


END