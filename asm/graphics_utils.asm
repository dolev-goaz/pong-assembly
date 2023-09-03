%ifndef GRAPHICS_UTILS_INCLUDED
%define GRAPHICS_UTILS_INCLUDED
%include "asm/graphics.asm"
%include "asm/utils.asm"

section .text
%macro DrawRectangle 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawRectangle
	CLEAR_STACK_PARAMS 4
%endmacro

%endif