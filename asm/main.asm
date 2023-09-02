%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/XK_keycodes.asm"
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
	test rax, rax ; check if rax is not zero- a key was pressed
	jz after_events

key_pressed:
	cmp rax, XK_Escape
	je exit_program


	; ---- end event handling
after_events:
	call GDrawRectangle
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods