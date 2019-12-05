# Makefile - gnu make recipe for building HTML files

SOURCES = $(shell find . -regex '.*/[^.\#]+\.xml' )

%.html : %.xml
	xsltproc htmlgen.xslt $< >$@

#all: $(addsuffix .html,$(basename $(SOURCES)))
all:
	xsltproc htmlgen.xslt

test:
	@echo sources = $(SOURCES)
