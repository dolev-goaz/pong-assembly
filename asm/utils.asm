%ifndef UTILS_INCLUDED
%define UTILS_INCLUDED
BYTE_SIZE equ 1
WORD_SIZE equ 8 * BYTE_SIZE

section .text
%macro CLEAR_STACK_PARAMS 1
    add rsp, %1 * WORD_SIZE
%endmacro
%macro GET_STACK_PARAM 2
    mov %1, [rsp + %2 * WORD_SIZE]
%endmacro
%macro PUSH_ADDRESS 1
    lea rax, %1
    push rax
%endmacro

; ------------------------------------------------ METHODS --------------------------------------------
;-----------------------------------------
; EXIT
; ----------------------------------------
; Receives- status code (STACK)
;-----------------------------------------
exit:
    mov rax, 60
    GET_STACK_PARAM rdi, 1 ; status code
    syscall
%endif