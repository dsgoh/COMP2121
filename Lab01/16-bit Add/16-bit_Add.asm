; 16 bit Add
; Adds two numbers, 40960 and 2730
; Places result in r21:r20

.def a_high = r17
.def a_low = r16
.def b_high = r19
.def b_low = r18
.def sum_high = r21
.def sum_low = r20

	ldi a_high, high(40960)
	ldi a_low, low(40960)
	ldi b_high, high(2730)
	ldi b_low, low(2730)
	clr sum_high
	clr sum_low

main:
	add a_low, b_low
	adc a_high, b_high
	mov sum_high, a_high
	mov sum_low, a_low
	rjmp end

end:
	rjmp end
