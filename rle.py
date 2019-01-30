def rle():
    with open("logo.ascii") as fp:
        logo = fp.read().split("\n")[:-1]

    # simple row based rle
    bits = 5
    cur = "."
    run = 0
    buf = list()
    for row in logo:
        for c in row:
            if c == cur:
                run += 1
            else:
                cur = c
                buf += [run]
                run = 1
            if run > 2 ** bits - 1:
                buf += [2 ** bits - 1]
                buf += [0]
                run = run - 2 ** bits + 1
    # we don't need to append the last run if it's a run of 0's
    if cur != ".":
        buf += [run]

    # iterator to split off the data into chunks
    def chunks(l, n):
        ret = list()
        for b in l:
            ret += [b]
            if len(ret) == n:
                yield ret
                ret = list()
        if len(ret) == 0: return
        while len(ret) % n != 0:
            ret += [0]
        yield ret

    buf2 = list()
    for b in chunks(buf, 3):
        i = b[0] | b[1] << 5 | b[2] << 10 | 1 << 15
        buf2 += [i & 0xff, i >> 8 & 0xff]

    return (len(logo[0]), len(logo), buf2)

if __name__ == "__main__":
    (width, height, buf) = rle()
    # print it as a nasm data directive
    print("logo_width equ", width)
    print("logo_height equ", height)
    print("db " + ", ".join(map(str, buf)))
