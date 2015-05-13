;==================================
; ASSUMPTION HAS BEEN MADE THAT 8-BIT CALCULATOR ALSO MEANS INPUT IS 8-BIT.
; Part D of lab 4 is also done in this file.
; Thankfully, nobody cares about overflow!
;==================================

.include "m2560def.inc"


;==================================
; registers
;==================================
	.def row = r16			; current row number
	.def col = r17			; current column number
	.def rmask = r18		; mask for current row during scan
	.def cmask = r19		; mask for current column during scan

	.def currVal = r20		; value at the top of lcd
	.def digit1 = r21		; 10 ^ 0
	.def digit2 = r22		; 10 ^ 1
	.def digit3 = r23		; 10 ^ 2

	.def temp = r24			; temporary usage
	.def temp1 = r25		; temporary usage.


;==================================
; macros
;==================================
	.macro do_lcd_command
		ldi temp, @0
		rcall lcd_command
		rcall lcd_wait
	.endmacro

	.macro do_lcd_data
		ldi temp, @0
		rcall lcd_data
		rcall lcd_wait
	.endmacro


;==================================
; constants for hardware
;==================================
	.equ PORTADIR = 0xF0	; Setting PD7-4 to output and PD3-0 to input
	.equ INITCOLMASK = 0xEF	; scan from the rightmost column
	.equ INITROWMASK = 0x01	; scan from the top row
	.equ ROWMASK = 0x0F		; for obtaining input from Port D
	.equ F_CPU = 16000000
	.equ DELAY_1MS = F_CPU / 4 / 1000 - 4


.dseg 

.cseg
	jmp RESET


;==================================
; INITIAL SETUP
;==================================
	RESET:
		ldi temp1, low(RAMEND)
		out SPL, temp1
		ldi temp1, high(RAMEND)
		out SPH, temp1

		ser temp				; sets up ports for lcd
		out DDRF, temp
		out DDRA, temp
		clr temp
		out PORTF, temp
		out PORTA, temp

		ldi temp1, PORTADIR		; load PORTADIR into temp1
		sts DDRL, temp1			; setting up direction pin A
	// just lighting up the leds for fun
		ser temp1				; sets temp1 to 1
		out DDRC, temp1			; PORTC is output
		out PORTC, temp1
	
		//initialisation code for the lcd
		do_lcd_command 0b00111000 ; 2x5x7
		;do_lcd_command 0b00001000 ; display off?
		do_lcd_command 0b00000001 ; clear display
		do_lcd_command 0b00000110 ; increment, no display shift
		do_lcd_command 0b00001110 ; Cursor on, bar, no blink
		
		do_lcd_data '0'
		do_lcd_command 0b11000000
		clr digit1
		clr digit2
		clr digit3
		clr currVal

		jmp main

;==================================
; UPDATE LCD STATE
;==================================
	main:
		ldi cmask, INITCOLMASK	; initial column mask
		clr col					; initial column
		; scan for input
		rjmp colloop

;==================================
; SCAN BUTTONS
;==================================
	colloop:
		cpi col, 4		
		breq main				; if all keys are scanned, repeat
		sts PORTL, cmask		; otherwise scan a column

		ldi temp1, 0xFF			; for slowing down the scan operation

	delay: 
		dec temp1
		brne delay

		lds temp1, PINL			; read PORTA
		andi temp1, ROWMASK		; Get the keypad output value
		cpi temp1, 0xF			; check if any row is low
		breq nextcol			

		ldi rmask, INITROWMASK	; initialise for row check
		clr row

	rowloop:
		cpi row, 4
		breq nextcol			; the row scan is over
		mov temp, temp1
		and temp, rmask		; check un-masked bit
		breq convert			; if bit is clear, the key is pressed
		inc row					; else move to the next row
		lsl rmask
		jmp rowloop

	nextcol:
		lsl cmask
		inc col
		jmp colloop

;==================================
; handling each different type of button
;==================================
convert:
		cpi col, 3				; if key is in column 3
		breq letters			; handle a, b, c, d

		cpi row, 3				; if the key is in row 3
		breq symbols			; handle *, 0, #
	
	handle1to9:
		; find out the number if 1-9
		mov temp1, row			
		lsl temp1
		add temp1, row
		add temp1, col
		inc temp1
		; shift up decimal digits
		mov digit3, digit2
		mov digit2, digit1
		; store latest digit (which is smallest) in smallest digit.
		mov digit1, temp1
		subi temp1, -48		; ascii constant for start of numbers
		
		; do lcd data (without macro cause cant reference registers)
		mov temp, temp1
		rcall lcd_data
		rcall lcd_wait
		
		jmp convert_end

	letters:
		// might as well just handle the convert to binary here!
		// however, try not to destroy temp1 then...
		rcall BCDtoBINARY
		cpi row, 0			; if we have an 'A'
		breq A
		cpi row, 1			; if we have a 'B'
		breq B
		cpi row, 2			; if we have an 'C'
		breq C
		cpi row, 3			; if we have a 'D'
		breq D
		jmp convert_end		; we shouldnt reach this line ever.

	symbols:
		cpi col, 0			; if we have a star
		breq star
		cpi col, 1			; if we have a zero
		breq n0
		jmp convert_end		; else: hash (column 2) does nothing. column 3 is checked earlier.


	A:	// Addition
		add currVal, temp1
		jmp updateAll

	B:	// Subtraction
		sub currVal, temp1
		jmp updateAll

	C:	// Multiplication
		mov temp, currVal
		clr currVal
		multiplyLoop:
			cpi temp1, 0
			breq postMultiplyLoop
			subi temp1, 1
			add currVal, temp
			rjmp multiplyLoop
		postMultiplyLoop:
			jmp updateAll

	D:	// Division
		// skip if we're trying to divide by zero.. infinite loop otherwise.
		cpi temp1, 0
		breq updateAll		

		// otherwise, loop. and... floor the remainder.
		clr temp
		divisionLoop:
			sub currVal, temp1
			brcs postDivisionLoop
			inc temp
			rjmp divisionLoop
		postDivisionLoop:
			mov currVal, temp
		jmp updateAll


	star: // reset the accumulator to zero. easy peasy.
		jmp RESET ; AHAHAHAHAHA SO LAZY AHAHAHA

	n0:	// 0 is just, in an awkward non progressive area ukno?
		mov digit3, digit2	; shift up decimal digits
		mov digit2, digit1
		clr digit1			; store 0 in digit1
		do_lcd_data 48		; print 0
		jmp convert_end



	updateAll: 	// ONLY EXECUTED BECAUSE OF A,B,C,D
				// ASSUMING CURRVAL IS ALREADY ITS NEW VALUE		
		do_lcd_command 0b00000001 ; clear display, go to first row
		
		mov temp1, currVal
		rcall BINARYtoBCD
		
		// now using temp1 for removing consequtive most significant zeros
		clr temp1
		clr temp		

	printDigit3:
		cp temp1, digit3
		breq printDigit2
		ldi temp1, -1 ; we invalidate all further tests of zeros if not
		
		// do_lcd_data digit3 but cant do reigstersfawefaw
		ldi temp, 48
		add temp, digit3
		rcall lcd_data
		rcall lcd_wait
		
	printDigit2:
		cp temp1, digit2
		breq printDigit1
		ldi temp1, -1 ; we invalidate all further tests of zeros if not

		// do_lcd_data digit2
		ldi temp, 48
		add temp, digit2
		rcall lcd_data
		rcall lcd_wait
	
	printDigit1:
		; wait we always gotta print one digit.
		// do_lcd_data digit1
		ldi temp, 48
		add temp, digit1
		rcall lcd_data
		rcall lcd_wait

	updateLineTwo:
		; go to bottom bar, wait for input.
		do_lcd_command 0b11000000	
		clr digit1
		clr digit2
		clr digit3
		rjmp convert_end

	convert_end:
		rcall sleep_220ms
		jmp main 



;==================================
; CONVERT BCD TO BINARY
; check digit1,2,3
; convert them into binary (add them either 100, 10 or 1 times)
; RESULT STORED IN temp1
;==================================
	BCDtoBINARY:
		clr temp1
		push temp ; i dunno, maybe you wanted temp? lol

		hundreds:
			clr temp
		hundredsLoop:
			cpi temp, 100
			breq tens

			add temp1, digit3
			inc temp
			rjmp hundredsLoop

		tens:
			clr temp
		tensLoop:
			cpi temp, 10
			breq ones

			add temp1, digit2
			inc temp
			rjmp tensLoop

		ones:
			add temp1, digit1
				
		pop temp
		ret

;==================================
; CONVERT BINARY TO BCD
; using the number stored in temp1, generate bcd for numbers in digit 1,2,3
; RESULT STORED IN digit1,2,3\
; temp1 is destroied in the process

; could do the bit shift -> add 3 if >5 algorithm
; but the divide by power method is appropriate (easier!) for an 8-bit instruction set.
;==================================
	BINARYtoBCD:
		// ok fkn, lets do the bit shift thing
		clr digit1
		clr digit2
		clr digit3
		clr temp 	;count to 8 to determine algorithm finish
		
		addThrees:
			andi digit1, 0x0F 	;clear the top half	
			andi digit2, 0x0F 	;clear the top half	
			andi digit3, 0x0F 	;clear the top half

			cpi digit1, 5
			brlt skipFixD1
				subi digit1, -3
			skipFixD1:

			cpi digit2, 5
			brlt skipFixD2
				subi digit2, -3
			skipFixD2:

			cpi digit3, 5
			brlt skipFixD3
				subi digit1, -3
			skipFixD3:
		
			andi digit1, 0x0F 	;clear the top half	
			andi digit2, 0x0F 	;clear the top half	
			andi digit3, 0x0F 	;clear the top half
		
		leftShift: 
			lsl temp1
			rol digit1
			swap digit1
			lsr digit1	; janky way of getting the carry for 8 bits, bcd just4 bits
			
			rol digit2
			swap digit2
			lsr digit2
			
			rol digit3	; biggest digit doesnt need to carry anything.
			
			// fix up digit 1 and 2 lol
			lsl digit1
			swap digit1
			lsl digit2
			swap digit2			
			
		

			inc temp
			cpi temp, 8
			brlt addThrees
			
		ret
	

	oldBINARYtoBCD:
		clr digit1
		clr digit2
		clr digit3
		
		
		; see if subtracting a hundred goes below zero.
		removeHundreds:
			subi temp1, 100	
			cpi temp1, 0
			brlt postRemoveHundreds
			inc digit3
			rjmp removeHundreds
		postRemoveHundreds:
			ldi temp, 100
			add temp1, temp
			;subi temp1, -100 ; go back to having real unsigned data...

			
		removeTens:
			subi temp1, 10
			cpi temp1, 0
			brlt postRemoveTens
			inc digit2
			rjmp removeTens
		postRemoveTens:
			ldi temp, 10
			add temp1, temp
			;subi temp1, -10
		
		
		removeOnes:
			mov digit1, temp1
			

		ret

		
;==================================
; Send a command to the LCD (temp)
;==================================

	.equ LCD_RS = 7
	.equ LCD_E = 6
	.equ LCD_RW = 5
	.equ LCD_BE = 4

	.macro lcd_set
		sbi PORTA, @0
	.endmacro

	.macro lcd_clr
		cbi PORTA, @0
	.endmacro

	lcd_command:
		out PORTF, temp
		rcall sleep_1ms
		lcd_set LCD_E
		rcall sleep_1ms
		lcd_clr LCD_E
		rcall sleep_1ms
		ret

	lcd_data:
		out PORTF, temp
		lcd_set LCD_RS
		rcall sleep_1ms
		lcd_set LCD_E
		rcall sleep_1ms
		lcd_clr LCD_E
		rcall sleep_1ms
		lcd_clr LCD_RS
		ret

	lcd_wait:
		push temp
		clr temp
		out DDRF, temp
		out PORTF, temp
		lcd_set LCD_RW
		lcd_wait_loop:
		rcall sleep_1ms
		lcd_set LCD_E
		rcall sleep_1ms
		in temp, PINF
		lcd_clr LCD_E
		sbrc temp, 7
		rjmp lcd_wait_loop
		lcd_clr LCD_RW
		ser temp
		out DDRF, temp
		pop temp
		ret

;==================================
; SLEEP FUNCTIONS
;==================================
	sleep_1ms:
		push r24
		push r25
		ldi r25, high(DELAY_1MS)
		ldi r24, low(DELAY_1MS)

	delayloop_1ms:
		sbiw r25:r24, 1
		brne delayloop_1ms
		pop r25
		pop r24
		ret

	sleep_5ms:
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		ret
	sleep_20ms:
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		ret
	sleep_100ms:
		rcall sleep_20ms
		rcall sleep_20ms
		rcall sleep_20ms
		rcall sleep_20ms
		rcall sleep_20ms
		ret

	sleep_220ms:
		rcall sleep_100ms
		rcall sleep_100ms
		rcall sleep_20ms
		rcall sleep_20ms
		ret
