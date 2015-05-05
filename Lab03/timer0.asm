Timer0OVF:               ; interrupt subroutine to Timer0
    in temp, SREG
    push temp            ; Prologue starts.
    push YH              ; Save all conflict registers in the prologue.
    push YL
    push r25
    push r24             ; Prologue ends.
                         ; Load the value of the temporary counter.
    lds r24, OneSecondCounter
    lds r25, OneSecondCounter+1
    adiw r25:r24, 1      ; Increase the one second counter by one.

    cpi r24, low(7812)   ; Check if (r25:r24) = 7812
    ldi temp, high(7812) ; 7812 = 10^6/128
    cpc r25, temp
    brne NotSecond

    ; timer execution
    ; -----------------------------

    ; check if 8 bits is collected
    cpi bitCounter, 8
    brne displayStart
    updatePattern:
        mov currPattern, newPattern
        clr bitCounter
        clr displayCounter

    ; check if have to display 3 times, or nothing
    displayStart:
    cpi displayCounter, 3
    breq clearDisplay
    cpi isDisplay, 0
    brne clearDisplay
    displayPattern:
        out PORTC, currPattern
        inc displayCounter
        inc isDisplay
        rjmp doneClearDisplay
    doneDisplayPatten:
    clearDisplay:
        ldi temp, 0b00000000
        out PORTC, temp
        clr isDisplay
    doneClearDisplay:

    clr debounceCounter

    ; ------------------------------
    ; timer execution end
    clear OneSecondCounter   ; Reset the one second counter.

    rjmp endNotSecond
    NotSecond:
        ; Store the new value of the temporary counter.
        sts OneSecondCounter, r24
        sts OneSecondCounter+1, r25
    endNotSecond:

    ; -------- check for 500 ms --------
    lds r24, milliSCounter
    lds r25, milliSCounter+1
    adiw r25:r24, 1      ; Increase the one second counter by one.

    cpi r24, low(3906)   ; Check if (r25:r24) = 3901
    ldi temp, high(3906) ; 3906.25 = 5*10^5/128
    cpc r25, temp
    brne NotMilliSecond

    ; ----------- start reset debounce counter ------------
    ; reset debounce counter to 0
    clr debounceCounter
    ; ------- done 10 ms reset for debounce counter -------

    clear milliSCounter  ; Reset the 10 ms counter
    rjmp EndIf
    NotMilliSecond:
        ; Store the new value of the temporary counter.
        sts milliSCounter, r24
        sts milliSCounter+1, r25

    EndIF:
        pop r24          ; Epilogue starts;
        pop r25          ; Restore all conflict registers from the stack.
        pop YL
        pop YH
        pop temp
        out SREG, temp
        reti             ; Return from the interrupt.