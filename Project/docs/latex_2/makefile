# System variables
PDFLATEX = pdflatex

# Directories
CURR_DIR = $(shell pwd)
OUT_DIR = $(CURR_DIR)/output

# Target tex file
TEX = $(wildcard $(CURR_DIR)/*.tex)

# Rules for each target
.PHONY: all run clean
all: build $(TEX) run

# Rules to build the output directories
build:
	mkdir -p $(OUT_DIR)

# Run the tex
run: $(TEX)	# Run the tex file twice
	for i in 1 2; do \
		$(PDFLATEX) $(TEX); \
	done
	mv *.aux *.log *.out *.toc $(OUT_DIR)

# Clean up the output directory and the generated pdf
clean:
	rm -rf $(OUT_DIR) *.pdf
