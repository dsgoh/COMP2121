.include "m2560def.inc"

.dseg
.org 0x200

;==============
; SETUP
;==============

.cseg 
rjmp RESET

.org OVF5addr
	jmp Timer5OVF

.def temp = r16
.def brightness = r17

;================
; TIMER
;================

Timer5OVF:
	in temp, SREG
	push temp
	push YH
	push YL
	push r24
	push r25

	dec brightness			; decrement brightness every interrupt
							; brightness automatically wraps around to 255 
							; when it decrements from 0
	sts OCR5AL, brightness
	sts OCR5AH, brightness
	//out PORTC, brightness

EndIf:
	pop r25
	pop r24
	pop YL
	pop YH
	pop temp
	out SREG, temp
	reti


RESET:
	ldi brightness, 255

	//These two lines are for testing purposes
	;ser temp
	;out DDRC, temp

	//setting up direction pin L
	ldi temp, 0b00001000
	sts DDRL, temp ; Bit 3 will function as OC5A.

	; Set the Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS50)
	sts TCCR5B, temp
	ldi temp, (1<< WGM50)|(1<<COM5A1)
	sts TCCR5A, temp

	in temp, EIMSK
	ori temp, (1<<INT2)			; enable INT2 in temp
	out EIMSK, temp				; write it back to EIMSK

	ldi temp, 0b00000100
	sts TCCR5B, temp
	ldi temp, 1<<TOIE5		; turns overflow interrupt bit on
	sts TIMSK5, temp

	sei

loop:

	rjmp loop
	
