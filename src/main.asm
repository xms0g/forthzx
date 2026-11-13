STACK_TOP           equ $7FE8
INPUT_SIZE          equ 256
STACK_DATA_COUNT    equ 128
OPR_BUFFER_SIZE     equ 7
CMD_PLUS            equ 1
CMD_MINUS           equ 2
CMD_MULT            equ 3
CMD_DIV             equ 4
CMD_DOT             equ 5
CMD_COLON           equ 6
CMD_EQ              equ 7
CMD_GREATER_THEN    equ 8
CMD_LESS_THEN       equ 9
CMD_NOT_EQ          equ 10
CMD_STORE_VAL       equ 11
CMD_GET_VAL         equ 12
CMD_SHOW_VAL        equ 13
CMD_ADD_VAL         equ 14
CMD_DUP             equ 15
CMD_DROP            equ 16
CMD_SWAP            equ 17
CMD_OVER            equ 18
CMD_ROT             equ 19
CMD_EMIT            equ 21
CMD_AND             equ 22
CMD_OR              equ 23
CMD_INVERT          equ 24
CMD_VAR             equ 25
CMD_SDOT            equ 26
CMD_UNKNOWN         equ 27

PUT_NULL_TERM macro addr
    xor a
    ld (addr), a
endm

CHECK_NULL_TERM macro addr
    ld a, (addr)
    or a
endm

NEGATE16 macro regh, regl
    xor a
    sub regl
    ld regl, a
    ld a, 0
    sbc a, regh
    ld regh, a
endm

    org $8000
    jp start

    include "video.asm"
    include "string.asm"
    include "keyboard.asm"
    
start:
    ld hl, banner
    call print_str
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
    call nz, save_input
    jr _wait_release

_run_done:
    ld hl, shell
    call print_str

_wait_release:
    call kb_poll
    jr nz, _wait_release

    jr _main_loop

_run_cmd:
    ld a, (input_length)
    ld e, a
    ld d, 0
    ld hl, input_buffer
    add hl, de
  
    PUT_NULL_TERM hl

    xor a
    ld (operand_sign), a
    ; passed chars count
    ld bc, 0
    ; compare input with command map
    ld de, cmd_map
    ld hl, input_buffer
;------------;
; Tokenizing ;
;------------;
_cmp_loop:
    ld a, (de)
    cp (hl)
    jr nz, _next

    or a
    jp z, _dispatch

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
_mb_loop:
    ; if we catch the negative sign, don't move backward
    ld a, (operand_sign)
    or a
    jr nz, _cmp_loop
    ; check bc, if it's zero, no moving forward.
    ld a, b
    or c
    jr z, _cmp_loop

    ; move backward the input ptr till bc is zero
    dec hl
    dec bc
    ld a, b
    or c
    jr nz, _mb_loop
    jr _cmp_loop
_unknown:
    ld bc, operand_buffer

    ld a, (operand_sign)
    or a
    jr z, _digit_loop

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
    jp m, _check_var
    
    cp '9'
    ; if the result is positive, the character is greater than '9'
    jp p, _check_var
    ; save the digit
    ld (bc), a
    inc bc
    inc hl
    ; if it's null terminator, push it
    CHECK_NULL_TERM hl
    jr z, _push_digit
    jr _digit_loop
;------------;
; Push Digit ;
;------------;
_push_digit:
    ; save the buffer ptr
    ld (input_buffer_ptr), hl
    
    PUT_NULL_TERM bc

    ld bc, operand_buffer
    push bc
    pop hl
    call str_atoi
    push hl

    jp _done
;----------------;
; Check Variable ;
;----------------;
_check_var:
    ld bc, var_dict
    ld de, 0
_var_loop:
    ld a, (bc)
    cp (hl)
    jr nz, _s_var_name

    or a
    jr z, _var_found

    inc hl
    inc bc
    inc de
    jr _var_loop
_s_var_name:
    ; Skip the entry name
    ld a, (bc)
    inc bc
    or a
    jr nz, _s_var_name

    ; Skip the entry addr
    inc bc
    inc bc
    ; Skip the entry value
    inc bc
    inc bc
    ld a, (bc)
    cp 0
    jp z, _cmd_unknown
_vmb_loop:
    ; check de, if it's zero, no moving forward.
    ld a, d
    or e
    jr z, _var_loop

    ; move backward the input ptr till bc is zero
    dec hl
    dec de
    ld a, d
    or e
    jr nz, _vmb_loop
    jr _var_loop
_var_found:
    ; save the buffer ptr
    ld (input_buffer_ptr), hl

    inc bc
    ; bc now points addr
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a

    push hl
    
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

    cp CMD_EQ
    jp z, _cmd_equal

    cp CMD_GREATER_THEN
    jp z, _cmd_greater_then

    cp CMD_LESS_THEN
    jp z, _cmd_less_then

    cp CMD_NOT_EQ
    jp z, _cmd_not_eq

    cp CMD_STORE_VAL
    jp z, _cmd_store_val

    cp CMD_GET_VAL
    jp z, _cmd_get_val

    cp CMD_SHOW_VAL
    jp z, _cmd_show_val

    cp CMD_ADD_VAL
    jp z, _cmd_add_val

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

    cp CMD_AND
    jp z, _cmd_and

    cp CMD_OR
    jp z, _cmd_or

    cp CMD_INVERT
    jp z, _cmd_invert

    cp CMD_VAR
    jp z, _cmd_var

    cp CMD_SDOT
    jp z, _cmd_s_dot
;---------------;
; plus          ;
;   bc=var1     ;
;   hl=var2     ;
;---------------;
_cmd_plus:
    pop bc
    pop hl
    add hl, bc
    push hl
    jp _done
;---------------;
; minus         ;
;   bc=var1     ;
;   hl=var2     ;
;---------------;
_cmd_minus:
    pop bc
    pop hl
    or a
    sbc hl, bc
    push hl
    jp _done
; ----------------------;
; mult                  ;
;   bc=multiplicand     ;
;   de=multiplier       ;
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
; div                   ;
;   bc=divisor          ;
;   hl=dividend         ;
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
    jp _done
;---------------;
; dot           ;
;   hl=var      ;
;---------------;
_cmd_dot:
    ld a, KEY_CR
    call print_char

    pop hl
    call str_itoa
    call print_str
    jp _done

;---------------;
; equal         ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_equal:
    pop de
    pop hl
    or a
    sbc hl, de
    jr z, _e
    ld hl, 0
    push hl
    jp _done
_e:
    ld hl, $ffff
    push hl
    jp _done

;---------------;
; gt            ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_greater_then:
    pop de
    pop hl
    or a
    sbc hl, de
    jr nz, _nz
    jr _gt_fin  
_nz:
    jr nc, _nc
    jr _gt_fin
_nc:
    ld hl, $ffff
    push hl
    jp _done
_gt_fin:
    ld hl, 0
    push hl
    jp _done

;---------------;
; lt            ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_less_then:
    pop de
    pop hl
    or a
    sbc hl, de
    jr c, _lt
    ld hl, 0
    push hl
    jp _done
_lt:
    ld hl, $ffff
    push hl
    jp _done

;---------------;
; Not Equal     ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_not_eq:
    pop de
    pop hl
    or a
    sbc hl, de
    jr nz, _ne
    ld hl, 0
    push hl
    jp _done
_ne:
    ld hl, $ffff
    push hl
    jp _done

;---------------;
; !             ;
;   hl=addr     ;
;   bc=val      ;
;---------------;
_cmd_store_val:
    pop hl
    pop bc
_csv_l:
    ld a, (hl)
    inc hl
    cp 0
    jr nz, _csv_l
    ; Skip the addr
    inc hl
    inc hl

    ld a, c
    ld (hl), a
    inc hl
    ld a, b
    ld (hl), a
    
    jp _done

;---------------;
; @             ;
;   hl=addr     ;
;---------------;
_cmd_get_val:
    pop hl
_cgv_l:
    ld a, (hl)
    inc hl
    cp 0
    jr nz, _cgv_l

    inc hl
    inc hl

    ld a, (hl)
    ld c, a
    inc hl
    ld a, (hl)
    ld b, a

    push bc

    jp _done

;---------------;
; ?             ;
;   bc=addr     ;
;---------------;
_cmd_show_val:
    ld a, KEY_CR
    call print_char

    pop bc
_cshv_l:
    ld a, (bc)
    inc bc
    cp 0
    jr nz, _cshv_l

    inc bc
    inc bc

    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a

    call str_itoa
    call print_str

    jp _done

;---------------;
; +!            ;
;   bc=addr     ;
;   de=val      ;
;---------------;
_cmd_add_val:
    pop bc
    pop de
_cav_l:
    ld a, (bc)
    inc bc
    cp 0
    jr nz, _cav_l
    ; Skip the addr
    inc bc
    inc bc

    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a

    add hl, de

    ld a, h
    ld (bc), a
    dec bc
    ld a, l
    ld (bc), a
    jp _done

;---------------;
; dup           ;
;   bc=var      ;
;---------------;
_cmd_dup:
    pop bc
    ld h, b
    ld l, c

    push bc
    push hl
    jp _done
;---------------;
; drop          ;
;   hl=var      ;
;---------------;
_cmd_drop:
    pop hl
    jp _done

;---------------;
; swap          ;
;   bc=var1     ;
;   hl=var2     ;
;---------------;
_cmd_swap:
    pop bc
    pop hl

    push bc
    push hl
    jp _done

;---------------;
; over          ;
;   bc=var1     ;
;   hl=var2     ;
;---------------;
_cmd_over:
    pop bc
    pop hl

    ld d, h
    ld e, l

    push hl
    push bc
    push de
    jp _done

;---------------;
; rot           ;
;   bc=var1     ;
;   hl=var2     ;
;   de=var3     ;
;---------------;
_cmd_rot:
    pop bc
    pop hl
    pop de

    push hl
    push bc
    push de
    jp _done

;---------------;
; emit          ;
;   bc=var      ;
;---------------;
_cmd_emit:
    ld a, KEY_CR
    call print_char

    pop bc
    ld a, c
    call print_char
    jp _done

;---------------;
; and           ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_and:
    pop de
    pop hl
    ld a, d
    and h
    ld h, a

    ld a, e
    and l
    ld l, a

    push hl
    jp _done

;---------------;
; or            ;
;   de=var1     ;
;   hl=var2     ;
;---------------;
_cmd_or:
    pop de
    pop hl
    ld a, d
    or h
    ld h, a

    ld a, e
    or l
    ld l, a
    
    push hl
    jp _done

;---------------;
; invert        ;
;   hl=var      ;
;---------------;
_cmd_invert:
    pop hl
    ld a, h
    cpl
    ld h, a

    ld a, l
    cpl
    ld l, a

    push hl
    jp _done

;---------------;
; variable      ;
;---------------;
_cmd_var:
    ld hl, var_dict
    ld de, (vd_offset)
   
    ; next cell 
    add hl, de

    ld a, h
    ld b, a
    ld a, l
    ld c, a
    ; bc now points current offset of var_dict
    ld (curr_vd_addr), bc
    ld hl, (input_buffer_ptr)
    inc hl
    ld de, 0
    ; Now hl points the variable name
_v_loop:
    ld a, (hl)
    ld (bc), a
    
    inc hl
    inc bc
    inc de
    
    ld a, (hl)
    cp 0
    jr nz, _v_loop

    PUT_NULL_TERM bc
    inc bc
    ; store the current dict address 
    ld hl, (curr_vd_addr)
    ld a, l
    ld (bc), a
    ld a, h
    inc bc
    ld (bc), a
  
    inc de
    inc de
    inc de
    inc de
    inc de
    
    ld hl, (vd_offset)
    add hl, de
    ld (vd_offset), hl
    
    jp _finish

;---------------;
; .S            ;
;   hl=var      ;
;---------------;
_cmd_s_dot:
    ld a, KEY_CR
    call print_char

    ld de, 0
    ld bc, stack_data_buffer
_stack_l:
    xor a
    ld hl, STACK_TOP
    or a
    sbc hl, sp
    jr z, _s_process_done
    
    pop hl
    ; store 16-bit value,first low then hight (little endian)
    ld a, l
    ld (bc), a
    inc bc
    ld a, h
    ld (bc), a
    inc bc

    inc de
    jr _stack_l
 _s_process_done:
    ld a, e
    cp 0
    jr z, _done

    dec bc
_s_print_l:
    ; print and push in the reverse order for stack correctness
    ld a, (bc)
    ld h, a

    ; clear
    PUT_NULL_TERM bc
    dec bc
    
    ld a, (bc)
    ld l, a
    ; clear 
    PUT_NULL_TERM bc
    dec bc

    push hl
    
    push bc
    push de
    call str_itoa
    call print_str
    ld a, ' '
    call print_char

    pop de
    pop bc

    dec de

    ld a, e
    or d
    jr nz, _s_print_l

    jp _done

;---------------;
; unknown       ;
;---------------;
_cmd_unknown:
    ld a, KEY_CR
    call print_char
    ld hl, input_buffer
    call print_str
    ld a, ' '
    call print_char
    ld a, '?'
    call print_char

    ld a, (input_length)
    ld e, a
    ld d, 0
    add hl, de
    ld (input_buffer_ptr), hl
_done:
    ; Find the length of the processed token
    ; HL = current offset
    ld hl, (input_buffer_ptr)
    ld de, input_buffer
    or a
    sbc hl, de         

    ld a, (input_length)
    ld e, a
    ld d, 0
    or a
    ; Compare it with input_length
    or a
    sbc hl, de
    jr nc, _finish     

    ; More tokens available
    ld hl, (input_buffer_ptr)
    inc hl
    ld de, cmd_map
    ld bc, 0
    jp _cmp_loop

_finish:
    call clear_buffer
    jp _run_done

;-----------------------;
; a=char                ;
;-----------------------;
save_input:
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
    ld a, (input_length)
    push af    
    
    xor a                   
    ld (input_length), a

    pop af
    or a                    
    ret z                  

    ld c, a
    ld b, 0

    ld hl, input_buffer
    ld (hl), 0
    dec c
    ld a, c
    or a
    ret z
               
    ld de, input_buffer+1
    ldir     
    ret

cmd_map:
    defb "+", 0, CMD_PLUS
    defb "-", 0, CMD_MINUS
    defb "*", 0, CMD_MULT
    defb "/", 0, CMD_DIV
    defb ".", 0, CMD_DOT
    defb ":", 0, CMD_COLON
    defb "=", 0, CMD_EQ
    defb ">", 0, CMD_GREATER_THEN
    defb "<", 0, CMD_LESS_THEN
    defb "<>", 0, CMD_NOT_EQ
    defb "!", 0, CMD_STORE_VAL
    defb "@", 0, CMD_GET_VAL
    defb "?", 0, CMD_SHOW_VAL
    defb "+!", 0, CMD_ADD_VAL
    defb "DUP", 0, CMD_DUP
    defb "DROP", 0, CMD_DROP
    defb "SWAP", 0, CMD_SWAP
    defb "OVER", 0, CMD_OVER
    defb "ROT", 0, CMD_ROT
    defb "EMIT", 0, CMD_EMIT
    defb "AND", 0, CMD_AND
    defb "OR", 0, CMD_OR
    defb "INVERT", 0, CMD_INVERT
    defb "VARIABLE", 0, CMD_VAR
    defb ".S", 0, CMD_SDOT, 0
    defb CMD_UNKNOWN  

banner:
    defb "FORTHZX v0.1", KEY_CR
    defb "COPYRIGHT 2026 M. SAMI GURPINAR", 0

shell:
    defb KEY_CR, ">", 0

zero_division:
    defb KEY_CR, "infinity", 0

input_length:
    defb 0

input_buffer:
    defs INPUT_SIZE, 0

stack_data_buffer:
    defw STACK_DATA_COUNT, 0

input_buffer_ptr:
    defw 0

operand_buffer:
    defs OPR_BUFFER_SIZE, 0

operand_sign:
    defb 0

vd_offset:
    defw 0

curr_vd_addr:
    defw 0

var_dict:
    defb 0

end $8000
