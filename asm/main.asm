%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/XK_keycodes.asm"
; --- constants

; ==== Display Parameters
DISPLAY_WIDTH			equ 500
DISPLAY_HEIGHT			equ 600

DISPLAY_CENTER_X		equ DISPLAY_WIDTH / 2
DISPLAY_CENTER_Y		equ DISPLAY_HEIGHT / 2

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

; ==== Ball Parameters

BALL_DIAMETER			equ 20
BALL_START_X			equ DISPLAY_CENTER_X - BALL_DIAMETER / 2
BALL_START_Y			equ DISPLAY_CENTER_Y - BALL_DIAMETER / 2

; --- statically allocated empty data
section .bss

section .data
Player_1_Y_OLD dq 50
Player_2_Y_OLD dq 50
Player_1_Y dq 50
Player_2_Y dq 50

Ball_X dq BALL_START_X
Ball_Y dq BALL_START_Y

window_title db "Pong", 0

section .text

%macro HandlePlayerInput 1
	; ok, so basically, %% is dark magic for nasm
    cmp rax, PLAYER_%1_KEY_GO_UP
    je %%handle_up_%1
    cmp rax, PLAYER_%1_KEY_GO_DOWN
    je %%handle_down_%1
    jmp %%exit_input_handler_%1

%%handle_up_%1:
    sub qword [Player_%1_Y], PLAYER_STEP_SIZE
    jmp %%exit_input_handler_%1

%%handle_down_%1:
    add qword [Player_%1_Y], PLAYER_STEP_SIZE
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
	; clamp player positions
	push qword [Player_1_Y]
	call ClampPlayer
	CLEAR_STACK_PARAMS 1
	mov [Player_1_Y], rax

	push qword [Player_2_Y]
	call ClampPlayer
	CLEAR_STACK_PARAMS 1
	mov [Player_2_Y], rax
	; check should clear screen(hide player trail)
	call ShouldRedrawScreen
	test rax, rax
	jz draw
	ClearScreen
draw:
	DrawPlayer PLAYER_1_X, [Player_1_Y], PLAYER_WIDTH, PLAYER_HEIGHT
	DrawPlayer PLAYER_2_X, [Player_2_Y], PLAYER_WIDTH, PLAYER_HEIGHT
	DrawCircle [Ball_X], [Ball_Y], BALL_DIAMETER
end_game_loop:
	MOV_DATA [Player_1_Y_OLD], [Player_1_Y]
	MOV_DATA [Player_2_Y_OLD], [Player_2_Y]
    jmp game_loop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods

ClampPlayer:
	GET_STACK_PARAM rbx, 1
	cmp rbx, 0
	jl .too_high

	add rbx, PLAYER_HEIGHT
	cmp rbx, DISPLAY_HEIGHT
	jg .too_low
	GET_STACK_PARAM rax, 1 ; return the previous y
	jmp .exit_clamp
.too_low:
	mov rax, DISPLAY_HEIGHT - PLAYER_HEIGHT ; return the bottom of the screen
	jmp .exit_clamp
.too_high:
	mov rax, 0								; return the top of the screen
	jmp .exit_clamp
.exit_clamp:
	ret


ShouldRedrawScreen:
	xor rax, rax ; rax = 0
	CMP_DATA [Player_1_Y_OLD], [Player_1_Y]
	jne .should_redraw
	CMP_DATA [Player_2_Y_OLD], [Player_2_Y]
	jne .should_redraw
	jmp .exit_redraw_check

.should_redraw:
	mov rax, 1
	jmp .exit_redraw_check
.exit_redraw_check:
	ret