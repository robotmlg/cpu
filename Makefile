TESTS=$(shell find . -maxdepth 1 -name '*.test.v')
BINS=$(TESTS:.v=.run)

VFLAGS=-g 2009 -Wall


all: $(BINS)

%.run: %.v
	iverilog -o $@ $(VFLAGS) $< 

clean:
	rm -fv *.run Makefile.deps

tar:
	mkdir mgoldman_proj2
	cp *.v mgoldman_proj2
	cp Makefile mgoldman_proj2
	cp README.txt mgoldman_proj2
	cp -r tests mgoldman_proj2
	tar cvf mgoldman_proj2.tar mgoldman_proj2
	rm -rf mgoldman_proj2


.INTERMEDIATE: $(BINS:.run=.v.dep)
%.v.dep: %.v
	$(eval TMPF=$(shell mktemp))
	iverilog -o /dev/null $(VFLAGS) -Minclude=$(TMPF) $< 
	gsed -i -e "1i $@:" -e 's/\.v\.dep:/.run:/' $(TMPF)
	paste -sd ' ' $(TMPF) > $@
	paste -sd ' ' $(TMPF) | sed -e 's/\.v\.dep:/.run:/' >> $@
	rm -f $(TMPF)

Makefile.deps: $(BINS:.run=.v.dep)
	cat $^ /dev/null > $@

ifneq ($(BINS),)
include Makefile.deps
endif
