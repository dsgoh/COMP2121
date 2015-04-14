.include "m2560def.inc"

;Define your own macro called defint that defines a 
;linked list of signed 16-bit integers in program
;memory. Write a recursive function that takes the byte 
;address of the first list entry in the Z pointer,
;and calculates the largest and smallest integers in 
;the list. The largest integer should be returned in
;XH:XL, and the smallest in YH:YL.

.def next_low_address = r3
.def next_high_address = r2
.def smallest_low_byte = r20
.def smallest_high_byte = r19
.def largest_low_byte = r22
.def largest_high_byte = r21
.def useless_register = r18
.def current_number_low = r17
.def current_number_high = r16

.set NEXT_NUMBER = 0x0000
.macro defint ; str
	.set CURR = PC ; save current position in program memory
	.dw NEXT_NUMBER << 1 ; write out address of next list node
	.set NEXT_NUMBER = CURR ; update NEXT_STRING to point to this node
	.db high(@0), low(@0), 0, 0
.endmacro

.cseg
rjmp start

defint 123
defint 23
defint 12
defint -12
defint 244
defint 32767

start:
	clr smallest_low_byte
	clr smallest_high_byte
	clr largest_low_byte
	clr largest_high_byte
	ldi ZH, high(NEXT_NUMBER<<1)
	ldi ZL, low(NEXT_NUMBER<<1)
	rcall findLargestAndSmallest
	rjmp end

findLargestAndSmallest:
	; first two bytes store the address of next number (node)
	lpm next_low_address, Z+
	lpm next_high_address, Z+
	; now load in the actual 16-bit number
	lpm current_number_high, Z+
	lpm current_number_low, Z+

	; set largest and smallest number equal to current if current is first number
	cpi smallest_low_byte, low(0)
	ldi useless_register, high(0)
	cpc smallest_high_byte, useless_register
	breq setLargestAndSmallest ; should only happen in the first iteration of function call

	; if greater than or equal to 32768 (highest 16-bit number + 1) then it is negative
	cpi current_number_low, low(32767)
	ldi useless_register, high(32767)
	cpc current_number_high, useless_register
	brge currentIsNegative

	; else it is positive, then we first compare with highest
	cp current_number_low, largest_low_byte
	cpc current_number_high, largest_high_byte
	brge setLargest ; current number is larger than current largest

	cp current_number_low, smallest_low_byte
	cpc current_number_high, smallest_high_byte
	brlt setSmallest ; current number is smaller than current smallest

	; if it is neither greater than largest nor smaller than smallest go next iteration
	rjmp nextIteration

	currentIsNegative:
		; if number is negative it means when we compare the number the larger it is
		; the less negative the number is, i.e. -12 = 65524 = 65536 - 12
		; set smallest if smallest = positive OR smallest = negative && current < smallest
		; set largest if largest = negative && current > largest
		cpi largest_low_byte, low(32767)
		ldi useless_register, high(32767)
		cpc largest_low_byte, useless_register
		breq checkIfCurrentGreaterThanLargest
		; check smallest = positive or negative
		cpi smallest_low_byte, low(32767)
		cpc smallest_high_byte, useless_register ; smallest - 0
		brlt setSmallest; if it is less than then smallest is positive
		; otherwise smallest = negative
		rjmp checkIfCurrentLessThanSmallest
		
			checkIfCurrentGreaterThanLargest:
				cp current_number_low, largest_low_byte
				cpc current_number_high, largest_high_byte
				breq setLargest ; set largest as largest = negative && current > largest
				; if current < largest then just go next iteration
				rjmp nextIteration
		
			checkIfCurrentLessThanSmallest:
				cp current_number_low, smallest_low_byte
				cpc current_number_high, smallest_high_byte ; - current - (-smallest)
				brge setSmallest; if it is positive then current is smaller than smallest
				rjmp nextIteration
		; if current lowest is positive then we check highest..

	setLargestAndSmallest:
		mov smallest_low_byte, current_number_low
		mov smallest_high_byte, current_number_high
		mov largest_low_byte, current_number_low
		mov largest_high_byte, current_number_high
		rjmp nextIteration

	setLargest:
		mov largest_high_byte, current_number_high
		mov largest_low_byte, current_number_low
		rjmp nextIteration

	setSmallest:
		mov smallest_high_byte, current_number_high
		mov smallest_low_byte, current_number_low
		rjmp nextIteration

	nextIteration:
		; load in next number address into Z then call function
		mov ZL, next_low_address
		mov ZH, next_high_address
		; unless next_address is null then we reached end of linked list
		cpi ZL, low(0)
		ldi useless_register, high(0)
		cpc ZH, useless_register
		breq reachedEndOfList
		rcall findLargestAndSmallest

	reachedEndOfList:
		mov XH, largest_high_byte
		mov XL, largest_low_byte
		mov YH, smallest_high_byte
		mov YL, smallest_low_byte
		ret
	
end: 
	rjmp end
