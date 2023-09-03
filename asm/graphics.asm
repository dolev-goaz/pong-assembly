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
gc_white:		resb 8
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

; ---------------------- METHODS -------------------
;---------------------------------------------------
; Open Display
; ------------
; Stores the current display in [display]
;---------------------------------------------------
GOpenDisplay:
	; Display* XOpenDisplay(NULL)
	mov rdi, 0 ; Display name (0 indicates default display)
	CALL_AND_ALLOCATE_STACK XOpenDisplay
    mov [display], rax
	ret

;---------------------------------------------------
; Default Screen
; --------------
; Stores the default screen in [screen]
;---------------------------------------------------
GDefaultScreen:
	; int XDefaultScreen(display)
	mov	rdi, [display]
	call XDefaultScreen
	mov	[screen], eax
	ret

;---------------------------------------------------
; Pixels
; ------
; Gets and stores the black and white colors in
; [black] and [white] respectively
;---------------------------------------------------
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

;---------------------------------------------------
; Root Window
; -----------
; Gets the root window of the previously opened
; display and stores in [r_win]
;---------------------------------------------------
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
; Returns-	the created window([win])
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

;---------------------------------------------------
; Set Title
; ---------
; Sets the title of the current window
; --------------------------------------------------
; Receives- Address of the null terminated
; title(STACK)
;---------------------------------------------------
GSetTitle:
	mov rdi, [display]
	mov rsi, [win]
	GET_STACK_PARAM rdx, 1
	CALL_AND_ALLOCATE_STACK XStoreName
	ret

;---------------------------------------------------
; Create Graphics Context
; -----------------------
; Creates the graphics context for the colors black
; and white.
; --------------------------------------------------
; Returns-	the created context([gc_black], [gc_white])
;---------------------------------------------------
GCreateGraphicsContext:
	; GC XCreateGC(display, win, GCForeground, &values_white)
	mov	ecx, [white]
	mov	[xgcvals_white + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]
	mov	rcx, xgcvals_white
	CALL_AND_ALLOCATE_STACK XCreateGC
	mov	[gc_white], rax

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


;---------------------------------------------------
; Default Color Map
; -----------------
; Initializes the default color map for our app
; Used for color allocations
; --------------------------------------------------
; Returns-	the color map([colormap])
;---------------------------------------------------
GDefaultColorMap:
	; Colormap XDefaultColormap(display, screen)
	mov	rdi, [display]
	mov	esi, [screen]
	CALL_AND_ALLOCATE_STACK XDefaultColormap
	mov	[colormap], rax
	ret

;---------------------------------------------------
; Select Input
; ------------
; Request the X server to report events associated
; with keypress and exposure
;---------------------------------------------------
GSelectInput:
	; void XSelectInput(display, win, ExposureMask | KeyPressMask)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]
	CALL_AND_ALLOCATE_STACK XSelectInput
	ret


;---------------------------------------------------
; Map Window
; ----------
; Makes the game window eligible for display
;---------------------------------------------------
GMapWindow:
	; void XMapWindow(display, win)
	mov	rdi, [display]
	mov	rsi, [win]
	CALL_AND_ALLOCATE_STACK XMapWindow
	ret

;---------------------------------------------------
; Draw Rectangle Border
; ---------------------
; Draws a rectangle's outline
; Receives-	x, y, width, height	(STACK)
;---------------------------------------------------
GDrawRectangleBorder:
	; void XDrawRectangle(display, window, gc, x, y, width, height)
    mov rdi, [display]
    mov rsi, [win]
    mov rdx, [gc_white]
    GET_STACK_PARAM rcx, 4  ; x
    GET_STACK_PARAM r8, 3   ; y
    GET_STACK_PARAM r9, 2   ; width
    GET_STACK_PARAM rbx, 1  ; height
    push rbx                ; height is in the stack for some reason
    call XDrawRectangle
	CLEAR_STACK_PARAMS 1
    ret

;---------------------------------------------------
; Draw Rectangle
; --------------
; Draws a rectangle
; Receives-	x, y, width, height	(STACK)
;---------------------------------------------------
GDrawRectangle:
	; void XFillRectangle(display, window, gc, x, y, width, height)
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_black]

	GET_STACK_PARAM rcx, 4  ; x
	GET_STACK_PARAM r8, 3   ; y
	GET_STACK_PARAM r9, 2   ; width
	GET_STACK_PARAM rbx, 1  ; height
	push rbx
	call XFillRectangle
	CLEAR_STACK_PARAMS 1

	ret


;---------------------------------------------------
; Check Window Event
; ------------------
; Checks if exposure or keypress events were
; triggered
; --------------------------------------------------
; Returns-	the current event([STACK_xevent])
;---------------------------------------------------
GCheckWindowEvent:
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]

	GET_STACK_PARAM rcx, 1 ; rcx = xevent
	CALL_AND_ALLOCATE_STACK XCheckWindowEvent
	ret

;---------------------------------------------------
; Check Key Press
; ---------------
; Checks if a key press event was triggered.
; If it was, returns the XK code.
; --------------------------------------------------
; Returns- 	XK code if a key was pressed,
;			otherwise 0 (RAX)
;---------------------------------------------------
GCheckKeyPress:
	; clear xevent
	mov rdi, xevent_inner
	mov rcx, 192 ; sizeof(xevent_inner)
	xor rax, rax ; rax=0
	rep stosb	; 'repeat store byte'. repeat count- rcx, stored byte- al, destination address- rdi
	; end clear
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

;---------------------------------------------------
; KeyCode to KeySym
; -----------------
; Converts between key codes.
; --------------------------------------------------
; Receives-	Keycode	(XEVENT_INNER)
; Returns- 	XK code	(RAX)
;---------------------------------------------------
GKeycodeToKeysym:
	mov rdi, [display]
	mov esi, [xevent_inner + 84]	; offsetof(Xevent.xkey, keycode) == 84
	mov rdx, 0						; group
	mov rcx, 0						; level
	CALL_AND_ALLOCATE_STACK XkbKeycodeToKeysym
	; res in rax
	ret

;---------------------------------------------------
; Close Display
; -------------
; Closes the application
;---------------------------------------------------
GCloseDisplay:
	; XCloseDisplay(display)
	mov rdi, [display]
	CALL_AND_ALLOCATE_STACK XCloseDisplay
	ret

%endif