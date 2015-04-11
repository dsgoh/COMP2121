; 2 byte multiplication
; a*b

.def zero = r2
.def a_low = r16
.def a_high = r17
.def b_low = r18
.def b_high = r19
.def ans1 = r20
.def ans2 = r21
.def ans3 = r22
.def ans4 = r23

ldi a_low, LOW(42)
ldi a_high, HIGH(42)
ldi b_low, LOW(10)
ldi b_high, HIGH(10)

MUL16x16:
	clr zero
	mul a_low, b_low
    movw ans1:ans2, r1:r0
	mul a_high, b_high
	movw ans3:ans4, r1:r0

	mul a_low, b_high
	add ans2, r0
	adc ans3, r1
	adc ans4, zero

	mul b_low, a_high
	add ans2, r0
	adc ans3, r1
	adc ans4, zero
