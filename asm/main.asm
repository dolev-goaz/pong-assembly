%include "asm/utils.asm"
%include "asm/string_utils.asm"
%include "asm/graphics.asm"

; section .bss
; xevent:	 resb 192

DISPLAY_WIDTH	equ 500
DISPLAY_HEIGHT	equ 500

section .text
global main

main:
	push DISPLAY_WIDTH
	push DISPLAY_HEIGHT
	call GInitializeDisplay
	CLEAR_STACK_PARAMS 2

	;Infinite Game loop
gameLoop:

	call GDrawRectangle

    jmp gameLoop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods