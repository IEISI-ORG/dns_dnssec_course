# Build all Marp decks into dist/
#   make html   - HTML for every deck
#   make pdf    - PDF for every deck (needs Chrome/Chromium)
#   make all    - both
#   make clean  - remove dist/

THEME := dns-workshop-css-theme.css
MARP  := marp --no-stdin --theme-set $(THEME) --html --allow-local-files

DECKS := $(wildcard modules/*.marp.md) dns_deck_overview.md dns-workshop-demo-presentation.md
NAMES := $(basename $(notdir $(DECKS)))

vpath %.md modules .

.PHONY: all html pdf clean
all: html pdf
html: $(NAMES:%=dist/%.html)
pdf:  $(NAMES:%=dist/%.pdf)

dist/%.html: %.md $(THEME) | dist
	$(MARP) -o $@ $<

dist/%.pdf: %.md $(THEME) | dist
	$(MARP) --pdf -o $@ $<

dist:
	mkdir -p dist

clean:
	rm -rf dist
