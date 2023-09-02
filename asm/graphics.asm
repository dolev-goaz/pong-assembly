%ifndef GRAPHICS_INCLUDED
%define GRAPHICS_INCLUDED
%include "asm/utils.asm"
section .data
ExposureMask:	dq 32768
KeyPressMask:	dq 1
gc_foreground:	dq 4

EventKeyPress:	dd 2

section .bss
xevent_inner:	resb 192

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
extern XDrawRectangle, XFillRectangle, XCheckWindowEvent, XCloseDisplay
extern XkbKeycodeToKeysym, XStoreName

; ---------------------- METHODS -------------------
;---------------------------------------------------
; Initialize Display
; --------------------------------------------------
; Receives- Display Width, Display Height(STACK)
;---------------------------------------------------
GInitializeDisplay:

	CALL_AND_ALLOCATE_STACK GOpenDisplay
	CALL_AND_ALLOCATE_STACK GDefaultScreen
	CALL_AND_ALLOCATE_STACK GPixels
	CALL_AND_ALLOCATE_STACK GRootWindow

	GET_STACK_PARAM rax, 1
	GET_STACK_PARAM rbx, 2
	push rbx
	push rax
	call GCreateWindow
	CLEAR_STACK_PARAMS 2

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

;---------------------------------------------------
; Create Window
; --------------------------------------------------
; Receives- Window Width, Window Height(STACK)
;---------------------------------------------------
GCreateWindow:
	; Window XCreateSimpleWindow(display, r_win, 0, 0, width, height, 0, black, black)
	mov rdi, [display]		; display
	mov rsi, [r_win]		; window
	mov rdx, 0				; window position x (doesn't work?)
	mov rcx, 0				; window position y (doesn't work?)
	GET_STACK_PARAM r8, 2 	; window width
	GET_STACK_PARAM r9, 1 	; window height

	mov r10, 2				; border width (doesn't work?)
	mov r11, 0xFFFFFF		; border color (doesn't work?)
	mov r12, 0xFFFFFF		; background color (doesn't work?)


	push 0x393968			; background-color
	mov rax, 0				; clear return value
	CALL_AND_ALLOCATE_STACK_COUNT XCreateSimpleWindow, 2
	CLEAR_STACK_PARAMS 1

    mov	[win], rax
	ret

GSetTitle:
	mov rdi, [display]
	mov rsi, [win]
	GET_STACK_PARAM rdx, 1
	CALL_AND_ALLOCATE_STACK XStoreName
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
	ret

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

GCheckWindowEvent:
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]

	GET_STACK_PARAM rcx, 1 ; rcx = xevent
	CALL_AND_ALLOCATE_STACK XCheckWindowEvent
	ret

GCheckKeyPress:
	PUSH_ADDRESS xevent_inner
	call GCheckWindowEvent
	CLEAR_STACK_PARAMS 1

	mov rax, 0

	mov	ecx, [xevent_inner + 0] 	; offsetof(xevent_inner, type) == 0
	cmp ecx, [EventKeyPress]
	jne .finished_key_press

	; key was pressed
	CALL_AND_ALLOCATE_STACK GKeycodeToKeysym
	; res in rax

.finished_key_press:
	ret

GKeycodeToKeysym:
	mov rdi, [display]
	mov esi, [xevent_inner + 84]	; offsetof(Xevent.xkey, keycode) == 84
	mov rdx, 0						; group
	mov rcx, 0						; level
	CALL_AND_ALLOCATE_STACK XkbKeycodeToKeysym
	; res in rax
	ret

GCloseDisplay:
	; XCloseDisplay(display)
	mov rdi, [display]
	CALL_AND_ALLOCATE_STACK XCloseDisplay
	ret

%endif