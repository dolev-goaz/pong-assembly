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

%macro CALL_AND_ALLOCATE_STACK 1
    CALL_AND_ALLOCATE_STACK_COUNT %1, 1
%endmacro

%macro CALL_AND_ALLOCATE_STACK_COUNT 2
	sub rsp, WORD_SIZE * %2
	call %1
	add rsp, WORD_SIZE * %2
%endmacro

%macro MOV_DATA 2
    mov rbx, %2
    mov %1, rbx
%endmacro

%macro CMP_DATA 2
    mov rbx, %1
    cmp rbx, %2
%endmacro

; Macro to push all general-purpose registers onto the stack
%macro MY_PUSHA 0
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    push rax
%endmacro

; Macro to pop all general-purpose registers from the stack
%macro MY_POPA 0
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15
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