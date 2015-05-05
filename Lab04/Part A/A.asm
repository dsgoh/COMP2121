; This program gets input from keypad and displays its numeric 
; value in binary, with lsb at the bottom
; Only handles 0-9
.include "m2560def.inc"

.def row = r16			; current row number
.def col = r17			; current column number
.def rmask = r18		; mask for current row during scan
.def cmask = r19		; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def isPressed = r22

.equ PORTADIR = 0xF0	; Setting PD7-4 to output and PD3-0 to input
.equ INITCOLMASK = 0xEF	; scan from the rightmost column
.equ INITROWMASK = 0x01	; scan from the top row
.equ ROWMASK = 0x0F		; for obtaining input from Port D

/*.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr temp1
	st Y+, temp1
	st Y, temp1
.endmacro

.dseg 
MilliCounter: .byte 2

.cseg
	jmp RESET

.org OVF0addr
	jmp Timer0OVF*/

RESET:
	ldi temp1, low(RAMEND)
	out SPL, temp1
	ldi temp1, high(RAMEND)
	out SPH, temp1

	ldi temp1, PORTADIR		; load PORTADIR into temp1
	sts DDRL, temp1			; setting up direction pin A
	ser temp1				; sets temp1 to 1
	out DDRC, temp1			; PORTC is output
	out PORTC, temp1
	
	clr isPressed
	clr r0

/*	ldi temp1, 0b00000010
	out TCCR0B, temp1
	ldi temp1, 1<<TOIE0
	sts TIMSK0, temp1

	sei*/

	jmp main

/*Timer0OVF:
	push temp1
	push YH
	push YL
	push r25
	push r24
	
	lds r24, MilliCounter
	lds r25, MilliCounter+1
	adiw r25:r24, 1

	cpi r24, low(781)
	ldi temp1, high(781)
	cpc r25, temp1
	brne NotMilli
	clr isPressed
	clear MilliCounter
	jmp EndIF

NotMilli:
	sts MilliCounter, r24
	sts MilliCounter+1, r25

EndIF:
	pop r24
	pop r25
	pop YL
	pop YH
	pop temp1
	reti*/
	
main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column

colloop:
	cpi col, 4		
	breq main				; if all keys are scanned, repeat
	sts PORTL, cmask		; otherwise scan a column

	ldi temp1, 0xFF			; for slowing down the scan operation

delay: 
	dec temp1
	brne delay

	lds temp1, PINL			; read PORTA
	;cpi isPressed ,0
	;brne main

handleKey:
	andi temp1, ROWMASK		; Get the keypad output value
	//ser isPressed
	cpi temp1, 0xF			; check if any row is low
	breq nextcol			

	ldi rmask, INITROWMASK	; initialise for row check
	clr row

rowloop:
	cpi row, 4
	breq nextcol			; the row scan is over
	mov temp2, temp1
	and temp2, rmask		; check un-masked bit
	breq convert			; if bit is clear, the key is pressed
	inc row					; else move to the next row
	lsl rmask
	jmp rowloop

nextcol:
	lsl cmask
	inc col
	jmp colloop

convert:
	cpi col, 3				; if key is in column 3
	breq doNothing			; they are letters so do nothing

	cpi row, 3				; if the key is in row 3
	breq doNothing			; they are symbols, so do nothing

	mov temp1, row			; these are the numbers 1-9
	lsl temp1
	add temp1, row
	add temp1, col
	subi temp1, -'1'
	jmp convert_end

doNothing:
	out PORTC, r0
	jmp main

convert_end:
	andi temp1, 0b00001111	; this clears the first four bits, and keeps the setted last 4 bits
	out PORTC, temp1
	jmp main
	
