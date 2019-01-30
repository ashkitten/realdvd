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
    mov cx, -1 ; direction.x
    mov dx, -1 ; direction.y
    pusha      ; save all values to stack

    ; set video mode
    mov ax, 0x0011
    int 0x10
main_loop:

movelogo:
    popa

    cmp ax, 0
    je .flip_x
    cmp ax, 640 - logo_width
    je .flip_x

    jmp .noflip_x
    .flip_x:
    neg cx
    .noflip_x:

    ; `cmp bl, 0` is 3 bytes, this is only 2
    inc bx
    dec bx
    je .flip_y
    cmp bx, 480 - logo_height
    je .flip_y

    jmp .noflip_y
    .flip_y:
    neg dx
    .noflip_y:

    ; add direction to positions
    add ax, cx
    add bx, dx

    pusha

drawlogo:
    mov si, logo ; i
    xor cx, cx ; n
    mov dl, 1  ; current color
    xor ax, ax ; x
    xor bx, bx ; y
    ; width is an equ already defined

    push cx

drawloop:
    pop cx
    shr cx, 5 ; discard the chunk we just used
    cmp cx, 0b0100000 ; check if we're out of data
    jge _drawloop
    cmp si, logo_end
    je drawloop_end
    mov cx, [si] ; load the next 2 bytes of data
    add si, 2
_drawloop:
    push cx
    and cl, 0b0011111 ; we only care about the lowest 6 bit chunk
    xor dl, 1 ; invert the color
    drawrun:
        dec cl ; check if the run's done and if not decrement it
        jl drawloop

        pusha
        mov cx, ax ; column
        mov al, dl ; color
        mov dx, bx ; row
        mov ah, 0x0c ; draw pixel
        add cx, [esp + 32]
        add dx, [esp + 26]
        int 0x10
        popa

        ; if we're at the end of the row loop back
        inc ax
        cmp ax, logo_width
        jl drawrun
        xor ax, ax
        inc bx
        jmp drawrun

    ; we're done with this
    pop cx
drawloop_end:

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
