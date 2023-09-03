%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/XK_keycodes.asm"
; --- constants

DISPLAY_WIDTH		equ 500
DISPLAY_HEIGHT		equ 600

PLAYER_STEP_SIZE	equ 10
PLAYER_WIDTH		equ 20
PLAYER_HEIGHT		equ 80
PLAYER_X			equ 50

; --- statically allocated empty data
section .bss

section .data
PlayerY dq 50

window_title db "Pong", 0

section .text
global main

main:
	push DISPLAY_WIDTH + 1
	push DISPLAY_HEIGHT + 1
	call GInitializeDisplay
	CLEAR_STACK_PARAMS 2

	PUSH_ADDRESS window_title
	call GSetTitle
	CLEAR_STACK_PARAMS 1

	;Infinite Game loop
game_loop:

	call GCheckKeyPress
	test rax, rax ; check if rax is not zero- a key was pressed
	jz after_events

key_pressed:
	cmp rax, XK_Escape
	jne after_esc
	; key is esc
	jmp exit_program

after_esc:
	cmp rax, XK_Up
	jne after_up
	; key is up
	sub qword [PlayerY], PLAYER_STEP_SIZE

after_up:
	cmp rax, XK_Down
	jne after_down
	; key is down
	add qword [PlayerY], PLAYER_STEP_SIZE

after_down:

	; ---- end event handling
after_events:
	DrawPlayer PLAYER_X, [PlayerY], PLAYER_WIDTH, PLAYER_HEIGHT
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods