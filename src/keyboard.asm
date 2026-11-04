KEY_ENTER       equ $0D
KEY_CAPS_SHIFT  equ $01
KEY_SYMBOL      equ $02
KEY_SPACE       equ $20

;-------------------------------------------;
; Output:                                   ;
;   A = 1 if a key is pressed, 0 otherwise  ;
;-------------------------------------------;
kb_poll:
    ld HL, kb_map
    ld D, 8
_loop:
    exx
    ld B, (HL)
    ld C, $FE
    in A, (C)
    and $1F
    cp $1F
    jr nz, _pressed
    
    inc HL
    inc HL
    inc HL
    inc HL
    inc HL

    dec D
    jr nz, _loop
    xor A
    ret
_pressed:
    ld A, 1
    ret

;-------------------------------------------;
; Output:                                   ;
;   A = key code of the pressed key         ;
;-------------------------------------------;
kb_read:
    ld HL, kb_map
    ld D, 8

_row_loop:
    ld B, (HL)
    inc HL

    ld C, $FE
    in A, (C)
    and $1F

    ld E, 5

_key_loop:
    srl A
    jr nc, _pressed

    inc HL
    dec E
    jr nz, _key_loop

    dec D
    jr nz, _row_loop
    ret

_pressed:
    ld A, (HL)
    ret
    
kb_map:
    defb $FE, KEY_CAPS_SHIFT, 'Z', 'X', 'C', 'V'
    defb $FD, 'A', 'S', 'D', 'F', 'G'
    defb $FB, 'Q', 'W', 'E', 'R', 'T'
    defb $F7, '1', '2', '3', '4', '5'
    defb $EF, '0', '9', '8', '7', '6'
    defb $DF, 'P', 'O', 'I', 'U', 'Y'
    defb $BF, KEY_ENTER, 'L', 'K', 'J', 'H'
    defb $7F, ' ', KEY_SYMBOL, 'M', 'N', 'B'
