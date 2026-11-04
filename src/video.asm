; ---------------
; A = char      ;
; ---------------
print_char:
    rst $10
    ret
; ---------------
; HL=str      ;
; ---------------
print_str:
_loop:
    ld A, (HL)
    cp 0
    jr z, _done
    call print_char
    inc HL
    jr _loop
_done:
    ret