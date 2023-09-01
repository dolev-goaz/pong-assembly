%include "asm/utils.asm"
section .data
ExposureMask:	dq 32768
KeyPressMask:	dq 1

gc_foreground:	dq 4


section .bss
display: resb 8
screen: resb 4
r_win: resb 8
win: resb 8
gc_black:	resb 8
gc_color:	resb 8
colormap: resb 8

black: resb 4
white: resb 4

xgcvals_white: 	resb 128
xgcvals_black:	resb 128
xevent:		resb 192

section .text
global main

extern XOpenDisplay, XDefaultScreen, XDefaultRootWindow
extern XCreateSimpleWindow, XBlackPixel, XWhitePixel
extern XMapWindow, XSelectInput, XCreateGC, XDefaultColormap
extern XDrawRectangle, XFillRectangle, XCloseDisplay

main:
    ; Display* XOpenDisplay(NULL)
    mov rdi, 0               ; Display name (0 indicates default display)
    call XOpenDisplay
    mov [display], rax

    ; int XDefaultScreen(display)
	mov	rdi, [display]
	call XDefaultScreen
	mov	[screen], eax

    ; int XBlackPixel(display, screen)
	mov	rdi, [display]
	mov	rsi, [screen]
	call XBlackPixel
	mov	[black], eax

    ; int XWhitePixel(display, screen)
	mov	rdi, [display]
	mov	rsi, [screen]
	call XWhitePixel
	mov	[white], eax

    ; Window XDefaultRootWindow(display)
	mov	rdi, [display]
	call XDefaultRootWindow
	mov	[r_win], rax

    ; Window XCreateSimpleWindow(display, r_win, 0, 0, width: 500, height: 500, 0, black, black)
    mov	rdi, [display]
    mov	rsi, [r_win]
    mov	rdx, 0
    mov	rcx, 0
    mov	r8d, 500
    mov	r9d, 500
    mov	rax, 0
    push rax

    push rax
    push r9
    push r8
    push rax
    push rax
    call XCreateSimpleWindow
    mov	[win], rax
    CLEAR_STACK_PARAMS 7 ; Clear the stack after the function call

    ; ---------
	; GC XCreateGC(display, win, GCForeground, &values_white)
	mov	ecx, [white]
	mov	[xgcvals_white + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]
	mov	rcx, xgcvals_white
	call	XCreateGC
	mov	[gc_color], rax

	; GC XCreateGC(display, win, GCForeground, &values_black)
	mov	ecx, [black]
	mov	[xgcvals_black + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]

	mov	rcx, xgcvals_black
	call XCreateGC
	mov	[gc_black], rax

	; Colormap XDefaultColormap(display, screen)
	mov	rdi, [display]
	mov	esi, [screen]
	call XDefaultColormap
	mov	[colormap], rax

    ; ---------

    ; void XSelectInput(display, win, ExposureMask | KeyPressMask)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]
	call XSelectInput

    ; void XMapWindow(display, win)
	mov	rdi, [display]
	mov	rsi, [win]
	call XMapWindow

	; Infinite Game loop
gameLoop:
	; void XDrawRectangle(display, window, gc, x_pxl, y_pxl, tile_len, tile_len)
    mov rdi, [display]
    mov rsi, [win]
    mov rdx, [gc_black]
    mov rcx, 150
    mov r8, 150
    mov r9, 200
    push r9
    call XDrawRectangle
    pop r9

	; void XFillRectangle(display, window, gc, x_pxl, y_pxl, tile_len, tile_len)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_black]
	mov	rcx, 150
	mov	r8, 150
	mov	r9, 200
	push r9
	call XFillRectangle
	pop	r9

    jmp gameLoop

exit_program:
    mov	rdi, [display]
	call XCloseDisplay
    push 0
    call exit

; ------------------------- methods