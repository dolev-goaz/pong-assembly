%ifndef BITMAPS_INCLUDED
%define BITMAPS_INCLUDED

%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"

PIXEL_PER_DIGIT equ 8

section .data
    digit_0 db 0b00111100,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b00111100,
			db 0b00000000

	digit_1 db 0b00001000,
			db 0b00011000,
			db 0b00101000,
			db 0b00001000,
			db 0b00001000,
			db 0b00001000,
			db 0b01111100,
			db 0b00000000

	digit_2 db 0b00111100,
			db 0b01100110,
			db 0b00000010,
			db 0b00000100,
			db 0b00001000,
			db 0b00010000,
			db 0b01111110,
			db 0b00000000,

	digit_3 db 0b00111100,
			db 0b01100110,
			db 0b00000010,
			db 0b00011100,
			db 0b00000010,
			db 0b01100110,
			db 0b00111100,
			db 0b00000000,

	digit_4 db 0b00000010,
			db 0b00000110,
			db 0b00001010,
			db 0b00010010,
			db 0b00111110,
			db 0b00000010,
			db 0b00000010,
			db 0b00000000

	digit_5 db 0b01111110,
			db 0b01000000,
			db 0b01000000,
			db 0b01111100,
			db 0b00000010,
			db 0b01100110,
			db 0b00111100,
			db 0b00000000,

	digit_6 db 0b00111100,
			db 0b01100000,
			db 0b01000000,
			db 0b01111100,
			db 0b01100110,
			db 0b01000010,
			db 0b00111100,
			db 0b00000000

	digit_7 db 0b01111110,
			db 0b00000010,
			db 0b00000010,
			db 0b00000100,
			db 0b00001000,
			db 0b00010000,
			db 0b00100000,
			db 0b00000000

	digit_8 db 0b00111100,
			db 0b01100110,
			db 0b01000010,
			db 0b00111100,
			db 0b01100110,
			db 0b01000010,
			db 0b00111100,
			db 0b00000000

	digit_9 db 0b00111100,
			db 0b01100110,
			db 0b01000010,
			db 0b00111110,
			db 0b00000010,
			db 0b01100110,
			db 0b00111100,
			db 0b00000000

    
    digit_bitmap dq digit_0, digit_1, digit_2, digit_3, digit_4, digit_5, digit_6, digit_7, digit_8, digit_9 

section .bss
section .text

%macro DrawDigit 4
    SetColor COLOR_TEAL
    push %1
    push %2
    push %3
    push %4
    call GDrawDigit
    CLEAR_STACK_PARAMS 4
%endmacro


;-------------------------------------------------------------
; Draw Digit
; ----------
; Draws a digit on the screen
; ------------------------------------------------------------
; Receives- digit(0-9), positionX, positionY, drawSize(STACK)
;-------------------------------------------------------------
GDrawDigit:
    GET_STACK_PARAM rdi, 4 ; digit to draw
    mov rsi, [digit_bitmap + WORD_SIZE * rdi] ; rsi contains the address to the bitmap

    ; get pixel size
    GET_STACK_PARAM rax, 1 ; size(width and height)
    mov rcx, PIXEL_PER_DIGIT
    xor rdx, rdx
    div rcx                 ; now rax is pixel size

    ; get coordinates
    GET_STACK_PARAM rcx, 3 ; x coordinate
    GET_STACK_PARAM rbx, 2 ; y coordinate


    ; draw rectangle for each pixel

    mov r15, 0 ; byte counter (Y)

.draw_loop: ; loops over every byte

    mov r14, 0 ; bit counter (X)
    mov r13, [rsi] ; current byte
.inner_loop:
    shr r13, 1
    jnc .after_draw ; skip current pixel if no need to draw
.draw_rectangle:
    ; Rectangle(x + pixel_size * bit_counter, x + pixel_size * byte_counter, pixel_size, pixel_size)
    MY_PUSHA

    mov r10, PIXEL_PER_DIGIT - 1 ; indexes start at 0
    sub r10, r14 ; x indexes are inverted

    push rcx    ; start x
    push rbx    ; start y
    push r10    ; index x
    push r15    ; index y
    push rax    ; size
    call GBitmapDrawPixel
    CLEAR_STACK_PARAMS 5

    MY_POPA

.after_draw:
    inc r14 ; next x index
    cmp r14, PIXEL_PER_DIGIT
    jl .inner_loop

    inc rsi ; go to next byte
    inc r15 ; next y index
    cmp r15, PIXEL_PER_DIGIT
    jl .draw_loop
    
    ret



;-------------------------------------------------------------
; Bitmap Draw Pixel
; -----------------
; Draws a pixel of a bitmap
; ------------------------------------------------------------
; Receives- bitmapX, bitmapY, indexX, indexY, pixelSize(STACK)
;-------------------------------------------------------------
GBitmapDrawPixel:
    ; get the offset
    GET_STACK_PARAM rax, 1  ; pixel size
    GET_STACK_PARAM rcx, 3  ; x index
    mul rcx                 ; rax is now offset x

    GET_STACK_PARAM r10, 5  ; start X
    add r10, rax            ; r10 is rect X


    GET_STACK_PARAM rax, 1  ; pixel size
    GET_STACK_PARAM rcx, 2  ; y index
    mul rcx                 ; rax is not offset y

    GET_STACK_PARAM r11, 4  ; start Y
    add r11, rax            ; r11 is rect Y

    GET_STACK_PARAM rax, 1  ; pixel size

    DrawRectangleFill r10, r11, rax, rax

    ret

%macro DrawNumber 4
    push qword %1
    push %2
    push %3
    push %4
    call GDrawNumber
    CLEAR_STACK_PARAMS 4
%endmacro


;-------------------------------------------------------------
; Draw Number
; -----------
; Draws a number on the screen
; ------------------------------------------------------------
; Receives- number, positionX, positionY, digitSize(STACK)
;-------------------------------------------------------------
GDrawNumber:
    ; Get Digit count(digit_count)

    GET_STACK_PARAM rax, 4  ; number to draw
    test rax, rax
    jz .input_zero
    mov rbx, 10             ; base 10
	xor rcx, rcx			; digit counter
.count_next_digit:
	xor rdx, rdx			; clear rdx for div
    inc rcx
    div rbx

    test rax, rax
    jnz .count_next_digit
	jmp .prepare_draw
.input_zero:
	mov rcx, 1

    ; LOOP AT DIGITS:
.prepare_draw:
	GET_STACK_PARAM r15, 4	; number to draw
.draw_next_digit:
    ; Get digit position
    GET_STACK_PARAM rax, 1  ; digit size
    dec rcx					; offset should start at 0 instead of at 1
    mul rcx                 ; rax contains digit x offset
    inc rcx

    GET_STACK_PARAM r14, 3  ; number x position
    add r14, rax            ; digit x position


	mov rax, r15			; number to draw
    div rbx                 ; rdx contains current digit
	mov r15, rax			; r15 contains remaining number

    GET_STACK_PARAM r13, 2  ; number/digit y position
    GET_STACK_PARAM r12, 1  ; digit size

.debug_before_draw: ; CHECK: rdx, r15, r14, r13, rax, rdx
	MY_PUSHA
    DrawDigit rdx, r14, r13, r12
	MY_POPA
.debug_after_draw:
    dec rcx
    test rcx, rcx
    jnz .draw_next_digit
    ; draw current digit((positionX + digitSize * (digit_count - digit_index), positionY))
    ret
%endif