	org $8000

INPUT_SIZE      equ 256
OPR_BUFFER_SIZE equ 7
CMD_PLUS        equ 1
CMD_MINUS       equ 2
CMD_MULT        equ 3
CMD_DIV         equ 4
CMD_DOT         equ 5
CMD_2DOT        equ 6
CMD_DUP         equ 7
CMD_DROP        equ 8
CMD_SWAP        equ 9
CMD_OVER        equ 10
CMD_ROT         equ 11
CMD_EMIT        equ 12
CMD_UNKNOWN     equ 13

PUT_NULL_TERM macro addr
    xor a
    ld (addr), a
endm

CHECK_NULL_TERM macro addr
    ld a, (addr)
    or a
endm

PUSH_OPERAND macro
    PUT_NULL_TERM bc

    ld bc, operand_buffer
    push bc
    pop hl
    call str_atoi
    push hl
endm

NEGATE16 macro regh, regl
    xor a
    sub regl
    ld regl, a
    ld a, 0
    sbc a, regh
    ld regh, a
endm
    
    jp start

    include "video.asm"
    include "string.asm"
    include "keyboard.asm"
    
start:
    ld hl, shell
    call print_str
_main_loop:
    call kb_poll
    or a
    jr z, _main_loop
    
    call kb_read
    cp KEY_ENTER
    jr z, _run_cmd
    
    or a
    call nz, forth_input
    jr _wait_release

_run_done:
    ld hl, shell
    call print_str

_wait_release:
    call kb_poll
    jr nz, _wait_release

    jr _main_loop

_run_cmd:
    ld de, (input_length)
    ld hl, input_buffer
    add hl, de
  
    PUT_NULL_TERM hl

    xor a
    ld (operand_sign), a
    ; passed chars count
    ld bc, 0
    ; compare input with command map
    ld de, cmd_map
_next_cmd:
    ld hl, input_buffer

_cmp_loop:
    ld a, (de)
    cp (hl)
    jr nz, _next

    or a
    jr z, _dispatch

    cp '-'
    jr nz, _continue

    ld a, 1
    ld (operand_sign), a

_continue:
    inc hl
    inc de
    inc bc
    
    jr _cmp_loop
_next:
    ; Skip the remaining characters of this command
    ld a, (de)
    inc de
    or a
    jr nz, _next

    inc de
    ; de now points to the next command
    ld a, (de)
    or a
    jr z, _unknown
_return_loop:
    ld a, b
    or c
    jr z, _cmp_loop
    ; move backward the input ptr till bc is zero
    dec hl
    dec bc
    ld a, b
    or c
    jr nz, _return_loop
    jr _cmp_loop
_unknown:
    ld bc, operand_buffer

    ld a, (operand_sign)
    cp 1
    jr nz, _digit_loop
    ld a, '-'
    ld (bc), a
    inc bc
    ; zeroed the operand sign
    xor a
    ld (operand_sign), a  
_digit_loop:
    ld a, (hl)
    ; check if the character is a digit
    cp '0' 
    ; if the result is negative, the character is less than '0'
    jp m, _cmd_unknown
    
    cp '9'
    ; if the result is positive, the character is greater than '9'
    jp p, _cmd_unknown
    ; save the digit
    ld (bc), a
    inc bc
    inc hl
    ; if it's null terminator, push it
    CHECK_NULL_TERM hl
    jr z, _handle_var
    jr _digit_loop

_handle_var:
    ; save the buffer ptr
    ld (input_buffer_ptr), hl
    
    PUSH_OPERAND

    ld hl, (input_buffer_ptr)
    ld de, cmd_map
    ld bc, 0
    inc hl
   
    CHECK_NULL_TERM hl
    jr nz, _cmp_loop
    jp _done

_dispatch:
    ld (input_buffer_ptr), hl

    inc de
    ld a, (de)

    cp CMD_PLUS
    jp z, _cmd_plus 

    cp CMD_MINUS
    jp z, _cmd_minus

    cp CMD_MULT
    jp z, _cmd_mult

    cp CMD_DIV
    jp z, _cmd_div

    cp CMD_DOT
    jp z, _cmd_dot

    cp CMD_DUP
    jp z, _cmd_dup

    cp CMD_DROP
    jp z, _cmd_drop

    cp CMD_SWAP
    jp z, _cmd_swap

    cp CMD_OVER
    jp z, _cmd_over

    cp CMD_ROT
    jp z, _cmd_rot

    cp CMD_EMIT
    jp z, _cmd_emit

_cmd_plus:
    pop bc
    pop hl
    add hl, bc
    push hl
    jp _done

_cmd_minus:
    pop bc
    pop hl
    and a
    sbc hl, bc
    push hl
    jp _done
; ----------------------;
; bc=multiplicand       ;
; de=multiplier         ;
;-----------------------;
_cmd_mult:
    pop bc
    pop de
    ld hl, 0  
      
    ld a, b
    or c
    jr z, _m_d
_m_l:
    add hl, de
    dec bc
    ld a, b
    or c
    jr nz, _m_l
_m_d:
    push hl
    jp _done
; ----------------------;
; bc=divisor            ;
; hl=dividend           ;
;-----------------------;
_cmd_div:
    pop bc
    pop hl

    ld a, b
    or c
    jr z, _zero_division
    
    xor a
    push af
    ; Check dividend sign
    bit 7, h
    jr z, _chk_divisor
    
    ; HL = -HL
    NEGATE16 h,l
    
    pop af
    ld a, 1
    push af
 _chk_divisor:   
    ; check divisor
    bit 7, b
    jr z, _divide
    
    ; BC = -BC
    NEGATE16 b,c

    pop af
    cp 1
    jr z, _make_positive

    ld a, 1
    push af
    jr _divide 

_make_positive:
    xor a
    push af
_divide:
    ld de, 0 
_d_l:
    or a
    sbc hl, bc
    jr c, _d_fin
    inc de
    jr _d_l
_d_fin:
    push de
    pop hl

    pop af
    or a
    jr z, _d_d

    ; Negate quotient
    NEGATE16 h,l
    jr _d_d
_zero_division:
    ld hl, zero_division
    call print_str
    ld hl, $ffff
_d_d:
    push hl
    jr _done

_cmd_dot:
    ld a, KEY_CR
    call print_char

    pop hl
    call str_itoa
    call print_str
    jr _done

_cmd_dup:
    pop bc
    ld h, b
    ld l, c

    push bc
    push hl
    jr _done

_cmd_drop:
    pop hl
    jr _done

_cmd_swap:
    pop bc
    pop hl

    push bc
    push hl
    jr _done

_cmd_over:
    pop bc
    pop hl

    ld d, h
    ld e, l

    push hl
    push bc
    push de
    jr _done

_cmd_rot:
    pop bc
    pop hl
    pop de

    push hl
    push bc
    push de
    jr _done

_cmd_emit:
    ld a, KEY_CR
    call print_char

    pop bc
    ld a, c
    call print_char
    jr _done

_cmd_unknown:
    ld a, KEY_CR
    call print_char
    ld hl, input_buffer
    call print_str
    ld a, ' '
    call print_char
    ld a, '?'
    call print_char
    ld de, (input_length)
    add hl, de
    ld (input_buffer_ptr), hl
_done:
    ld de, cmd_map
    ld bc, 0
    ld hl, (input_buffer_ptr)
    inc hl

    CHECK_NULL_TERM hl
    jp nz, _cmp_loop
    call clear_buffer
    jp _run_done

;------------------------
; a=char                ;
;------------------------
forth_input:
    ld b, a

    ; Check input_buffer capacity
    ld a, (input_length)
    cp INPUT_SIZE-1
    ret nc

    ; hl = input_buffer + input_length
    ld hl, input_buffer
    ld e, a
    ld d, 0
    add hl, de

    ; Store character
    ld a, b
    cp KEY_SPACE
    jr z, _replace
    ld (hl), b
    jr _done
_replace:
    ld (hl), 0
_done:
    ; Increment input length
    ld a, (input_length)
    inc a
    ld (input_length), a

    ; Print character
    ld a, b
    call print_char
    ret

clear_buffer:
    ld bc, input_length
    ld a, b         
    or c                    
    ret z                  

    ld hl, input_buffer
    ld (hl), 0
    dec bc
    ld a, b
    or c
    ret z
               
    ld de, input_buffer+1
    ldir     
    
    xor a                   
    ld (input_length), a 
    ret

cmd_map:
    defb "+", 0, CMD_PLUS
    defb "-", 0, CMD_MINUS
    defb "*", 0, CMD_MULT
    defb "/", 0, CMD_DIV
    defb ".", 0, CMD_DOT
    defb ":", 0, CMD_2DOT
    defb "DUP", 0, CMD_DUP
    defb "DROP", 0, CMD_DROP
    defb "SWAP", 0, CMD_SWAP
    defb "OVER", 0, CMD_OVER
    defb "ROT", 0, CMD_ROT
    defb "EMIT", 0, CMD_EMIT, 0
    defb CMD_UNKNOWN  

shell:
    defb KEY_CR, "FORTH>", 0

zero_division:
    defb KEY_CR, "infinity", 0

input_length:
    defb 0

input_buffer:
    defs INPUT_SIZE, 0

input_buffer_ptr:
    defw 0

operand_buffer:
    defs OPR_BUFFER_SIZE, 0

operand_sign:
    defb 0

end $8000
