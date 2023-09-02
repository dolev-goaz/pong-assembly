%ifndef GRAPHICS_INCLUDED
%define GRAPHICS_INCLUDED
%include "asm/utils.asm"
%include "asm/string_utils.asm"
section .data
ExposureMask:	dq 32768
KeyPressMask:	dq 1

gc_foreground:	dq 4

section .bss
display:		resb 8
screen: 		resb 4
r_win: 			resb 8
win: 			resb 8
gc_black:		resb 8
gc_color:		resb 8
colormap: 		resb 8

black: 			resb 4
white: 			resb 4

xgcvals_white: 	resb 128
xgcvals_black:	resb 128

section .text

extern XOpenDisplay, XDefaultScreen, XDefaultRootWindow
extern XCreateSimpleWindow, XBlackPixel, XWhitePixel
extern XMapWindow, XSelectInput, XCreateGC, XDefaultColormap
extern XDrawRectangle, XFillRectangle, XCloseDisplay

; ---------------------- METHODS -------------------
GInitializeDisplay:
	CALL_AND_ALLOCATE_STACK GOpenDisplay
	CALL_AND_ALLOCATE_STACK GDefaultScreen
	CALL_AND_ALLOCATE_STACK GPixels
	CALL_AND_ALLOCATE_STACK GRootWindow
	CALL_AND_ALLOCATE_STACK GCreateWindow
	CALL_AND_ALLOCATE_STACK GCreateGraphicsContext
	CALL_AND_ALLOCATE_STACK GDefaultColorMap
	CALL_AND_ALLOCATE_STACK GSelectInput
	CALL_AND_ALLOCATE_STACK GMapWindow
	ret

GOpenDisplay:
	; Display* XOpenDisplay(NULL)
	mov rdi, 0 ; Display name (0 indicates default display)
	CALL_AND_ALLOCATE_STACK XOpenDisplay
    mov [display], rax
	ret

GDefaultScreen:
	; int XDefaultScreen(display)
	mov	rdi, [display]
	call XDefaultScreen
	mov	[screen], eax
	ret

GPixels:
	; int XBlackPixel(display, screen)
	mov	rdi, [display]
	mov	rsi, [screen]
	CALL_AND_ALLOCATE_STACK XBlackPixel
	mov	[black], eax

	; int XWhitePixel(display, screen)
	mov	rdi, [display]
	mov	rsi, [screen]
	CALL_AND_ALLOCATE_STACK XWhitePixel
	mov	[white], eax
	ret

GRootWindow:
	; Window XDefaultRootWindow(display)
	mov	rdi, [display]
	CALL_AND_ALLOCATE_STACK XDefaultRootWindow
	mov	[r_win], rax
	ret

GCreateWindow:
	; TODO: parameters
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
    CALL_AND_ALLOCATE_STACK XCreateSimpleWindow
    mov	[win], rax
    add rsp, 6 * 8 ; Clear the stack after the function call
	ret

GCreateGraphicsContext:
	; GC XCreateGC(display, win, GCForeground, &values_white)
	mov	ecx, [white]
	mov	[xgcvals_white + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]
	mov	rcx, xgcvals_white
	CALL_AND_ALLOCATE_STACK XCreateGC
	mov	[gc_color], rax

	; GC XCreateGC(display, win, GCForeground, &values_black)
	mov	ecx, [black]
	mov	[xgcvals_black + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]
	mov	rcx, xgcvals_black
	CALL_AND_ALLOCATE_STACK XCreateGC
	mov	[gc_black], rax

	ret

GDefaultColorMap:
	; Colormap XDefaultColormap(display, screen)
	mov	rdi, [display]
	mov	esi, [screen]
	CALL_AND_ALLOCATE_STACK XDefaultColormap
	mov	[colormap], rax
	ret

GSelectInput:
	; void XSelectInput(display, win, ExposureMask | KeyPressMask)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]
	CALL_AND_ALLOCATE_STACK XSelectInput
	ret

GMapWindow:
	; void XMapWindow(display, win)
	mov	rdi, [display]
	mov	rsi, [win]
	CALL_AND_ALLOCATE_STACK XMapWindow
	retgc_black

GDrawRectangle:
	; TODO: add parameters

	; void XDrawRectangle(display, window, gc, x_pxl, y_pxl, tile_len, tile_len)
    mov rdi, [display]
    mov rsi, [win]
    mov rdx, [gc_color]
    mov rcx, 150
    mov r8, 150
    mov r9, 200
    push r9
    call XDrawRectangle
	add rsp, 1 * 8 ; Clear the stack after the function call

	; void XFillRectangle(display, window, gc, x_pxl, y_pxl, tile_len, tile_len)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_color]
	mov	rcx, 150
	mov	r8, 150
	mov	r9, 200
	push r9
	call XFillRectangle
	add rsp, 1 * 8 ; Clear the stack after the function call

	ret

GCloseDisplay:
	; XCloseDisplay(display)
	mov rdi, [display]
	CALL_AND_ALLOCATE_STACK XCloseDisplay
	ret

%endif