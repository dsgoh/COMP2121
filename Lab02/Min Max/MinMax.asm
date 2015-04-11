.include "m2560def.inc"
.equ INTEGER_SIZE = 2 ; 2 bytes wide since it is 16 bits

.def nextAddressL = r16
.def nextAddressH = r17
.def currNumL = r18
.def currNumH = r19

.set NEXT = 0x0000
.macro defint ; int
	.set T = PC
	.dw NEXT << 1
	.set NEXT = T
	
	.db @0, @1
.endmacro

.cseg
rjmp main
defint 5, 2 ; 0x205 -> 517
defint 61, 0 ; 0x3D -> 61
defint 52, 3 ; 0x334 -> 820
defint 253, 0 ; 0xFD -> 253
defint 73, 34 ; 0x2249 -> 8777

main:
	;ldi r28, low(RAMEND)
	;ldi r29, high(RAMEND)
	;out SPH, r29
	;out SPL, r28

	ldi zl, low(NEXT<<1)
	ldi zh, high(NEXT<<1)
	;lpm nextAddressL, z+
	;lpm nextAddressH, z+
	rcall findLargest

end:
	rjmp end

findLargest:
	;push r28
	;push r29
	;in r28, SPL
	;in r29, SPH
	lpm nextAddressL, z+
	lpm nextAddressH, z+
	cpi nextAddressL, 0 ; if next address is 0 
	cpc nextAddressH, r0 ;then last item in linked list
	brne L3
	cpi yl, 0
	cpc yh, r0
	breq isLowest
	rjmp L6
	rjmp epilogue

L3:
	lpm currNumL, z+
	lpm currNumH, z+
	rcall initLowest
	;cp currNumL, xl
	;cpc currNumH, xh
	;brlo L4
	rcall isHighest
	movw zh:zl, nextAddressH:nextAddressL
	rcall findLargest

loopforever:
	rjmp loopforever

initLowest:
	cpi yl, 0
	cpc yh, r0
	brne isLowest
	movw yh:yl,currNumH:currNumL
	ret

isLowest:
	cp currNumL, yl
	cpc currNumH, yh
	brge L5
	movw yh:yl, currNumH:currNumL
	ret

isHighest:
	cp currNumL, xl
	cpc currNumH, xh
	brlo L5
	movw xh:xl,currNumH:currNumL
	ret

L5:
	ret

L6:
	lpm currNumL, z+
	lpm currNumH, z+
	rcall isLowest
	;cp currNumL, xl
	;cpc currNumH, xh
	;brlo L4
	rcall isHighest
	rjmp epilogue

checkLargest:
	cpi xl, 0
	cpc xh, r0
	breq singleElement

singleElement:
	lpm xl, z
	lpm yl, z+
	lpm xh, z
	lpm yh, z+
	rjmp epilogue

epilogue:
	;pop r29
	;pop r28
	ret
