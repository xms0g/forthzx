	org $8000

INPUT_SIZE equ 256
CMD_PLUS    equ 1
CMD_MINUS   equ 2
CMD_MULT    equ 3
CMD_DIV     equ 4
CMD_DOT     equ 5
CMD_2DOT    equ 6
CMD_DUP     equ 7
CMD_UNKNOWN equ 8
    
    jp start

    include "video.asm"
    include "string.asm"
    include "keyboard.asm"
    
start:
    ld HL, shell
    call print_str
_loop:
    call kb_poll
    or A
    jr z, _loop
    
    call kb_read
    cp KEY_ENTER
    jr z, _parse_input
    
    call forth_input
    jr _wait_release

_parse_done:
    ld HL, shell
    call print_str

_wait_release:
    call kb_poll
    jr nz, _wait_release

    jr _loop

_parse_input:
    ld A, (input_length)
    ld E, A
    ld D, 0

    ld HL, buffer
    add HL, DE
    ; put null terminator
    ld (HL), 0 

    ; compare input with command map
    ld DE, cmd_map
_next_cmd:
    ld HL, buffer

_cmp_loop:
    ld A, (DE)
    cp (HL)
    jr nz, _next

    or A
    jr z, _dispatch

    inc HL
    inc DE
    
    ld A, (HL)
    cp KEY_SPACE
    ; TODO
    jr _cmp_loop
_next:
    ; Skip the remaining characters of this command
    ld A, (DE)
    inc DE
    or A
    jr nz, _next

    inc DE
    ; DE now points to the next command
    ld A, (DE)
    or A
    jr z, _unknown
    jr _next_cmd
_unknown:
    ld HL, buffer
    ; check if the first character is a digit
    ld A, (HL)
    cp 48 
    ; if the result is negative,he first character is less than '0'
    jp m, _cmd_unknown
    
    cp 57
    ; if the result is positive, the first character is greater than '9'
    jp p, _cmd_unknown
    call str_atoi
    push HL
    jr _done

_dispatch:
    inc DE
    ld A, (DE)

    cp CMD_PLUS
    jr z, _cmd_plus 

    cp CMD_DOT
    jr z, _cmd_dot

_cmd_plus:
    pop BC
    pop HL
    add HL, BC
    push HL
    jr _done
_cmd_dot:
    ld A, 13
    call print_char

    pop HL
    call str_itoa
    call print_str
    jr _done
_cmd_unknown:
    ld A, 13
    call print_char
    ld HL, buffer
    call print_str
    ld A, ' '
    call print_char
    ld A, '?'
    call print_char
    ld A, 13
    call print_char
_done:    
    call clear_buffer
    jp _parse_done

;------------------------
; A=char                ;
;------------------------
forth_input:
    ld B, A

    ; Check buffer capacity
    ld A, (input_length)
    cp INPUT_SIZE-1
    ret nc

    ; HL = input_buffer + input_length
    ld HL, buffer
    ld E, A
    ld D, 0
    add HL, DE

    ; Store character
    ld (HL), B

    ; Increment input length
    ld A, (input_length)
    inc A
    ld (input_length), A

    ; Print character
    ld A, B
    call print_char
    ret

clear_buffer:
    ld HL, input_length
    ld B, (HL)
    
    ld A, B              
    or A                    
    ret z                  

    ld HL, buffer          
_loop:
    ld (HL), 0             
    inc HL                 
    djnz _loop        
    
    xor A                   
    ld (input_length), A 
    ret

cmd_map:
    defb "+", 0, CMD_PLUS
    defb "-", 0, CMD_MINUS
    defb "*", 0, CMD_MULT
    defb "/", 0, CMD_DIV
    defb ".", 0, CMD_DOT
    defb ":", 0, CMD_2DOT
    defb "DUP", 0, CMD_DUP, 0
    defb CMD_UNKNOWN  

shell:
    defb 13,"FORTH>",0

input_length:
    defb 0

buffer:
    defs INPUT_SIZE, 0


end $8000
