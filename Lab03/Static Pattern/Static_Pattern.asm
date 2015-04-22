.include "m2560def.inc"

	ser r16
	out DDRC, r16

	ldi r16, 0xE5
	out PORTC, r16

end:
	rjmp end
