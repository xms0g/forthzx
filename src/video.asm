;---------------;
; PRINT_CHAR    ;
;   a=char      ;
;---------------;
PRINT_CHAR macro
    rst $10
endm
;---------------;
; print_str     ;
;   hl=str      ;
;---------------;
print_str:
_loop:
    ld a, (hl)
    or a
    jr z, _done
    PRINT_CHAR
    inc hl
    jr _loop
_done:
    ret