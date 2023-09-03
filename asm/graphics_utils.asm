%ifndef GRAPHICS_UTILS_INCLUDED
%define GRAPHICS_UTILS_INCLUDED
%include "asm/graphics.asm"
%include "asm/utils.asm"

section .text
%macro DrawRectangleBorder 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawRectangleBorder
	CLEAR_STACK_PARAMS 4
%endmacro
%macro DrawRectangleFill 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawRectangle
	CLEAR_STACK_PARAMS 4
%endmacro
; assumes- y is a variable, others are literals
%macro DrawPlayer 4
    DrawRectangleBorder %1, %2, %3, %4

    ; this rectangle is smaller to not override the border
    mov rbx, %2
    inc rbx
    DrawRectangleFill %1+1, rbx, %3-2, %4-2
%endmacro
%endif