.include "m2560def.inc"

.dseg
.org 0x200
	MilliCounter:				; milli counter used to allow EXT_INT2 debounce
		.byte 2

	FiveHundredCounter:			; millicounter which counts to 500 milliseconds to update display
		.byte 2

	TwoFiftyCounter:			; millicounter which counts to 250 milliseconds
		.byte 2

;==========
; Setup
;==========

.cseg
rjmp RESET

.org INT2addr
	rjmp EXT_INT2

.org OVF5addr
	rjmp Timer5OVF

.def temp = r16
.def cycles = r17
.def debounce = r18
.def nInterrupt = r19

.def temp1 = r20

.def digit1 = r21		; 10 ^ 0
.def digit2 = r22		; 10 ^ 1
.def digit3 = r23		; 10 ^ 2

.equ CLEAR_DISPLAY = 0b00000001	; clears the display
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4


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

	.macro clear
		ldi YL, low(@0)
		ldi YH, high(@0)
		clr temp
		st Y+, temp
		st Y, temp
	.endmacro

;===========
; Start
;===========

Timer5OVF:
	in temp, SREG				; store current state of status registers in temp
	push temp					; push conflict registers onto the stack
	push YH
	push YL
	push r24
	push r25

;	inc nInterrupt

	;out PORTC, nInterrupt

	lds r24, MilliCounter
	lds r25, MilliCounter+1
	adiw r25:r24, 1

	cpi r24, low(5)			; 1 millisecond
	ldi temp, high(5)		
	cpc r25, temp
	brne NotSecond				; if it is not a second yet skip to notSecond
	clr debounce				; past this is one second

	finish:
		clear MilliCounter
		lds r24, MilliCounter
		lds r25, MilliCounter+1
		adiw r25:r24, 1

		sts MilliCounter, r24
		sts MilliCounter+1, r25
		rjmp check500Milli

	NotSecond:
		sts MilliCounter, r24
		sts MilliCounter+1, r25

	check500Milli:
		lds r24, FiveHundredCounter
		lds r25, FiveHundredCounter+1
		adiw r25:r24, 1

		cpi r24, low(3906)
		ldi temp, high(3906)
		cpc r25, temp
		brne Not500Milli

		clear FiveHundredCounter
		do_lcd_command 0b10000000
		lsr cycles						; we measure cycles over 500ms, so we multiply it by 2
										; to get 1 second, then we divide it by 4, because 4 holes
		mov temp1, cycles
		clr cycles
		rcall BINARYtoBCD
		clr temp
		clr temp1

	printDigit3:
		;cp temp1, digit3
		;breq printDigit2
		ldi temp1, -1 ; we invalidate all further tests of zeros if not
		
		// do_lcd_data digit3 but cant do reigstersfawefaw
		ldi temp, 48
		add temp, digit3
		rcall lcd_data
	//	rcall lcd_wait
		
	printDigit2:
		;cp temp1, digit2
		;breq printDigit1
		ldi temp1, -1 ; we invalidate all further tests of zeros if not
		// do_lcd_data digit2
		ldi temp, 48
		add temp, digit2
		rcall lcd_data
	//	rcall lcd_wait
	
	printDigit1:
		; wait we always gotta print one digit.
		// do_lcd_data digit1
		ldi temp, 48
		add temp, digit1
		rcall lcd_data
	//	rcall lcd_wait

		rjmp EndIf

	Not500Milli:
		sts FiveHundredCounter, r24
		sts FiveHundredCounter+1, r25

	EndIf: 
		pop r24
		pop r25
		pop YL
		pop YH
		pop temp
		out SREG, temp
		reti

EXT_INT2:
	cpi debounce, 0
	breq isDebounced2
	reti

	isDebounced2:
		inc debounce
		push temp
		in temp, SREG
		push temp
		inc cycles
		pop temp
		out SREG, temp
		pop temp
		reti

RESET:
	ser temp
	out DDRC, temp ; Make PORTC all outputs
	;out PORTC, temp ; Turn on all the LEDs

	//Sets up LCD display
	ser temp			
	out DDRF, temp
	out DDRA, temp
	clr temp
	out PORTF, temp
	out PORTA, temp

	//initialisation code for LCD
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command CLEAR_DISPLAY ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	//setting up direction pin L
	ldi temp, 0b00001000
	sts DDRL, temp ; Bit 3 will function as OC5A.

	ldi temp, 0x4A 	; the value controls the PWM duty cycle
	sts OCR5AL, temp 
	clr temp
	sts OCR5AH, temp


	; Set the Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS50)
	sts TCCR5B, temp
	ldi temp, (1<< WGM50)|(1<<COM5A1)
	sts TCCR5A, temp

	ldi temp, (2 << ISC30)
	sts EICRA, temp

	in temp, EIMSK
	ori temp, (1<<INT2)			; enable INT2 in temp
	out EIMSK, temp				; write it back to EIMSK

	ldi temp, 0b00000010
	sts TCCR5B, temp
	ldi temp, 1<<TOIE5		; turns overflow interrupt bit on
	sts TIMSK5, temp

	sei

	clr nInterrupt
	clr debounce
	clr cycles

	;do_lcd_command 0b10000000
	;do_lcd_data 'a'
	

loop:
	rjmp loop

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


