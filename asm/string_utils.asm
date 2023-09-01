%ifndef STRING_UTILS_INCLUDED
%define STRING_UTILS_INCLUDED
%include "asm/utils.asm"
section .text

; ------------------------------------------------ METHODS --------------------------------------------
;-----------------------------------------
; Write String By Length
; ----------------------------------------
; Receives- message,length (STACK)
;-----------------------------------------
write_string_length:
    mov rax, 1             ; write mode
    mov rdi, 1             ; standard output
    GET_STACK_PARAM rsi, 1 ; message pointer
    GET_STACK_PARAM rdx, 2 ; message length
    syscall
    ret

;-----------------------------------------
; Get Null-Terminated String Length
; ----------------------------------------
; Receives- message(STACK)
; Returns- length(RAX)
;-----------------------------------------
string_length:
    GET_STACK_PARAM rdi, 1
    xor rax, rax            ; rax = 0
.string_length_loop:
    cmp byte [rdi + rax], 0 ; Compare current character with null terminator
    je .string_length_done  ; If it's null terminator, we're done
    inc rax                 ; Increment the string length
    jmp .string_length_loop ; Repeat the loop
.string_length_done:
    ret

;-----------------------------------------
; Write String
; ----------------------------------------
; Receives- null terminated string(STACK)
;-----------------------------------------
write_string:
    GET_STACK_PARAM rdi, 1
    push rdi
    call string_length
    CLEAR_STACK_PARAMS 1

    push rax
    push rdi
    call write_string_length
    CLEAR_STACK_PARAMS 2
    ret
%endif