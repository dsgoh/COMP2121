.include "m2560def.inc"

.equ DOUBLESPEED_SIZE = 2
.def isPressed0 = r5
.def isPressed1 = r6
.def temp = r16
.def newOutput = r17
.def currOutput = r18
.def nBit = r19
.def nFlash = r21
.def isDisplaying = r22

.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr temp
	st Y+, temp
	st Y, temp
.endmacro

.dseg 
SecondCounter:
	.byte 2

MilliCounter:
	.byte 2

ButtonCounter:
	.byte 2

Pattern:
	.byte 32

.cseg
	jmp RESET

.org INT0addr		; address of external interrupt 0
	jmp EXT_INT0

.org INT1addr		; address of external interrupt 1
	jmp EXT_INT1

.org OVF0addr
	jmp Timer0OVF

/*
	Configurations
	INT0: PB0
	INT1: PB1
*/

RESET:
	ldi temp, low(RAMEND)		; initialise the stack 
	out SPL, temp
	ldi temp, high(RAMEND) 
	out SPH, temp

	//letting x and z pointers to point to pattern
	//in data memory
	//x will keep track of the addresses we are loaded until
	//z will keep track of the next available address to store new inputs
	ldi xl, low(Pattern)
	ldi xh, high(Pattern)
	ldi zl, low(Pattern)
	ldi zh, high(Pattern)

	clr newOutput
	clr nBit
	clr nFlash
	clr currOutput
	clr isDisplaying
	clr isPressed0
	clr isPressed1
	clr r0

	ser temp					; set temp to 0xFF
	out DDRC, temp				; set DDRC to 0xFF, 8 pins, so setting 8 bits to 1 sets 8 pins for output

	ldi temp, (2<<ISC10) | (2<<ISC00)		; setting int1 and int0 for falling edge trigger, each pair contains "10"
	sts EICRA, temp							; store temp back into EICRA
	
	in temp, EIMSK							; store current state of EIMSK in temp
	ori temp, (1<<INT0) | (1<<INT1)			; enable INT0 and INT1 in temp
	out EIMSK, temp							; write it back to EIMSK

	ldi temp, 0b00000010
	out TCCR0B, temp
	ldi temp, 1<<TOIE0		; turns overflow interrupt bit on
	sts TIMSK0, temp

	sei

	jmp main

Timer0OVF:
	in temp, SREG				; store current state of status registers in temp
	push temp					; push conflict registers onto the stack
	push YH
	push YL
	push r25
	push r24

	lds r24, SecondCounter
	lds r25, SecondCounter+1
	adiw r25:r24, 1

	sbiw z, DOUBLESPEED_SIZE
	cp xl, zl
	cpc xh, zh
	brlt halfSecond
	adiw z, DOUBLESPEED_SIZE
	jmp timeSecond

	halfSecond:
		adiw z, DOUBLESPEED_SIZE
		cpi r24, low(3906)
		ldi temp, high(3906)
		cpc r25, temp
		breq startDisplay

	timeSecond:
		cpi r24, low(7812)			; 256*8/clock speed, where clockspeed is 16MHz then 1000000/128 = 7812, 1 second
		ldi temp, high(7812)		
		cpc r25, temp
		brne NotSecond				; if it is not a second yet skip to notSecond

	; on less than 8 bits, it will skip through all of these and go down
	; to flashDisplay
	startDisplay:
		;cpi nFlash, 3				
		;breq clearLights
		cp xl, zl
		cpc xh, zh
		brge finishSecondCounter
		out PortC, r0
		cpi isDisplaying, 0
		brne clearLights

	; when we have less than 8 bits, leds will not flash,
	; since currOutput is still 0
	flashDisplay:
		ld currOutput, x
		out PORTC, currOutput
		inc isDisplaying					; sets isDisplaying to 1, display is showing
		inc nFlash							; we flash, so we increment it
		rjmp finishSecondCounter

	; will only enter here if we have 8 bits
	; this clears the lights
	; sets the isDisplaying "boolean" to false
	clearLights:
		out PORTC, r0
		clr isDisplaying
		cpi nFlash, 3
		breq clearNFlash
		rjmp finishSecondCounter

	clearNFlash:
		clr nFlash
		adiw x, 1
		
	finishSecondCounter:
		clear SecondCounter 		; reset the temporary counter.
	    lds r24, SecondCounter		; loading value of second counter, so storing it into r24 and r25
	    lds r25, SecondCounter+1
	    adiw r25:r24, 1     		; increase second counter by 1

	    sts SecondCounter, r24
	    sts SecondCounter+1, r25
	    rjmp checkMilli

	NotSecond:
		sts SecondCounter, r24
		sts SecondCounter+1, r25

	checkMilli:
/*		lds r24, MilliCounter
		lds r25, MilliCounter+1
		adiw r25:r24, 1

		cpi r24, low(1000)
		ldi temp, high(1000)
		cpc r25, temp
		brne NotMilli
		clr debounce
		clear MilliCounter
		rjmp checkButton

	NotMilli:
		sts MilliCounter, r24
		sts MilliCounter+1, r25
*/
	checkButton:
		lds r24, ButtonCounter
		lds r25, ButtonCounter+1
		adiw r25:r24, 1

		cpi r24, low(953)
		ldi temp, high(953)
		cpc r25, temp
		brne NotButton
		clr isPressed0
		clr isPressed1
		clear ButtonCounter
		rjmp EndIF

	NotButton:
		sts ButtonCounter, r24
		sts ButtonCounter+1,r25

	EndIF:
        pop r24          
        pop r25          ; restoring conflict registers
        pop YL
        pop YH
        pop temp
        out SREG, temp
        reti         		; return from interrupt

EXT_INT0:
	;ldi temp, (1<<ISC11) | (1<<ISC10) | (1<<ISC01) | (1<<ISC00)		; setting int1 and int0 for rising edge trigger, when signal is presented
	;sts EICRA, temp							; store temp back into EICRA

	//this section handles multiple button press
		;in temp, EIFR
		;cpi temp, 0b00000010
		;breq handleMultiplePress
	mov temp, isPressed1
	cpi temp, 1
	breq handleMultiplePress
	
	mov temp, isPressed0
	cpi temp, 0
	breq isDebounced0

	;ldi temp, (1<<ISC11) | (0<<ISC10) | (1<<ISC01) | (0<<ISC00)		; setting int1 and int0 for falling edge trigger, each pair contains "10"
	;sts EICRA, temp						

	reti

	isDebounced0:
		inc isPressed0
		push temp
		in temp, SREG 
		push temp


			//this section handles multiple button press
			;in temp, EIFR
			;cpi temp, 0b00000010
			;breq handleMultiplePress

		lsl newOutput 			; this adds a zero
		
	;	ldi temp, 0b10000000	; tells the user they selected PB0
		;out PORTC, nBit		; outputs it

	;	st z, newOutput

		pop temp
		out SREG, temp
		pop temp
		inc nBit
		out PORTC, nBit		; outputs it
		cpi nBit, 8
		breq updateOutput					

		reti

EXT_INT1:
	mov temp, isPressed0
	cpi temp, 1
	breq handleMultiplePress
	mov temp, isPressed1
	cpi temp, 0
	breq isDebounced1				

	reti

	isDebounced1:
		inc isPressed1
		push temp
		in temp, SREG
		push temp

		lsl newOutput					; shifts everything by 1
		ori newOutput, 0b00000001		; then or's with 1

		;st z, newOutput

		;ldi temp, 0b01000000			; this is used to tell the user that we selected PB1
		;out PORTC, nBit				; outputs it

		pop temp
		out SREG, temp
		pop temp
		inc nBit
	out PORTC, nBit				; outputs it
		cpi nBit, 8
		breq updateOutput					

		reti

handleMultiplePress:
	clr temp
	out EIFR, temp
	out PORTC, temp
	ldi temp, 0xFF
	mov currOutput, temp
	jmp RESET					; we reset, which is clearing the queue
		/*clearQueue:
			st x+, temp			; increment x and continue clearing
			cp xl, zl			; until it reaches z
			cpc xh, zh
			brne clearQueue*/

; When we have fulfilled all 8 bits,
; we will update our currentoutput
updateOutput:
	st z+, newOutput
	clr nBit
	reti

main:
	clear SecondCounter
	clear MilliCounter

loop:
	rjmp loop
