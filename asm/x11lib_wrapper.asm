%ifndef GRAPHICS_INCLUDED
%define GRAPHICS_INCLUDED
%include "asm/utils.asm"
section .data
ExposureMask:	dq 1 << 15	; 15th bit
KeyPressMask:	dq 1 << 0	; 1st bit
gc_foreground:	dq 4

EventKeyPress:	dd 2
EventExpose:	dd 12


; Color names
clr_name_black:		db "black", 0
clr_name_white:		db "white", 0
clr_name_yellow:	db "yellow", 0
clr_name_red:		db "red", 0
clr_name_teal:		db "teal", 0

section .bss
xevent_inner:	resb 192

display:		resb 8
screen: 		resb 4
r_win: 			resb 8
win: 			resb 8
gc_white:		resb 8
colormap: 		resb 8

white: 			resb 4

xgcvals_white: 	resb 128

xcolors:
	struc xcolors_struct
		.black		resb 16
		.white		resb 16
		.yellow:	resb 16
		.red:		resb 16
		.teal:		resb 16
		.temp:		resb 16 ; yeah idk why this is here
	endstruc


section .text

extern XOpenDisplay, XDefaultScreen, XDefaultRootWindow
extern XCreateSimpleWindow, XWhitePixel
extern XMapWindow, XSelectInput, XCreateGC, XDefaultColormap
extern XDrawRectangle, XFillRectangle, XCheckWindowEvent, XCloseDisplay
extern XkbKeycodeToKeysym, XStoreName, XAllocNamedColor, XSetForeground
extern XDrawLine, XDrawArc, XFillArc, XFlush

; ---------------------- METHODS -------------------
;---------------------------------------------------
; Initialize Display
; --------------------------------------------------
; Receives- Display Width, Display Height(STACK)
;---------------------------------------------------
GInitializeDisplay:

	call GOpenDisplay
	call GDefaultScreen
	call GPixels
	call GRootWindow

	GET_STACK_PARAM rax, 1
	GET_STACK_PARAM rbx, 2
	push rbx
	push rax
	call GCreateWindow
	CLEAR_STACK_PARAMS 2

	call GCreateGraphicsContext
	call GDefaultColorMap
	call GInitializeColors
	call GSelectInput
	call GMapWindow

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
	call XOpenDisplay
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
; Gets and stores the white color into [white]
;---------------------------------------------------
GPixels:
	; int XWhitePixel(display, screen)
	mov	rdi, [display]
	mov	rsi, [screen]
	call XWhitePixel
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
	call XDefaultRootWindow
	mov	[r_win], rax
	ret

;---------------------------------------------------
; Create Window
; --------------------------------------------------
; Receives- Window Width, Window Height(STACK)
; Returns-	the created window([win])
;---------------------------------------------------
GCreateWindow:
	; Window XCreateSimpleWindow(display, r_win, 0, 0, width, height)
	mov rdi, [display]		; display
	mov rsi, [r_win]		; window
	mov rdx, 0				; window position x (not honored- main window is a child of OS)
	mov rcx, 0				; window position y (not honored- main window is a child of OS)
	GET_STACK_PARAM r8, 2 	; window width
	GET_STACK_PARAM r9, 1 	; window height

	; rest of parameters need to be pushed in reverse
	push qword 0xFFFFFF		; window background color	(honored)
	push qword 0xFF0000		; window border color		(not honored- idk why)
	push qword 5			; window border size		(not honored- idk why)

	mov rax, 0				; clear return value
	call XCreateSimpleWindow
	CLEAR_STACK_PARAMS 3

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
	call XStoreName
	ret

;---------------------------------------------------
; Create Graphics Context
; -----------------------
; Creates the graphics context for the color white.
; --------------------------------------------------
; Returns-	the created context([gc_white])
;---------------------------------------------------
GCreateGraphicsContext:
	; GC XCreateGC(display, win, GCForeground, &values_white)
	mov	ecx, [white]
	mov	[xgcvals_white + 16], ecx	; offsetof(XGCValues, foreground) == 16
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [gc_foreground]
	mov	rcx, xgcvals_white
	call XCreateGC
	mov	[gc_white], rax

	ret

%macro InitializeColor 1
	; XAllocNamedColor(display, colormap, %1, xcol_struct.%1, xcol_struct.temp)
	mov rdi, [display]
	mov rsi, [colormap],
	mov rdx, clr_name_%1
	mov rcx, xcolors
	add rcx, xcolors_struct.%1
	mov r8, xcolors
	add r8, xcolors_struct.temp

	call XAllocNamedColor
%endmacro
;---------------------------------------------------
; Initialize colors
; -----------------------
; Initializes named colors
; --------------------------------------------------
; Returns-	the initialized colors([xcolors])
;---------------------------------------------------
GInitializeColors:
	InitializeColor black
	InitializeColor white
	InitializeColor yellow
	InitializeColor red
	InitializeColor teal
	ret

;---------------------------------------------------
; Set Foreground color
; -----------------------
; Sets the current color
; --------------------------------------------------
; Receives- the color index (STACK)
;---------------------------------------------------
GSetForegroundColor:
	; void XSetForeground(display, gc_draw, XColor.pixel)
	GET_STACK_PARAM r11, 1

	MY_PUSHA
	mov	eax, 16 ; size of color
	mul	r11d	; offset from start of colors

	mov	rdi, [display]
	mov	rsi, [gc_white]
	mov	rdx, [xcolors + eax]	; offsetof(XColor, pixel) == 0
	call XSetForeground

	MY_POPA
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
	call XDefaultColormap
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
	call XSelectInput
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
	call XMapWindow
	ret

;---------------------------------------------------
; Draw Circle
; -----------
; Draws a circle
; Receives-	x, y, radius (STACK)
;---------------------------------------------------
GDrawCircle:
	; void XFillArc(display, win, gc, x, y, radius, radius, 0, 360*64)
	mov rdi, [display]
	mov rsi, [win]
	mov rdx, [gc_white]
	GET_STACK_PARAM rcx, 3	; x
	GET_STACK_PARAM r8, 2	; y
	GET_STACK_PARAM r9, 1	; width
	push 360 * 64	; end angle
	push 0			; start angle
	push r9			; height

	call XFillArc
	CLEAR_STACK_PARAMS 3
	ret

;---------------------------------------------------
; Draw Circle Border
; ------------------
; Draws a circle
; Receives-	x, y, radius (STACK)
;---------------------------------------------------
GDrawCircleBorder:
	; void XDrawCircle(display, win, gc, x, y, radius, radius, 0, 360*64)
	mov rdi, [display]
	mov rsi, [win]
	mov rdx, [gc_white]
	GET_STACK_PARAM rcx, 3	; x
	GET_STACK_PARAM r8, 2	; y
	GET_STACK_PARAM r9, 1	; width
	push 360 * 64	; end angle
	push 0			; start angle
	push r9			; height

	call XDrawArc
	CLEAR_STACK_PARAMS 3
	ret

;---------------------------------------------------
; Draw Line
; ---------
; Draws a line
; Receives-	x1, y1, x2, y2 (STACK)
;---------------------------------------------------
GDrawLine:
	; void XDrawLine(display, win, gc, x1, y1, x2, y2)
	mov rdi, [display]
	mov rsi, [win]
	mov rdx, [gc_white]
	GET_STACK_PARAM rcx, 4	; x1
	GET_STACK_PARAM r8, 3	; y1
	GET_STACK_PARAM r9, 2	; x2
	GET_STACK_PARAM rbx, 1
	push rbx				; y2
	call XDrawLine
	CLEAR_STACK_PARAMS 1
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
    sub r9, 1               ; width is one more for some reason?
    GET_STACK_PARAM rbx, 1  ; height
    sub rbx, 1              ; height is one more for some reason?
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
	mov	rdx, [gc_white]

	GET_STACK_PARAM rcx, 4  ; x
	GET_STACK_PARAM r8, 3   ; y
	GET_STACK_PARAM r9, 2   ; width
	GET_STACK_PARAM rbx, 1  ; height
	push rbx
	call XFillRectangle
	CLEAR_STACK_PARAMS 1

	ret

;---------------------------------------------------
; Flush
; -----
; Not sure what it does really
;---------------------------------------------------
GFlush:
	mov rdi, [display]
	call XFlush
	ret


;---------------------------------------------------
; Check Window Event
; ------------------
; Checks if exposure or keypress events were
; triggered
; --------------------------------------------------
; Returns-	the current event([xevent_inner])
;---------------------------------------------------
GCheckWindowEvent:
	; ---- clear previous event
	mov rdi, xevent_inner
	mov rcx, 192 ; sizeof(xevent_inner)
	xor rax, rax ; rax=0
	rep stosb	; 'repeat store byte'. repeat count- rcx, stored byte- al, destination address- rdi
	; ---- get current event
	mov	rdi, [display]
	mov	rsi, [win]
	mov	rdx, [ExposureMask]
	or	rdx, [KeyPressMask]
	mov rcx, xevent_inner

	; causes segfault without allocating stack, idk why
	CALL_AND_ALLOCATE_STACK XCheckWindowEvent
	ret

;---------------------------------------------------
; Check Expose
; ------------
; Checks if an expose event was triggered
; --------------------------------------------------
; Receives-	the current event(xevent_inner)
; Returns- 	If an expose event was raised(rax)
;---------------------------------------------------
GCheckExpose:
	mov rax, 0

	mov ecx, [xevent_inner + 0] 	; offsetof(xevent_inner, type) == 0
	cmp ecx, [EventExpose]
	jne .finished_expose

	mov rax, 1

.finished_expose:
	ret

;---------------------------------------------------
; Check Key Press
; ---------------
; Checks if a key press event was triggered.
; If it was, returns the XK code.
; --------------------------------------------------
; Receives-	the current event(xevent_inner)
; Returns-	XK code if a key was pressed,
;			otherwise 0 (RAX)
;---------------------------------------------------
GCheckKeyPress:
	xor rax, rax
	mov	ecx, [xevent_inner + 0] 	; offsetof(xevent_inner, type) == 0
	cmp ecx, [EventKeyPress]
	jne .finished_key_press

	; key was pressed
	call GKeycodeToKeysym
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
	mov rsi, [xevent_inner + 84]	; offsetof(Xevent.xkey, keycode) == 84
	mov rdx, 0						; group
	mov rcx, 0						; level

	; causes segfault without allocating stack, idk why
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
	call XCloseDisplay
	ret

%endif