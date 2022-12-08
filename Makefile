SHELL=bash

default: all

bas2tap/bas2tap: bas2tap/bas2tap.c
	cd bas2tap && $(MAKE) bas2tap

bin2tap/bin2tap: bin2tap/bin2tap.hs
	cd bin2tap && $(MAKE) bin2tap

build/day%/main.bin: day%.asm math.asm print.asm bigloops.asm
	mkdir -p $(dir $@)
	sjasmplus $< --lst=$@.lst
	mv $(<:.asm=.bin) $@
	-mv $(<:.asm=.labels) $@.labels

build/day%/preload.bas: preload_template.bas
	mkdir -p $(dir $@)
	sed -e "s/FILENAME/AoC22d"`printf '%s' $@ | sed -E 's#.*day([0-9]+).*#\1#'`"/" < $< > $@

build/day%/preload.tap: build/day%/preload.bas bas2tap/bas2tap
	bas2tap/bas2tap -sAoC22d`printf '%s' $@ | sed -E 's#.*day([0-9]+).*#\1#'` -a1 $< $@

build/day%/main.bin.tap: build/day%/main.bin bin2tap/bin2tap
	bin2tap/bin2tap 0x8000 AoC22d`printf '%s' $@ | sed -E 's#.*day([0-9]+).*#\1#'`b $<

build/day%/input.txt.tap: inputs/day%.txt bin2tap/bin2tap
	cat $< <(echo -ne '\x00') > $(<).0
	bin2tap/bin2tap 0xa000 AoC22d`printf '%s' $@ | sed -E 's#.*day([0-9]+).*#\1#'`i $(<).0
	mv $(<).0.tap $@ 

build/day%/full.tap: build/day%/preload.tap build/day%/main.bin.tap build/day%/input.txt.tap
	cat $^ > $@

megatape.tap: build/day1/full.tap build/day2/full.tap build/day3/full.tap build/day4/full.tap build/day5/full.tap build/day6/full.tap
	cat $^ > $@

%.wav: %.tap
	tape2wav $< $@

all: megatape


clean:
	rm -rf build
	-rm -- tests/*/*.0
	-rm *.wav
	-rm *.tap
