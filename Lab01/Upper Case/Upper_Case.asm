.include "m2560def.inc"
.equ size = 20
.def counter = r16

.dseg
.org 0x200

Length: .byte 20

.cseg

String: .db	"fwe1fma.zoold" ,0

start:
    ldi zh, high(String<<1)
    ldi zl, low(String<<1)
    ldi yh, high(Length)
    ldi yl, low(Length)
    clr counter

main:
    cpi counter, size
    brge end
    lpm r20, z+
	cpi r20, 0
	breq end
    cpi r20, 0x61
    brlt store
    cpi r20, 0x7B
    brge store

convert:
    subi r20, 32

store:
    st y+, r20

incCounter:
   inc counter
   rjmp main

end:
    rjmp end




