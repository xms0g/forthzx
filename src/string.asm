BYTE_LENGTH equ 6

;-------------------------------------------;
; Input:                                    ;
;   hl = address of null-terminated string  ;
;                                           ;
; Output:                                   ;
;   hl = parsed 16-bit integer              ;
;-------------------------------------------;

str_atoi:
    ld de, 0

_loop:
    ld a, (hl)
    or a
    jr z, _done

    sub '0'
    ld b, a

    ; de = de * 10
    push hl
    ld h, d
    ld l, e

    add hl, hl       ; *2
    push hl
    add hl, hl       ; *4
    add hl, hl       ; *8
    pop de
    add hl, de       ; *10

    ld d, h
    ld e, l

    ; de += digit
    ld a, e
    add a, b
    ld e, a
    jr nc, _next
    inc d

_next:
    pop hl
    inc hl
    jr _loop

_done:
    ex de, hl
    ret

;-------------------------------------------;
; Input:                                    ;
;   hl = 16-bit integer to convert to string;
;                                           ;
; Output:                                   ;
;   hl = address of null-terminated string  ;     
;-------------------------------------------;
str_itoa:
    push ix
    ld ix, 0
    ld de, byte_str

    bit 7, h
    jr z, _positive

    ld a, '-'
    ld (de), a
    inc de

    ; Negate HL (two's complement)
    xor a
    sub l
    ld l, a
    ld a, 0
    sbc a, h
    ld h, a

_positive:
   ; Process decimal positions
    ld bc, 10000
    call _digit

    ld bc, 1000
    call _digit

    ld bc, 100
    call _digit

    ld bc, 10
    call _digit

    ; Units
    ld a, l
    add a, '0'
    ld (de), a
    inc de

    PUT_NULL_TERM de

    ld hl, byte_str
    pop ix
    ret

;-------------------------------------------;
; HL = remaining value                      ; 
; BC = divisor                              ; 
; DE = output pointer                       ;
;-------------------------------------------;
_digit:
    ld a, '0'

_loop:
    or a
    sbc hl, bc
    jr c, _digit_done

    inc a
    jr _loop

_digit_done:
    add hl, bc

    cp '0'
    jr nz, _write_digit

    push af
    ld a, ixh
    or ixl
    jr z, _skip_zero
    pop af

_write_digit:
    ld (de), a
    inc de

    ld ix, 1
    ret
_skip_zero:
    pop af
    ret


byte_str:
    defs BYTE_LENGTH, 0