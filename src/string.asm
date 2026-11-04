BYTE_LENGTH equ 4

;-------------------------------------------;
; Input:                                    ;
;   HL = address of null-terminated string  ;
;                                           ;
; Output:                                   ;
;   HL = parsed 16-bit integer              ;
;-------------------------------------------;

str_atoi:
    ld DE, 0

_loop:
    ld A, (HL)
    or A
    jr z, _done

    sub '0'
    ld B, A

    ; DE = DE * 10
    push HL
    ld H, D
    ld L, E

    add HL, HL       ; *2
    push HL
    add HL, HL       ; *4
    add HL, HL       ; *8
    pop DE
    add HL, DE       ; *10

    ld D, H
    ld E, L

    ; DE += digit
    ld A, E
    add A, B
    ld E, A
    jr nc, _next
    inc D

_next:
    pop HL
    inc HL
    jr _loop

_done:
    ex DE, HL
    ret

;-------------------------------------------;
; Input:                                    ;
;   L = 8-bit integer to convert to string  ;
;                                           ;
; Output:                                   ;
;   HL = address of null-terminated string  ;     
;-------------------------------------------;
str_itoa:
    ld B, L
    ld C, 0
    ld HL, byte_str
_hundreds:
    ld A, B
    cp 100
    jr c, _tens

    sub 100
    ld B, A
    inc C
    jr _hundreds

_tens:
    ld A, C
    or A
    jr z, _save_tens

    add A, '0'
    ld (HL), A
    inc HL

_save_tens:
    ld C, 0
_tens_loop:
    ld A, B
    cp 10
    jr c, _units

    sub 10
    ld B, A
    inc C
    jr _tens_loop

_units:
    ld A, C
    or A
    jr nz, _save_tens_digit

    ; Save units
    ld A, B
    add A, '0'
    ld (HL), A
    inc HL

    jr _done
_save_tens_digit:
    ld A, C
    add A, '0'
    ld (HL), A
    inc HL

    ld A, B
    add A, '0'
    ld (HL), A
    inc HL
_done:
    xor A
    ld (HL), A
    ld HL, byte_str
    ret

byte_str:
    defs BYTE_LENGTH, 0