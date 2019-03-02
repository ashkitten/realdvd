; vim:ft=nasm

bits 16

%ifdef FLOPPY
org 0x7c00
%else
org 0x0100
%endif

init:
    %ifdef FLOPPY
    ; pad because some bioses will overwrite with drive geometry
    times 50 nop

    ; can't depend on the bios to clear regs
    xor ax, ax
    xor bx, bx
    xor si, si
    xor di, di

    ; setup segment registers
    mov ds, ax ; ds = 0
    mov ss, ax ; ss = 0

    ; setup stack pointer
    mov sp, 0xffff
    %endif

    ; we have to start off going backward so it doesn't cause problems with the collision code
    mov cx, -1 ; direction.x
    mov dx, -1 ; direction.y
    pusha      ; save all values to stack

    ; set video mode
    %ifndef NOCOLOR
    mov ax, 0x4f02
    mov bx, 0x0101
    %else
    mov ax, 0x0011
    %endif
    int 0x10
main_loop:

movelogo:
    popa

    xor si, si
    mov di, cur_color

    inc ax
    dec ax
    je .flip_x
    cmp ax, 640 - logo_width
    je .flip_x

    jmp .noflip_x
    .flip_x:
    neg cx
    inc si
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
    inc si
    .noflip_y:

    ; add direction to positions
    add ax, cx
    add bx, dx

    pusha

changecolors:
    mov ax, si
    add byte [di], al
    cmp byte [di], 14
    jle .skip
    mov byte [di], 9
    .skip:

drawlogo:
    mov si, logo ; i
    xor bx, bx ; n
    mov ax, [di] ; current color (cur_color address is stored in di)
    xor cx, cx ; x
    xor dx, dx ; y
    ; width is an equ already defined

    push bx

drawloop:
    pop bx
    shr bx, 5 ; discard the chunk we just used
    cmp bx, 0b0100000 ; check if we're out of data
    jge _drawloop
    cmp si, logo_end
    je main_loop
    mov bx, [si] ; load the next 2 bytes of data
    inc si
    inc si
_drawloop:
    push bx
    and bx, 0b0011111 ; we only care about the lowest 6 bit chunk
    xor ax, [di] ; invert the color
    drawrun:
        dec bx ; check if the run's done and if not decrement it
        jl drawloop

        pusha
        mov ah, 0x0c ; draw pixel
        mov bx, sp
        add cx, word [bx + 32]
        add dx, word [bx + 26]
        xor bx, bx
        int 0x10
        popa

        ; if we're at the end of the row loop back
        inc cx
        cmp cx, logo_width
        jl drawrun
        xor cx, cx
        inc dx
        jmp drawrun

logo:
%include "logo.s"
logo_size equ $ - logo
logo_end equ $

cur_color db 13 ; 13 + 2 for initial collisions is 15 (white)

%ifdef FLOPPY
; padding to 512
times 510 - ($ - $$) db 0
; boot signature
dw 0xaa55
%endif
