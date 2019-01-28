; vim:ft=nasm

org 0x100

init:
    ; we have to start off going backward so it doesn't cause problems with the collision code
    xor al, al ; position.x
    xor bl, bl ; position.y
    mov cl, -1 ; direction.x
    mov dl, -1 ; direction.y
    pusha      ; save all values to stack

main_loop:

reset:
    ; ax is still 0 from xor'ing earlier
    mov al, 0x11
    int 0x10

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

    ; set position in framebuffer
    mov di, ax
    imul si, bx, 640 / 8 * 8
    add di, si

    pusha

drawlogo:
    mov si, logo

    mov ax, 0xa000
    mov es, ax
    pop di
    push di

    .drawline:
        mov cl, 8
        rep movsb
        add di, 640 / 8 - 8
        cmp si, logo + logo_size ; end of logo
        jl .drawline

sleep:
    mov ah, 0x86 ; wait interrupt
    mov cl, 0x09 ; low byte of high word of wait time
    xor dx, dx   ; low word of wait time
    int 0x15     ; execute interrupt

jmp main_loop

logo:
%include "logo.s"
logo_size equ $ - logo
