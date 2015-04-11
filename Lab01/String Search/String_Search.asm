.include "m2560def.inc"

.def counter = r18 

.dseg
.org 0x200

.cseg

String: .db "hello",0

ldi zh, high(String)
ldi zl, low(String)
clr counter

loop:
    lpm r17, z+
    cpi r17, 0
	breq fail
    cpi r17,0x68 ; change 2nd argument for character to search
    breq store
    inc counter
    rjmp loop

store:
    mov r16, counter
    rjmp end

fail:
    ldi r16, 0xFF
    rjmp end

end:
    rjmp end
