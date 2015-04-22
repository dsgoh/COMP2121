.include "m2560def.inc"

.equ PATTERN = 0b1111000000010000
.def temp = r16
.def ledsL = r17
.def ledsH = r18
.def templeds = r19

; The macro clears a word (2 bytes) in a memory
; the parameter @0 is the memory address for that word
.macro clear
	ldi YL, low(@0) 	; load the memory address to Y
	ldi YH, high(@0) 
	clr temp
	st Y+, temp			; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro

.dseg
SecondCounter:
	.byte 2					; We need a 2 byte counter for counting seconds
TempCounter:
	.byte 2					; Temporary counter, used to determine if one second has passed

.cseg
.org 0x0000
	jmp RESET

.org OVF0addr
	jmp Timer0OVF			; jump to the interrupt handler for timer0 overflow


RESET: 
	ldi temp, high(RAMEND)	; high byte of RAMEND stored into temp
	out SPH, temp			; write the high byte of RAMEND into high byte of stack pointer
	ldi temp, low(RAMEND)	; low byte of RAMEND stored into temp
	out SPL, temp			; write low byte of RAMEND into low byte of stack pointer

	ser temp				; temp stores 0xFF, reset bit to 1
	out DDRC, temp			; setting port c as output

	rjmp main

Timer0OVF:
	in temp, SREG			; saving the SREG state in temp
	push temp				; saving all conflict registers onto the stack
	push YH
	push YL
	push r25
	push r24

	lds r24, TempCounter			; loading value of tempcounter into registers
	lds r25, TempCounter + 1		; +1 because tempcounter is 2 bytes large
	adiw r25:r24, 1					; increase the temporary counter by one
	
	cpi r24, low(7812)
	ldi temp, high(7812)			; need to store into a register to allow cpc instruction
	cpc r25, temp
	brne NotSecond					; if 1 second has not yet passed we branch

	ror ledsL
	ror ledsH
	brcs Wrap
		
	out PORTC, ledsH
	clear TempCounter

	lds r24, SecondCounter			; load contents of second counter into registers
	lds r25, SecondCounter + 1
	adiw r25:r24, 1					; increment the second counter by 1

	sts SecondCounter, r24			; we need to store the new second counter back into the data memory 
	sts SecondCounter, r25
	rjmp EndIF

NotSecond:
	sts TempCounter, r24			; stores the value back into data space
	sts TempCounter + 1, r25		; stores new value of temporary counter
	rjmp EndIF

Wrap:
	clr templeds
	ror templeds
	or ledsL, templeds

	out PORTC, ledsH
	clear TempCounter

	lds r24, SecondCounter			; load contents of second counter into registers
	lds r25, SecondCounter + 1
	adiw r25:r24, 1					; increment the second counter by 1

	sts SecondCounter, r24			; we need to store the new second counter back into the data memory 
	sts SecondCounter, r25
	rjmp EndIF

EndIF:
	pop r24
	pop r25
	pop YL
	pop YH
	pop temp 
	out SREG, temp					; store data from the register into SREG
	reti

main:
	ldi ledsL, 0xFF
	ldi ledsH, 0xFF
	ldi ledsL, low(PATTERN)
	ldi ledsH, high(PATTERN)

	out PORTC, ledsH

	clear TempCounter
	clear SecondCounter
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000010			; CS02, CS01, CS00 is 010, hence we use 00000010
	out TCCR0B, temp				; prescaling value of 8
	ldi temp, 1<<TOIE0				; = 128 microseconds timer0 overflow interrupt enable
	sts TIMSK0, temp				; T/C0 interrupt enable store direct to SRAM
	sei								; enable global interrupt

loop:
	rjmp loop


