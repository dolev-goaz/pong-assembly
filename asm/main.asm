%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/XK_keycodes.asm"
; --- constants

DISPLAY_WIDTH			equ 500
DISPLAY_HEIGHT			equ 600

PLAYER_STEP_SIZE		equ 10
PLAYER_WIDTH			equ 20
PLAYER_HEIGHT			equ 80
PLAYER_BORDER_OFFSET	equ 50

; ==== Player 1 Parameters

PLAYER_1_X				equ PLAYER_BORDER_OFFSET
PLAYER_1_KEY_GO_UP		equ XK_W
PLAYER_1_KEY_GO_DOWN	equ XK_S
PLAYER_1_STEP_SIZE		equ PLAYER_STEP_SIZE

; ==== Player 2 Parameters

PLAYER_2_X				equ DISPLAY_WIDTH - PLAYER_BORDER_OFFSET - PLAYER_WIDTH
PLAYER_2_KEY_GO_UP		equ XK_Up
PLAYER_2_KEY_GO_DOWN	equ XK_Down
PLAYER_2_STEP_SIZE		equ PLAYER_STEP_SIZE

; --- statically allocated empty data
section .bss

section .data
Player_1_Y dq 50
Player_2_Y dq 50

window_title db "Pong", 0

section .text
%macro ClearScreen 0
	DrawRectangleFill 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT
%endmacro

%macro HandlePlayerInput 1
	; ok, so basically, %% is dark magic for nasm
    cmp rax, PLAYER_%1_KEY_GO_UP
    je %%handle_up_%1
    cmp rax, PLAYER_%1_KEY_GO_DOWN
    je %%handle_down_%1
    jmp %%exit_input_handler_%1

%%handle_up_%1:
    sub qword [Player_%1_Y], PLAYER_STEP_SIZE
    ClearScreen
    jmp %%exit_input_handler_%1

%%handle_down_%1:
    add qword [Player_%1_Y], PLAYER_STEP_SIZE
    ClearScreen
    jmp %%exit_input_handler_%1

%%exit_input_handler_%1:
%endmacro


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
	; ---- handle user input
	HandlePlayerInput 1
	HandlePlayerInput 2

	; ---- end event handling
after_events:
	DrawPlayer PLAYER_1_X, [Player_1_Y], PLAYER_WIDTH, PLAYER_HEIGHT
	DrawPlayer PLAYER_2_X, [Player_2_Y], PLAYER_WIDTH, PLAYER_HEIGHT
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods

ClampPlayer:
	cmp qword [Player_1_Y], 0
	jl .too_high

	mov rbx, [Player_1_Y]
	add rbx, PLAYER_HEIGHT
	cmp rbx, DISPLAY_HEIGHT
	jg .too_low
	jmp .exit_clamp
.too_low:
	mov qword [Player_1_Y], DISPLAY_HEIGHT - PLAYER_HEIGHT
	jmp .exit_clamp
.too_high:
	mov qword [Player_1_Y], 0
	jmp .exit_clamp
.exit_clamp:
	ret