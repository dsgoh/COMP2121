.include "m2560def.inc"

.def tempOutput = r1
.def temp = r16
.def output = r17
.def count = r18
.def nBit = r19
.def debounce = r20
.def nFlash = r22
//.def isNextInput = r23

.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr r21
	st Y+, r21
	st Y, r21
.endmacro

.dseg 
SecondCounter:
	.byte 2

TempCounter:
	.byte 2

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

	clr output
	clr nBit
	clr debounce
	clr r0
	clr nFlash
	//clr isNextInput
	clr tempOutput

	ser temp					; set temp to 0xFF
	out DDRC, temp				; set DDRC to 0xFF, 8 pins, so setting 8 bits to 1 sets 8 pins for output

	ldi temp, (1<<ISC11) | (1<<ISC01)		; setting int1 and int0 for falling edge trigger, each pair contains "10"
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
/*	cpi isNextInput, 1
	breq handleLights*/
	cpi nBit, 8						; if we have 8 bits inputted
	breq handleLights				; we need to flash the lights
	cpi debounce, 0					; if debounce is not 0
	brne handleDebounce				; we need to make debounce 0, after some timer
	reti

	handleLights:
		in temp, SREG
		push temp
		push YH
		push YL
		push r25
		push r24

		lds r24, TempCounter
		lds r25, TempCounter+1
		adiw r25:r24, 1
		
		//cpi isNextInput, 1
		//breq lastDisplay

		cpi r24, low(7812)			; 256*8/clock speed, where clockspeed is 16MHz then 1000000/128 = 7812, 1 second
		ldi temp, high(7812)		
		cpc r25, temp
		brne NotSecond

	/*	cpi isNextInput, 1
		breq lastBlank*/

		in temp, PORTC
		cp temp, r0					; compare current state of PORTC with 0
		brne displayBlank			; if it is not equal, then we are currently displaying output, so now we want to display blank LEDs
									; if the current state is all blank
									; then we want to display the actual user inputted leds
		
		displayOutput:
			inc nFlash
			cpi nFlash, 3
			breq getNextInput
			out PORTC, output
			rjmp prologue

		/*lastDisplay:
			clr isNextInput
			out PORTC, tempOutput
			rjmp prologue*

		lastBlank:
			clr nFlash
			out PORTC, r0
			rjmp prologue*/

		displayBlank:
			out PORTC, r0
			rjmp prologue

		getNextInput:
			out PORTC, r0
			clr output
			clr nBit
			clr debounce
			clr nFlash
			rjmp prologue

	NotSecond:
		sts TempCounter, r24
		sts TempCounter+1, r25
	
	EndIF:
		pop r24
		pop r25
		pop YL
		pop YH
		pop temp
		out SREG, temp
		reti

	handleDebounce:
		in temp, SREG
		push temp
		push YH
		push YL
		push r25
		push r24

		lds r24, TempCounter
		lds r25, TempCounter+1
		adiw r25:r24, 1
		
		cpi r24, low(1953)			; 256*8/clock speed, where clockspeed is 16 then 1000000/128 = 7812
		ldi temp, high(1953)		; to be safe we use 250 milliseconds, so 7812*0.25 = 1953, which is 250 milliseconds
		cpc r25, temp
		brne NotSecond

		clear TempCounter

		lds r24, SecondCounter
		lds r25, SecondCounter+1
		adiw r25:r24, 1

		sts SecondCounter, r24
		sts SecondCounter+1, r25

		ldi debounce, 0

		rjmp EndIF

	prologue:
		clear TempCounter

		lds r24, SecondCounter
		lds r25, SecondCounter+1
		adiw r25:r24, 1

		sts SecondCounter, r24
		sts SecondCounter+1, r25
		rjmp EndIF


EXT_INT0:
	cpi debounce, 0
	breq isDebounced0
	reti

	isDebounced0:
		inc debounce
		push temp
		in temp, SREG 
		push temp

		ldi temp, 0b00000000
		rcall checkPos
		or output, temp

		;out PORTC, output

		pop temp
		out SREG, temp
		pop temp
		inc nBit
		clr count

		cpi nBit, 8
		breq display
		reti

EXT_INT1:
	cpi debounce, 0
	breq isDebounced1
	reti

	isDebounced1:
		inc debounce
		push temp
		in temp, SREG
		push temp

		ldi temp, 0b10000000
		rcall checkPos
		or output, temp

		;out PORTC, output

		pop temp
		out SREG, temp
		pop temp
		inc nBit
		clr count

		cpi nBit, 8
		breq display
		reti

display:
	out PORTC, output
	reti

// if nBit is 0, then that means this is the first user input
// and it immediately returns
// else it will run into findPos, and find the latest position of which we need
// to enter the 0 or 1 value into the pattern
checkPos:
	cpi nBit, 0
	breq return
	
// keep incrementing count to find the nBit'th position
// which is the position we last inputted a value in
findPos:
	lsr temp
	inc count
	cp count, nBit
	brlo findPos

return:
	ret

main:
	clear SecondCounter
	clear TempCounter

loop:
	rjmp loop

