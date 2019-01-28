.PHONY: all

all: Makefile dvd.com

run: Makefile all
	dosbox dvd.com

dvd.com dvd.list: Makefile main.s logo.s rle.s
	nasm -f bin main.s -o dvd.com -l dvd.list
	wc -c dvd.com

logo.s: Makefile logogen.pl logo.ascii
	cat logo.ascii | perl -n logogen.pl > logo.s
