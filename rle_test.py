from rle import rle

(width, height, buf) = rle()
screen = [["." for _ in range(width)] for _ in range(height)]

x = 0
y = 0
i = 0
n = 0
cur = 1 
while True:
    n = n >> 6
    if n < 0x100:
        if i >= len(buf): break
        n = buf[i+2] << 16 | buf[i+1] << 8 | buf[i]
        i += 3
        n |= 0xff000000
    run = n & 0b111111
    cur ^= 1
    while run > 0:
        run -= 1
        screen[y][x] = "#" if cur else "."
        x += 1
        if x == width:
            x = 0
            y += 1

for row in screen:
    print("".join(row))
