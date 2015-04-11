.include "m2560def.inc"
.dseg
.org 0x200
Array3: .byte 5

.cseg 

.def Array1_1 = r16
.def Array1_2 = r17
.def Array1_3 = r18
.def Array1_4 = r19
.def Array1_5 = r20
.def Array2_1 = r21
.def Array2_2 = r22
.def Array2_3 = r23
.def Array2_4 = r24
.def Array2_5 = r25

ldi Array1_1, 1
ldi Array1_2, 2
ldi Array1_3, 3
ldi Array1_4, 4
ldi Array1_5, 5
ldi Array2_1, 5
ldi Array2_2, 4
ldi Array2_3, 3
ldi Array2_4, 2
ldi Array2_5, 1
ldi zh, high(Array3)
ldi zl, low(Array3)

main:
   add Array1_1, Array2_1
   add Array1_2, Array2_2
   add Array1_3, Array2_3
   add Array1_4, Array2_4
   add Array1_5, Array2_5

   st z+, Array1_1
   st z+, Array1_2
   st z+, Array1_3
   st z+, Array1_4
   st z+, Array1_5

   rjmp end

end:
   rjmp end

