; vim:ft=nasm

bits 16

%ifdef FLOPPY
org 0x7c00
%else
org 0x0100
%endif

init:
    ; we have to start off going backward so it doesn't cause problems with the collision code
    xor ax, ax ; position.x
    xor bx, bx ; position.y
    mov cl, -1 ; direction.x
    mov dl, -1 ; direction.y
    pusha      ; save all values to stack

main_loop:

reset:
    mov ax, 0x0011
    int 0x10

	mov ax, 0x13
	int 0x10 ; set graphics video mode

movelogo:
    popa

    cmp al, 0
    je .flip_x
    cmp al, 640 / 8 - 8
    je .flip_x

    jmp .noflip_x
    .flip_x:
    neg cl
    .noflip_x:

    ; `cmp bl, 0` is 3 bytes, this is only 2
    inc bx
    dec bx
    je .flip_y
    cmp bl, (480 - logo_size / 8) / 8
    je .flip_y

    jmp .noflip_y
    .flip_y:
    neg dl
    .noflip_y:

    ; add direction to positions
    add al, cl
    add bl, dl

    pusha

drawlogo:
	mov si, logo ; i
	xor ecx, ecx ; n
	mov dl, 15 ; cur color
	xor ax, ax ; x
	xor bx, bx ; y
	; width is an equ already defined

	push ecx

drawloop: 
	pop ecx
	shr ecx, 6 ; discard the chunk we just used
	cmp ecx, 0x100 ; check if we're out of data
	jge _drawloop
	cmp si, logo_end
	je sleep
	mov ecx, [si] ; load the next 3 bytes of data
	add si, 3
	or ecx, 0xff000000 ; set a new sentinel in the highest byte to tell us when we're out
_drawloop:
	push ecx
	and cl, 111111b ; we only care about the lowest 6 bit chunk
	xor dl, 15 ; invert the color
	drawrun:
		dec cl ; check if the run's done and if not decrement it 
		jl drawloop
		
		pusha
		mov cx, ax ; column
		mov al, dl ; color
		mov dx, bx ; row
		mov ah, 0xc ; draw pixel
		int 0x10
		popa

		; if we're at the end of the row loop back
		inc ax
		cmp ax, logo_width
		jl drawrun
		xor ax, ax
		inc bx
		jmp drawrun

sleep:
    mov ah, 0x86 ; wait interrupt
    mov cl, 0x09 ; low byte of high word of wait time
    xor dx, dx   ; low word of wait time
    int 0x15     ; execute interrupt

jmp main_loop

logo:
%include "logo.s"
logo_size equ $ - logo
logo_end equ $

%ifdef FLOPPY
; padding to 512
times 510 - ($ - $$) db 0
; boot signature
dw 0xaa55
%endif
