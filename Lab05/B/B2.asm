.include "m2560def.inc"

.dseg
.org 0x200

;==============
; SETUP
;==============

.cseg 
rjmp RESET

.org OVF3addr
	jmp Timer3OVF

.def temp = r16
.def brightness = r17

;================
; TIMER
;================

Timer3OVF:
	in temp, SREG
	push temp
	push YH
	push YL
	push r24
	push r25

	dec brightness			; decrement brightness every interrupt
							; brightness automatically wraps around to 255 
							; when it decrements from 0
	sts OCR3BL, brightness
	sts OCR3BH, brightness
	//out PORTE, brightness

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
;	ser temp
	ldi temp, 0b00010000
	out DDRE, temp ; Bit 3 will function as OC5A.
;	out PORTE, temp


	; Set the Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS30)
	sts TCCR3B, temp
	ldi temp, (1<< WGM30)|(1<<COM3B1)
	sts TCCR3A, temp

	in temp, EIMSK
	ori temp, (1<<INT2)			; enable INT2 in temp
	out EIMSK, temp				; write it back to EIMSK

	ldi temp, 0b00000100
	sts TCCR3B, temp
	ldi temp, 1<<TOIE3		; turns overflow interrupt bit on
	sts TIMSK3, temp

	sei

loop:

	rjmp loop
	
