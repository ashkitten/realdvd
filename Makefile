.PHONY: all clean run

all: Makefile dvd.com floppy.img

clean:
	rm dvd.com dvd.list floppy.img floppy.list logo.s

run: Makefile dvd.com
	dosbox dvd.com

run-qemu: Makefile floppy.img
	qemu-system-i386 -hda floppy.img

floppy.img floppy.list: Makefile main.s logo.s
	nasm -f bin main.s -o floppy.img -l floppy.list -D FLOPPY $(ASFLAGS)

dvd.com dvd.list: Makefile main.s logo.s
	nasm -f bin main.s -o dvd.com -l dvd.list $(ASFLAGS)
	wc -c dvd.com

logo.s: Makefile rle.py logo.ascii
	python rle.py > logo.s

#logo.s: Makefile logogen.pl logo.ascii
#	cat logo.ascii | perl -n logogen.pl > logo.s
