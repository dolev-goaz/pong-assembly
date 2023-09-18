%ifndef GRAPHICS_UTILS_INCLUDED
%define GRAPHICS_UTILS_INCLUDED
%include "asm/x11lib_wrapper.asm"
%include "asm/utils.asm"

section .text

; color offsets
COLOR_BLACK				equ 0
COLOR_WHITE				equ 1
COLOR_YELLOW            equ 2
COLOR_RED               equ 3
COLOR_TEAL              equ 4


; Draw a circle
%macro DrawCircle 3
    push qword %1
    push qword %2
    push qword %3
    call GDrawCircle
	CLEAR_STACK_PARAMS 3
%endmacro
; Draw circle border
%macro DrawCircleBorder 3
    push qword %1
    push qword %2
    push qword %3
    call GDrawCircleBorder
	CLEAR_STACK_PARAMS 3
%endmacro

; Draw rectangle border
%macro DrawRectangleBorder 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawRectangleBorder
	CLEAR_STACK_PARAMS 4
%endmacro
; Draw rectangle
%macro DrawRectangleFill 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawRectangle
    CLEAR_STACK_PARAMS 4
%endmacro
%macro DrawLine 4
    push qword %1
    push qword %2
    push qword %3
    push qword %4
    call GDrawLine
	CLEAR_STACK_PARAMS 4
%endmacro
; Set Foreground Color
%macro SetColor 1
	push %1
	call GSetForegroundColor
	CLEAR_STACK_PARAMS 1
%endmacro

; Clear screen
%macro ClearScreen 0
    ; black screen
	SetColor COLOR_BLACK
	DrawRectangleFill 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT

    ; field seperator
    SetColor COLOR_WHITE
    DrawLine DISPLAY_CENTER_X, 0, DISPLAY_CENTER_X, DISPLAY_HEIGHT
%endmacro
; Draw player
%macro DrawPlayer 4
    SetColor COLOR_WHITE
    DrawRectangleBorder %1, %2, %3, %4
    SetColor COLOR_BLACK
    ; this rectangle is smaller to not override the border
    mov rbx, %2
    inc rbx
    DrawRectangleFill %1+1, rbx, %3-2, %4-2
%endmacro
%macro DrawBall 3
    SetColor COLOR_TEAL
    DrawCircle %1, %2, %3,
%endmacro
%endif