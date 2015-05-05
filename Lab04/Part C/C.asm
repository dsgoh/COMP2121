.include "m2560def.inc"

.def row = r16			; current row number
.def col = r17			; current column number
.def rmask = r18		; mask for current row during scan
.def cmask = r19		; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def currVal = r22		; value at the top of lcd
.def botVal = r23		; value at the bottom of lcd
.def symbol = r24		; 0 = no operation, 1 = Addition, 2 = Subtraction

.equ PORTADIR = 0xF0	; Setting PD7-4 to output and PD3-0 to input
.equ INITCOLMASK = 0xEF	; scan from the rightmost column
.equ INITROWMASK = 0x01	; scan from the top row
.equ ROWMASK = 0x0F		; for obtaining input from Port D

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
		
	clr r0

	jmp main
	
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
	andi temp1, ROWMASK		; Get the keypad output value
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
	breq letters			; they are letters

	cpi row, 3				; if the key is in row 3
	breq symbols			; they are symbols, so do nothing

	cpi row, 0				; these are the numbers 1-9
	ldi temp1, 0
	cpc col, temp1
	breq n1

	cpi row, 0
	ldi temp1, 1
	cpc col, temp1
	breq n2

	cpi row, 0
	ldi temp1, 2
	cpc col, temp1
	breq n3
	
	cpi row, 1
	ldi temp1, 0
	cpc col, temp1
	breq n4

	cpi row, 1
	ldi temp1, 1
	cpc col, temp1
	breq n5

	cpi row, 1
	ldi temp1, 2
	cpc col, temp1
	breq n6

	cpi row, 2
	ldi temp1, 0
	cpc col, temp1
	breq n7

	cpi row, 2
	ldi temp1, 1
	cpc col, temp1
	breq n8

	cpi row, 2
	ldi temp1, 2
	cpc col, temp1
	breq n9

	jmp convert_end

//for this program we only handle A and B
letters:
	cpi row, 0			; if we have an 'A'
	breq A
	cpi row, 1			; if we have a 'B'
	breq B
	jmp convert_end		; otherwise we have C or D, but we don't handle it

//for this program we only handle *
symbols:
	cpi col, 0			; if we have a star
	breq star
	cpi col, 1			; if we have a zero
	breq zero
	jmp convert_end		; otherwise we have a hash, let's make hash the decimal number

star:
	clr currVal
	//clear the top lcd screen
	jmp convert_end

zero:
	//add zero to the bottom value
	//display it on bottom accumulator
	jmp main

A:
	//since it is a, we want to add the new number
	//to the accumulator
	//move the number to the top accumulator

	//clear the number on bottom accumulator
	jmp convert_end

B:
	//move the number to the top accumulator

	//clear the number on bottom accumulator
	jmp convert_end

n1:
	//add the number 1 to the bottom value
	//display it on bottom accumulator

n2:

n3:

n4:

n5:

n6:

n7:

n8:

n9:

convert_end:
	jmp main
	
