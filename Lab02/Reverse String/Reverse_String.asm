.include "m2560def.inc"
.dseg
.org 0x200
memory: .byte 30

.cseg
String: .db "aNgUsyU3/\/",0

start:
   ldi r17, low(RAMEND)
   out SPL, r17
   ldi r17, high(RAMEND)
   out SPH, r17
   ldi zh, high(String<<1)
   ldi zl, low(String<<1)
   ldi yh, high(memory)
   ldi yl, low(memory)

pushZero:
   ldi r16, 0 
   push r16       ; initially have to push a zero onto stack to act as terminating byte

main:
   lpm r16, z+
   cpi r16, 0     ; as long as z does not reach terminating byte in string
   breq reverse
   push r16       ; we push the contents of r16 onto the stack, this occurs stringLength times
   rjmp main

reverse:
   pop r16        ; this pop occurs stringLength+1 times, since it also pops off terminating byte
   st y+, r16
   cpi r16, 0
   breq end
   rjmp reverse

end:
   rjmp end
