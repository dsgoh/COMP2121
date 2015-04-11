.include "m2560def.inc"

.def counter = r19
.def counter2 = r21
.equ size = 7

.dseg
.org 0x200
memory: .byte 7

.cseg
array: .db 7,4,5,1,6,3,2

start:
    ldi zh, high(array)
    ldi zl, low(array)
    ldi yh, high(memory)
    ldi yl, low(memory)

load:
    cpi counter, size
    brge init
    lpm r20, z+
    st y+, r20
    inc counter
    rjmp load

init:
    ldi zh, high(memory)
    ldi zl, low(memory)
    ldi yh, high(memory)
    ldi yl, low(memory)
	ldi xh, high(memory)
    ldi xl, low(memory)
    ld r17, z+ ; increment z to point to index 1
    ldi counter, 1 ; counter begins at 1 because z begins at index 1
	clr counter2 ; this keeps track of our outer loop
    rjmp sort

sort:
    cpi counter2, size
	breq end
    cpi counter, size
    breq iterationEnd
    ld r16, y+
    ld r17, z+
    cp r16, r17
    brlo step
    st x+, r17
    st x, r16
	inc counter
    rjmp sort

step: ; this occurs when we have 2 numbers already sorted
    ld r16, x+ 
	inc counter
    rjmp sort

iterationEnd: ; when one iteration of the sort ends we will go in here
    ldi counter, 1
	inc counter2
    ldi zh, high(memory) ; initialising pointers again
    ldi zl, low(memory)
	ldi yh, high(memory)
    ldi yl, low(memory)
	ldi xh, high(memory)
	ldi xl, low(memory)
    ld r17, z+ ; make z point to index 1
	rjmp sort

end:
    rjmp end

    



