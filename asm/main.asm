%include "asm/utils.asm"
%include "asm/string_utils.asm"
%include "asm/graphics.asm"
; --- constants
DISPLAY_WIDTH	equ 500
DISPLAY_HEIGHT	equ 500

; --- statically allocated empty data
section .bss

section .data


section .text
global main

main:
	push DISPLAY_WIDTH
	push DISPLAY_HEIGHT
	call GInitializeDisplay
	CLEAR_STACK_PARAMS 2

	;Infinite Game loop
game_loop:

	call GCheckKeyPress
	test rax, rax
	jz after_events

	jmp exit_program


	; ---- end event handling
after_events:
	call GDrawRectangle
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods