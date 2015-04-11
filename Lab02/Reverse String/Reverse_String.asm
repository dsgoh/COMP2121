.include "m2560def.inc"
.dseg
.org 0x200
memory: .byte 30

.cseg
String: .db "abc",0

start:
   ldi r17, low(RAMEND)
   out spl, r17
   ldi r17, high(RAMEND)
   out sph, r17
   ldi zh, high(String<<1)
   ldi zl, low(String<<1)
   ldi yh, high(memory)
   ldi yl, low(memory)

pushZero:
   ldi r16, 0
   push r16

main:
   lpm r16, z+
   cpi r16, 0
   breq reverse
   push r16
   rjmp main

reverse:
   pop r16
   st y+, r16
   cpi r16, 0
   breq end
   rjmp reverse

end:
   rjmp end
