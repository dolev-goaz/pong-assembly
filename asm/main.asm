%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/XK_keycodes.asm"
; --- constants
DISPLAY_WIDTH	equ 500
DISPLAY_HEIGHT	equ 600

STEP_SIZE		equ 10

; --- statically allocated empty data
section .bss

section .data
PlayerY dq 50

window_title db "Pong",0

section .text
global main

main:
	push DISPLAY_WIDTH
	push DISPLAY_HEIGHT
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
	sub qword [PlayerY], STEP_SIZE

after_up:
	cmp rax, XK_Down
	jne after_down
	; key is down
	add qword [PlayerY], STEP_SIZE

after_down:

	; ---- end event handling
after_events:
	push 150 ; x
	; mov rax, [PlayerY]
	push qword [PlayerY] ; y
	push 200 ; width
	push 200 ; height
	call GDrawRectangle
	CLEAR_STACK_PARAMS 4
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods