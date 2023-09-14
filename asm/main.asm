%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/XK_keycodes.asm"
; --- constants

extern	clock, usleep

; ==== Display Parameters
DISPLAY_WIDTH			equ 500
DISPLAY_HEIGHT			equ 600

DISPLAY_CENTER_X		equ DISPLAY_WIDTH / 2
DISPLAY_CENTER_Y		equ DISPLAY_HEIGHT / 2

PLAYER_STEP_SIZE		equ 10
PLAYER_WIDTH			equ 20
PLAYER_HEIGHT			equ 80
PLAYER_BORDER_OFFSET	equ 50

FRAME_RATE				equ 40
FRAME_TIME_MS			equ 1000 / FRAME_RATE
FRAME_TIME_NS			equ 1000 * FRAME_TIME_MS

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
BALL_STEP_SIZE			equ 3

; --- statically allocated empty data
section .bss

temp 		resb 24 ; Weird color overflow when using frame_start

frame_start		resb 8
frame_end		resb 8

section .data
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

	PUSH_ADDRESS frame_start
	call GetCurrentTime
	CLEAR_STACK_PARAMS 1


	call GCheckWindowEvent
	test rax, rax
	jz game_logic
	call GCheckExpose
	cmp rax, 0
	jne draw
	call HandleEvent

game_logic:
	call UpdateGameLogic
	
draw:
	ClearScreen
	DrawPlayer PLAYER_1_X, [Player_1_Y], PLAYER_WIDTH, PLAYER_HEIGHT
	DrawPlayer PLAYER_2_X, [Player_2_Y], PLAYER_WIDTH, PLAYER_HEIGHT
	DrawCircle [Ball_X], [Ball_Y], BALL_DIAMETER
time_sync:
; Time handling

	PUSH_ADDRESS frame_end
	call GetCurrentTime
	CLEAR_STACK_PARAMS 1


	; sleep if elapsed is less than frame_time
	; rax	= FRAME_TIME - ELAPSED = FRAME_TIME - (frame_end - frame_start)
	;		= FRAME_TIME + frame_start - frame_end
	mov rax, FRAME_TIME_NS
	add rax, [frame_start]
	sub rax, [frame_end]
	cmp rax, 0
	jle end_game_loop
	push rax
	call Sleep
	CLEAR_STACK_PARAMS 1

end_game_loop:
    jmp game_loop

; ------------------------- methods
HandleEvent:
	CALL_AND_ALLOCATE_STACK GCheckKeyPress
	cmp rax, 0 ; check if rax is not zero- a key was pressed
	jne .key_pressed
	ret	; no key was pressed

.key_pressed:
	cmp rax, XK_Escape
	je .exit_program
	; key isn't escape

	; ---- handle user input
	HandlePlayerInput 1
	HandlePlayerInput 2
	ret
.exit_program:
    call GCloseDisplay
    push 0
    call exit
	ret ; unreachable code
; =====

UpdateGameLogic:
	; clamp player positions
	push qword [Player_1_Y]
	call ClampPlayer
	CLEAR_STACK_PARAMS 1
	mov [Player_1_Y], rax

	push qword [Player_2_Y]
	call ClampPlayer
	CLEAR_STACK_PARAMS 1
	mov [Player_2_Y], rax

	; move ball

	add qword [Ball_X], BALL_STEP_SIZE

	ret

Sleep:
	GET_STACK_PARAM rdi, 1
    call usleep
	ret

GetCurrentTime:
	GET_STACK_PARAM rbx, 1
	call clock
	mov [rbx], rax
    ret


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