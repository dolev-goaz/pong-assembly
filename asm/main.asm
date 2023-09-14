%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/XK_keycodes.asm"
; --- constants

extern	clock, usleep

; === Time Constants

CLOCKS_PER_MS			equ 1000

; ==== Display Parameters
DISPLAY_WIDTH			equ 800
DISPLAY_HEIGHT			equ 600

DISPLAY_CENTER_X		equ DISPLAY_WIDTH / 2
DISPLAY_CENTER_Y		equ DISPLAY_HEIGHT / 2

PLAYER_STEP_SIZE		equ 10
PLAYER_WIDTH			equ 20
PLAYER_HEIGHT			equ 80
PLAYER_BORDER_OFFSET	equ 50

FRAME_RATE				equ 60
FRAME_TIME_MS			equ 1000 / FRAME_RATE
FRAME_TIME_NS			equ 1000 * FRAME_TIME_MS

; ==== Player 1(left player) Parameters

PLAYER_1_X				equ PLAYER_BORDER_OFFSET
PLAYER_1_KEY_GO_UP		equ XK_W
PLAYER_1_KEY_GO_DOWN	equ XK_S
PLAYER_1_STEP_SIZE		equ PLAYER_STEP_SIZE

; ==== Player 2(right player) Parameters

PLAYER_2_X				equ DISPLAY_WIDTH - PLAYER_BORDER_OFFSET - PLAYER_WIDTH
PLAYER_2_KEY_GO_UP		equ XK_Up
PLAYER_2_KEY_GO_DOWN	equ XK_Down
PLAYER_2_STEP_SIZE		equ PLAYER_STEP_SIZE

; ==== Ball Parameters

BALL_DIAMETER			equ 20
BALL_START_X			equ DISPLAY_CENTER_X - BALL_DIAMETER / 2
BALL_START_Y			equ DISPLAY_CENTER_Y - BALL_DIAMETER / 2
BALL_COLLIDE_ERR		equ 10

; --- statically allocated empty data
section .bss

temp 		resb 24 ; Weird color overflow when using frame_start

frame_start		resb 8
frame_end		resb 8

section .data
Player_1_Y		dq (DISPLAY_HEIGHT - PLAYER_HEIGHT) / 2
Player_1_Score	dq 0
Player_2_Y		dq (DISPLAY_HEIGHT - PLAYER_HEIGHT) / 2
Player_2_Score	dq 0

Ball_X			dq BALL_START_X
Ball_Y			dq BALL_START_Y
Ball_X_Speed	dq 3
Ball_Y_Speed	dq 2

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

; register, low end, high end, fallback label
%macro CheckInRange 4
	cmp %1, %2
	jl %4
	cmp %1, %3
	jg %4
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
	DrawBall [Ball_X], [Ball_Y], BALL_DIAMETER
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

;----------------------------------------------------------
; Handle Event
; -----------------
; Handles the game exit and player movement keyboard events
;----------------------------------------------------------
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

;-------------------------------------------------------
; Update Game Logic
; -----------------
; Applies game logic:
; 1.	player clamping
; 2.	ball movement/bounce
; 3.	scoring and resetting the ball
;-------------------------------------------------------
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
	mov qword rax, [Ball_Y_Speed]
	add [Ball_Y], rax

	mov qword rax, [Ball_X_Speed]
	add [Ball_X], rax

	; constrain ball in game bounds(y axis)

	mov qword rax, [Ball_Y]
	add rax, BALL_DIAMETER
	cmp rax, DISPLAY_HEIGHT
	jge .bounce_ball_y

	cmp qword [Ball_Y], 0
	jle .bounce_ball_y
	jmp .after_wall_bounce
.bounce_ball_y:
	mov qword rax, [Ball_Y_Speed]
	neg rax
	mov qword [Ball_Y_Speed], rax

.after_wall_bounce:

	; player 1 (left)
	push qword [Player_1_Y]
	call CheckBallWithinPlayerY
	CLEAR_STACK_PARAMS 1
	test rax, rax
	jz .player_2_bounce
	; === logic here

	mov rcx, PLAYER_1_X
	add rcx, PLAYER_WIDTH
	sub rcx, [Ball_X]
	CheckInRange rcx, 0, BALL_COLLIDE_ERR, .player_2_bounce
	; ball hit player
	mov qword rax, [Ball_X_Speed]
	test rax, rax
	jns .after_player_bounce ; only negate direction if wasn't already negated
	neg rax
	mov qword [Ball_X_Speed], rax

	jmp .after_player_bounce

.player_2_bounce:
	; player 2 (right)
	push qword [Player_2_Y]
	call CheckBallWithinPlayerY
	CLEAR_STACK_PARAMS 1
	test rax, rax
	jz .after_player_bounce
	; === logic here
	mov qword rcx, [Ball_X]
	add rcx, BALL_DIAMETER
	sub rcx, PLAYER_2_X
	CheckInRange rcx, 0, BALL_COLLIDE_ERR, .after_player_bounce
	; ball hit player
	mov qword rax, [Ball_X_Speed]
	test rax, rax
	js .after_player_bounce ; only negate direction if wasn't already negated
	neg rax
	mov qword [Ball_X_Speed], rax

.after_player_bounce:
	cmp qword [Ball_X], 0
	jle .player_2_score
	mov rax, [Ball_X]
	add rax, BALL_DIAMETER
	cmp rax, DISPLAY_WIDTH
	jge .player_1_score
	jmp .after_game_logic
.player_1_score:
	inc qword [Player_1_Score]
	jmp .reset_ball
.player_2_score:
	inc qword [Player_2_Score]
.reset_ball:
	mov qword [Ball_X], BALL_START_X
	mov qword [Ball_Y], BALL_START_Y
.after_game_logic:
	ret


;------------------------------------------------------------
; Check Ball Within Player Y
; --------------------------
; Checks if the ball is within a player's Y coordinates
; -----------------------------------------------------------
; Receives-	the player's y(STACK)
; Returns-	whether the ball is within the player's y (RAX)
;------------------------------------------------------------
CheckBallWithinPlayerY:
	GET_STACK_PARAM rdi, 1
	mov rax, 0 ; output- flag

	; check ball is above lower end
	; if (ball.y < (player.y + player.h))
	mov rcx, rdi
	add rcx, PLAYER_HEIGHT
	cmp qword [Ball_Y], rcx
	jge .finish_check_within

	; check ball is below higher end
	; if ((ball.y + ball.h) > player.y)
	mov rcx, [Ball_Y]
	add rcx, BALL_DIAMETER
	cmp rcx, rdi
	jle .finish_check_within
	mov rax, 1

.finish_check_within:
	ret

;------------------------------------------------------------
; Sleep
; -----
; Sleeps for a given amount of time
; -----------------------------------------------------------
; Receives-	the amount of time to sleep in NANOseconds(STACK)
;------------------------------------------------------------
Sleep:
	GET_STACK_PARAM rdi, 1
    call usleep
	ret

;-------------------------------------------------------
; Get Current Time
; ----------------
; Returns the current time
; ------------------------------------------------------
; Receives-	the address to store the current time(STACK)
; Returns- 	the current time(DATA)
;-------------------------------------------------------
GetCurrentTime:
	GET_STACK_PARAM rbx, 1
	call clock
	mov rcx, CLOCKS_PER_MS
	div rcx ; rax is now in ms
	mov [rbx], rax
    ret

;---------------------------------------------------
; Clamp player
; ------------
; Clamps a player's y position to be inside the
; display
; --------------------------------------------------
; Receives-	the player's y coordinate(STACK)
; Returns- 	the updated player's y coordinate(RAX)
;---------------------------------------------------
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