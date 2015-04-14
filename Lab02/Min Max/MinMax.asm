.include "m2560def.inc"
.equ INTEGER_SIZE = 2 ; 2 bytes wide since it is 16 bits

.def nextAddressL = r16
.def nextAddressH = r17
.def currNumL = r18
.def currNumH = r19
.def lowNumL = r20
.def lowNumH = r21
.def count = r22 ; keeps track of how many items there are in list

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
<<<<<<< HEAD
defint 52, 3 ; 0x334 -> 820  
;defint 253, 0 ; 0xFD -> 253
;defint 73, 34 ; 0x2249 -> 8777
; decimals in defint are converted into hex
=======
defint 52, 3 ; 0x334 -> 820
;defint 253, 0 ; 0xFD -> 253
;defint 73, 34 ; 0x2249 -> 8777
>>>>>>> 77130af01d999866cbdb8c29a0fe348506fadac2

main:
	ldi zl, low(NEXT<<1)
	ldi zh, high(NEXT<<1)
	cpi zl, 0
	cpc zh, r0
	breq end

init:
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29
	out SPL, r28
	rcall findLargest
	cp lowNumL, yl
	cpc lowNumH, yh
	brge end
	movw yh:yl, lowNumH:lowNumL
	cpi count, 1
	brne end
	movw yh:yl, currNumH:currNumL

end:
	rjmp end

findLargest:
	lpm nextAddressL, z+
	lpm nextAddressH, z+
	inc count
	cpi nextAddressL, 0 ; if next address is 0 
	cpc nextAddressH, r0 ;then last item in linked list
	brne L3
	cpi yl, 0            ;handle last item
	cpc yh, r0
	breq isLowest
	rjmp L6
	rjmp epilogue

L3:
	lpm currNumL, z+
	lpm currNumH, z+
	rcall initLowest
	rcall isHighest
	movw zh:zl, nextAddressH:nextAddressL
	rcall init

loopforever:
	rjmp loopforever

initLowest:
	cpi lowNumL, 0
	cpc lowNumH, r0
	brne isLowest
	movw lowNumH:lowNumL,currNumH:currNumL
	ret

isLowest:
	cp currNumL, lowNumL
	cpc currNumH, lowNumH
	brge epilogue
	movw lowNumH:lowNumL, currNumH:currNumL
	ret

isHighest:
	cp currNumL, xl
	cpc currNumH, xh
	brlo epilogue
	movw xh:xl,currNumH:currNumL
	ret

L6:
	lpm currNumL, z+
	lpm currNumH, z+
	rcall isLowest
	rcall isHighest
	rjmp epilogue

epilogue:
	ret
