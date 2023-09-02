%include "asm/utils.asm"
%include "asm/string_utils.asm"
%include "asm/graphics.asm"

section .bss
xevent:	 resb 192

section .text
global main

main:
	call GInitializeDisplay

	;Infinite Game loop
gameLoop:

	call GDrawRectangle

    jmp gameLoop

exit_program:
    call GCloseDisplay
    push 0
    call exit

; ------------------------- methods