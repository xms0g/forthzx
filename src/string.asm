BYTE_LENGTH equ 4

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
;   l = 8-bit integer to convert to string  ;
;                                           ;
; Output:                                   ;
;   hl = address of null-terminated string  ;     
;-------------------------------------------;
str_itoa:
    ld b, l
    ld c, 0
    ld hl, byte_str
_hundreds:
    ld a, b
    cp 100
    jr c, _tens

    sub 100
    ld b, a
    inc c
    jr _hundreds

_tens:
    ld a, c
    or a
    jr z, _save_tens

    add a, '0'
    ld (hl), a
    inc hl

_save_tens:
    ld c, 0
_tens_loop:
    ld a, b
    cp 10
    jr c, _units

    sub 10
    ld b, a
    inc c
    jr _tens_loop

_units:
    ld a, c
    or a
    jr nz, _save_tens_digit

    ; Save units
    ld a, b
    add a, '0'
    ld (hl), a
    inc hl

    jr _done
_save_tens_digit:
    ld a, c
    add a, '0'
    ld (hl), a
    inc hl

    ld a, b
    add a, '0'
    ld (hl), a
    inc hl
_done:
    xor a
    ld (hl), a
    ld hl, byte_str
    ret

byte_str:
    defs BYTE_LENGTH, 0