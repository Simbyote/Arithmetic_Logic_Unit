# System variables
IVERILOG = iverilog
SIMULATOR = vvp

# Directories
CURR_DIR = $(shell pwd)
SRC_DIR = $(CURR_DIR)/src
TEST_DIR = $(CURR_DIR)/tb
OUT_DIR = $(CURR_DIR)/out
WAVE_DIR = $(OUT_DIR)/waveforms
SIM_DIR = $(OUT_DIR)/simulations

# Recursively gather all Verilog files in src/
SRC_FILES = $(shell find $(SRC_DIR) -type f -name "*.v")
TESTBENCHES = $(wildcard $(TEST_DIR)/*.v)

# Simulation targets
SIMULATIONS = $(patsubst $(TEST_DIR)/%.v, $(SIM_DIR)/%.out, $(TESTBENCHES))

# Rules for each target
.PHONY: all run clean
all: build $(SIMULATIONS) run

# Rule to build the output directories
build:
	mkdir -p $(WAVE_DIR) $(SIM_DIR)

# Build the simulation targets
$(SIM_DIR)/%.out: $(TEST_DIR)/%.v $(SRC_FILES)
	$(IVERILOG) -g2012 -o $@ $(SRC_FILES) $<

# Run all the simulations
run: $(SIMULATIONS)
	for sim in $^; do \
		$(SIMULATOR) $$sim; \
	done
	mv *.vcd $(WAVE_DIR)

# Clean up the output directory
clean:
	rm -rf $(OUT_DIR)