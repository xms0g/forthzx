; ---------------
; a=char        ;
; ---------------
print_char:
    rst $10
    ret
; ---------------
; hl=str        ;
; ---------------
print_str:
_loop:
    CHECK_NULL_TERM_ADDR hl
    jr z, _done
    call print_char
    inc hl
    jr _loop
_done:
    ret