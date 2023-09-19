%ifndef BITMAPS_INCLUDED
%define BITMAPS_INCLUDED

%include "asm/utils.asm"
; %include "asm/x11lib_wrapper.asm"
%include "asm/graphics_utils.inc"

PIXEL_PER_DIGIT equ 8

section .data
    digit_0 db 0b00111100,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b01100110,
			db 0b00111100,
			db 0b00000000,


	digit_1 db 0b00001000,
            db 0b00011000,
            db 0b00111000,
            db 0b00011000,
            db 0b00011000,
            db 0b00011000,
            db 0b00111100,
            db 0b00000000,

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

    GET_STACK_PARAM rax, 3	; rax contains bitmap x
    GET_STACK_PARAM rbx, 2	; rbx contains bitmap y
    GET_STACK_PARAM rcx, 1	; rcx contains bitmap size

    push rsi					; bitmap address
    push rax					; bitmap x
    push rbx					; bitmap y

    push qword PIXEL_PER_DIGIT  ; bitmap height(constant for numbers)
    push qword PIXEL_PER_DIGIT  ; bitmap width(constant for numbers)

    ; pixel_size = draw_size/pixel_count = rcx / PIXEL_PER_DIGIT
    mov rbx, PIXEL_PER_DIGIT
    mov rax, rcx
    xor rdx, rdx                ; clear before div
    div rbx						; rax holds pixel size
    push rax					; pixel size

    call GDrawBitmap
    CLEAR_STACK_PARAMS 6

    ret

;----------------------------------------------------------------------
; Draw Bitmap
; -----------
; Draws a bitmap
;----------------------------------------------------------------------
; Assumes-	each row is split to bytes, each bit representing a pixel
;----------------------------------------------------------------------
; Receives- bitmapAddress, bitmapX, bitmapY, pxH, pxW, pixelSize(STACK)
;----------------------------------------------------------------------
GDrawBitmap:
    GET_STACK_PARAM r8, 2	; r8 is bitmap width

    push r8
    push qword 8
    call RoundUpMultiple
    CLEAR_STACK_PARAMS 2
    ; rax contains bit count of each row
    shr rax, 3  ; rax = rax / 8, holds byte count per row

    GET_STACK_PARAM rsi, 6	; rsi is bitmap address

    ; get pixel size
    GET_STACK_PARAM rdi, 1	; rdi is pixel size

    ; get coordinates
    GET_STACK_PARAM rcx, 5	; rcx is x coordinate
    GET_STACK_PARAM rbx, 4	; rbx is y coordinate

    GET_STACK_PARAM r9, 3	; r9 is bitmap height


    ; draw rectangle for each pixel

    mov r11, 0 ; y index

.draw_loop:
    mov r15, 0  ; bits drawn(0-r8)
    mov r14, 0  ; bit counter(in current byte, 0-8)
    mov r13, 0   ; byte counter(0-rax)
.load_byte:
    mov rdx, rsi    ; current bitmap row address
    add rdx, r13    ; offset by bytes passed in the current row
    mov r12b, [rdx] ; current byte- bitmap address offset

.draw_byte_loop:

    shl r12b, 1
    jnc .after_draw_bit

    MY_PUSHA

    push rcx    ; start x
    push rbx    ; start y
    push r15    ; index x
    push r11    ; index y
    push rdi    ; size
    call GBitmapDrawPixel
    CLEAR_STACK_PARAMS 5

    MY_POPA
    ; draw here

.after_draw_bit:
    inc r15 ; next bit(total offset)
    cmp r15, r8 ; check if row is finished
    je .after_draw_row
    ; row didnt finish
    inc r14 ; next bit(byte offset)
    cmp r14, 8 ; check if byte is finished
    jl .draw_byte_loop
    ; byte finished
    mov r14, 0
    inc r13
    jmp .load_byte
.after_draw_row:
    add rsi, rax ; offset the bitmap address by the bytes we passed
    inc r11
    cmp r11, r9 ; check if we finished bitmap
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
    push qword %2
    push qword %3
    push qword %4
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
	push rax
	call GetDigitCount		; result is in rax
	CLEAR_STACK_PARAMS 1
	mov rcx, rax			; digit counter

    ; LOOP AT DIGITS:
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
    xor rdx, rdx            ; clear rdx before div
    div rbx                 ; rdx contains current digit
	mov r15, rax			; r15 contains remaining number

    GET_STACK_PARAM r13, 2  ; number/digit y position
    GET_STACK_PARAM r12, 1  ; digit size

	MY_PUSHA
    DrawDigit rdx, r14, r13, r12
	MY_POPA

    dec rcx
    test rcx, rcx
    jnz .draw_next_digit
    ; draw current digit((positionX + digitSize * (digit_count - digit_index), positionY))
    ret

;-------------------------------------------------------------
; Round Up Multiple
; -----------------
; Rounds the first argument up to the closest multiple above
; or equal of the second parameter
; ------------------------------------------------------------
; Receives- toRound, multiple(STACK)
; Returns- the rounded multiple(RAX)
;-------------------------------------------------------------
RoundUpMultiple:
    GET_STACK_PARAM rcx, 1  ; the multiple
    GET_STACK_PARAM rax, 2  ; the number to round
    mov rbx, rax            ; copy
    xor rdx, rdx            ; clear before div
    div rcx                 ; rax = rax/rcx, rdx=rax%rcx
    test rdx, rdx           ; is there any remainder?
    jz .no_remainder
    xor rdx, rdx
    mul rcx                 ; rax is the closest multiple below the input
    add rax, rcx            ; rax is rounded upwards
    jmp .exit
.no_remainder:
    mov rax, rbx
    jmp .exit

.exit:
    ret

%endif