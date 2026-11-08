KEY_ENTER       equ $0D
KEY_CAPS_SHIFT  equ $01
KEY_SYMBOL      equ $02
KEY_SPACE       equ $20
KEY_CR          equ $0D

;-------------------------------------------;
; Output:                                   ;
;   a = 1 if a key is pressed, 0 otherwise  ;
;-------------------------------------------;
kb_poll:
    ; Detect SYMBOL SHIFT independently.
    ld bc, $7FFE
    in a, (c)
    bit 1, a
    jr nz, _scan

    ld a, 1
    ld (symbol_state), a
    jr _pressed

_scan:
    ld hl, kb_map
    ld d, 8
_loop:
    ld b, (hl)
    ld c, $FE
    in a, (c)
    and $1F
    cp $1F
    jr nz, _pressed
    
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl

    dec d
    jr nz, _loop
    xor a
    ret
_pressed:
    ld a, 1
    ret

;-------------------------------------------;
; Output:                                   ;
;   a = key code of the pressed key         ;
;-------------------------------------------;
kb_read:
    ld hl, kb_map
    ld d, 8

_row_loop:
    ld b, (hl)
    inc hl

    ld c, $FE
    in a, (c)
    and $1F

    ld e, 5
_key_loop:
    srl a
    jr nc, _pressed

    inc hl
    dec e
    jr nz, _key_loop

    dec d
    jr nz, _row_loop
    ret

_pressed:
    ld a, (hl)

    ; Ignore modifier keys.
    cp KEY_SYMBOL
    jr z, _skip

    cp KEY_CAPS_SHIFT
    jr z, _skip

    ; Save the normal key.
    ld b, a

    ; Check SYMBOL SHIFT state.
    ld a, (symbol_state)
    or a
    jr z, _normal

    ld a, b
    ; Translate the key.
    call kb_translate
    ld b, a
    ; Consume the modifier.
    xor a
    ld (symbol_state), a
    
    ld a, b
    ret

_normal:
    ld a, b
    ret

_skip:
    xor a
    ret

;--------------------------------------;
; kb_translate                         ;
;                                      ;
; Input:                               ;
;   a = normal character               ;
;                                      ;
; Output:                              ;
;   a = translated character           ;
;--------------------------------------;

kb_translate:
    ld d, a
    ld hl, symbol_map

_loop:
    ld a, (hl)
    or a
    jr z, _not_found

    cp d
    jr z, _found

    inc hl
    inc hl
    jr _loop

_found:
    inc hl
    ld a, (hl)
    ret

_not_found:
    ld a, d
    ret

symbol_state:
    defb 0

kb_map:
    defb $FE, KEY_CAPS_SHIFT, 'Z', 'X', 'C', 'V'
    defb $FD, 'A', 'S', 'D', 'F', 'G'
    defb $FB, 'Q', 'W', 'E', 'R', 'T'
    defb $F7, '1', '2', '3', '4', '5'
    defb $EF, '0', '9', '8', '7', '6'
    defb $DF, 'P', 'O', 'I', 'U', 'Y'
    defb $BF, KEY_ENTER, 'L', 'K', 'J', 'H'
    defb $7F, KEY_SPACE, KEY_SYMBOL, 'M', 'N', 'B'

symbol_map:
    defb '1', '!'
    defb '2', '@'
    defb '3', '#'
    defb '4', '$'
    defb '5', '%'
    defb '6', '&'
    defb '7', "'"
    defb '8', '('
    defb '9', ')'
    defb '0', '_'
    defb 'K', '+'
    defb 'J', '-'
    defb 'B', '*'
    defb 'V', '/'
    defb 'M', '.'
    defb 'N', ','
    defb 'Z', ':'
    defb 'O', ';'
    defb 'L', '='
    defb 'C', '?'
    defb 'R', '<'
    defb 'T', '>'
    defb 0