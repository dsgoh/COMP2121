.include "m2560def.inc"
; whatever we want to return, it doesn't get pushed on the stack
	; comp string
	.def longest = r16
	.def counter = r17
	.def loadChar = r18
	; start of node
	.def startLow = r19
	.def startHigh = r20
	; store z while we iterate
	.def spareLow = r21
	.def spareHigh = r22

	.set NEXT_STRING = 0x0000

	.macro defstring ; str
		.set T = PC
		.dw NEXT_STRING << 1
		.set NEXT_STRING = T
		.if strlen(@0) & 1 ; odd length + null byte
			.db @0, 0
		.else ; even length + null byte, add padding byte 
			.db @0, 0, 0
		.endif
	.endmacro

;======================================
.cseg
	
	; lets not execute our macro data in program memory
	rjmp main

	; JUNK TO FILL PROGRAM MEMORY
	TESTJUNK:
		inc r16
		inc r16
		inc r16
		inc r16
		inc r16
		inc r16
		inc r16

	setString:
		defstring "macros"
		defstring "are"
		defstring "no. now i am the longest and will remain forever unopposed"
		defstring "fun"
		inc r16 ; this shouldnt affect anything.
		inc r16
		defstring "a"
		defstring "IM THE LONGEST NOW MUAHA"
	main:
		; setup
		; z is the only thing "passed into" compareNext function
		ldi zh, high(NEXT_STRING<<1)
		ldi zl, low(NEXT_STRING<<1)

		; then call recursive compare next	
		rcall compareNext
	
	end:
		rjmp end


;======================================
compareNext:
	;======================================	0 start
	prologue:
		; push things we work with
		push counter
		push loadChar

		push startLow
		push startHigh

		push spareLow
		push spareHigh
		

	;======================================	0.5: housekeeping

	; before recursion, z stores pointer of this layer's string
	mov startLow, zl
	mov startHigh, zh

	; we then GO down to our layer. (dereference z)
	lpm spareLow, z+
	lpm spareHigh, z
	mov zl, spareLow
	mov zh, spareHigh
	
	;====================================== 1: recursion for whole list

	; go deeper if zh, zl is NOT 0,0
	recursiveNextA:
		cpi zl, 0 
		brne goDeeper
	recursiveNextB:
		cpi zh, 0 
		brne goDeeper
	noRecursion:
		rjmp postRecursion

	goDeeper:
		rcall compareNext
		
	postRecursion: 
		;continue along

	;======================================	1.5: housekeeping

	; after recursion call, new Z has been PASSED UP
	; we have to store this
	mov spareLow, zl
	mov spareHigh, zh

	; remember the start for this layer
	mov zl, startLow
	mov zh, startHigh

	;======================================	2: count and compare

	clr counter
	
	; skip the pointer to next node
	adiw zl, 2

	countString:
		inc counter
		lpm loadChar, z+
		cpi loadChar, 0
		brne countString

	; if you dont want to include 0 byte in length..
	dec counter

	;======================================	3: updating z

	; counter has to be > longest to usurp
	compareLengths:
		cp longest, counter
		brge restoreOldZ

	restoreNewZ:
		mov zl, startLow
		mov zh, startHigh
		mov longest, counter
		rjmp endComparison	

	restoreOldZ:
		mov zl, spareLow
		mov zh, spareHigh
		rjmp endComparison

	endComparison:
		; do nothing
	;======================================	4: finish
	epilogue:
		; we got z done, clean up
		; POP things we workED with
		pop spareHigh
		pop spareLow

		pop startHigh
		pop startLow

		pop loadChar
		pop counter

		ret
		
;======================================
