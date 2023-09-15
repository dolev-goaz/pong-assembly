%include "asm/utils.asm"
%include "asm/graphics.asm"
%include "asm/graphics_utils.asm"
%include "asm/string_utils.asm"

PIXEL_PER_DIGIT equ 8

section .data
    ; Define the pixel data for numbers 0 to 9 (8x8 bitmap fonts)
    digit_0     db 0b00111100,
                db 0b01100110,
                db 0b11000011,
                db 0b11000011,
                db 0b11000011,
                db 0b11000011,
                db 0b01100110,
                db 0b00111100

    digit_1     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_2     db 0b01111110,
                db 0b01111110,
                db 0b00001110,
                db 0b00011110,
                db 0b01111110,
                db 0b01111000,
                db 0b01110000,
                db 0b01111110

    digit_3     db 0b01111110,
                db 0b01111110,
                db 0b00001110,
                db 0b01111110,
                db 0b01111110,
                db 0b00001110,
                db 0b01111110,
                db 0b01111110

    ; continue from here

    digit_4     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_5     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_6     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_7     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_8     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100

    digit_9     db 0b00011000,
                db 0b00111000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00011000,
                db 0b00111100
    
    msg db "Hello ", 0

section .bss
digit_test      resq 10 ; idk why i have to define this so the color won't overflow
digit_bitmap    resq 10

section .text

%macro InitializeDigit 1
    mov qword [digit_bitmap + %1 * WORD_SIZE], digit_%1
%endmacro

; =====
InitializeBitmaps:
    InitializeDigit 0
    InitializeDigit 1
    InitializeDigit 2
    InitializeDigit 3
    InitializeDigit 4
    InitializeDigit 5
    InitializeDigit 6
    InitializeDigit 7
    InitializeDigit 8
    InitializeDigit 9
    ret
; =====

%macro DrawDigit 4
    push %1
    push %2
    push %3
    push %4
    call GDrawDigit
    CLEAR_STACK_PARAMS 4
%endmacro

GDrawDigit:
    GET_STACK_PARAM rdi, 4 ; digit to draw

    ; TODO: get bitmap by index
    ; TODO: bitmaps are flipped horizontally

    ; mov rax, WORD_SIZE
    ; mul rdi ; now rax contains the offset for the current digit bitmap

    ; ; get current digit bitmap
    ; mov rsi, digit_bitmap
    ; add rsi, rax ; rsi contains the address to the bitmap
    lea rsi, digit_0

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
    jc .color
    SetColor COLOR_BLACK
    jmp .draw_rectangle
.color:
    SetColor COLOR_WHITE ; this is the drawing color
.draw_rectangle:
    ; Rectangle(x + pixel_size * bit_counter, x + pixel_size * byte_counter, pixel_size, pixel_size)
    MY_PUSHA

    push rcx
    push rbx
    push r14
    push r15
    push rax
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



; startX, startY, currentIndexX, currentIndexY, pixelSize
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
string_utils