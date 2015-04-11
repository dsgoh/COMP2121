; This program performs
; 2-byte addition: a + b

.def a_low = r1;
.def a_high = r2;
.def b_low = r3;
.def b_high = r4;
.def sum_low = r5;
.def sum_high = r6;
.def i = r16

ldi i, 0x01
mov a_low, i
ldi i, 0x01
mov a_high, i ; 0x0101 is 257
ldi i, 0x02
mov b_low, i
ldi i, 0x01
mov b_high, i ; 0x0102 is 258

add a_low, b_low
adc a_high, b_high
mov sum_low, a_low
mov sum_high, a_high

; answer is 0x0203
