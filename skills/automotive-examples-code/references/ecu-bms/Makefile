# BMS ECU Makefile
# Supports both native (testing) and cross-compilation (ARM target)

# Project Configuration
PROJECT = bms_ecu
VERSION = 1.0.0
BUILD_DIR = build
SRC_DIR = src
TEST_DIR = tests

# Toolchain Configuration
# Set TARGET=arm for cross-compilation, or leave empty for native build
TARGET ?= native

ifeq ($(TARGET),arm)
    # ARM Cortex-M4 Cross-Compilation
    PREFIX = arm-none-eabi-
    CC = $(PREFIX)gcc
    AS = $(PREFIX)as
    LD = $(PREFIX)ld
    OBJCOPY = $(PREFIX)objcopy
    SIZE = $(PREFIX)size

    # MCU Specific Flags
    MCU = -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
    LDSCRIPT = config/stm32f407.ld

    # Target-specific CFLAGS
    TARGET_CFLAGS = $(MCU) -DSTM32F407xx -DUSE_HAL_DRIVER
    TARGET_LDFLAGS = $(MCU) -T$(LDSCRIPT) -Wl,--gc-sections
else
    # Native Build for Testing
    CC = gcc
    AS = as
    LD = ld
    OBJCOPY = objcopy
    SIZE = size

    TARGET_CFLAGS = -DNATIVE_BUILD
    TARGET_LDFLAGS =
endif

# Compiler Flags
CFLAGS = -Wall -Wextra -Werror -std=c11 -O2 -g3
CFLAGS += $(TARGET_CFLAGS)
CFLAGS += -DVERSION=\"$(VERSION)\"
CFLAGS += -I$(SRC_DIR) -I$(SRC_DIR)/application -I$(SRC_DIR)/rte -I$(SRC_DIR)/bsw

# MISRA C Compliance Flags
CFLAGS += -Wpedantic -Wshadow -Wstrict-prototypes -Wmissing-prototypes

# Linker Flags
LDFLAGS = $(TARGET_LDFLAGS) -lm

# Source Files
APP_SOURCES = $(wildcard $(SRC_DIR)/application/*.c)
RTE_SOURCES = $(wildcard $(SRC_DIR)/rte/*.c)
BSW_SOURCES = $(wildcard $(SRC_DIR)/bsw/*.c)
MAIN_SOURCE = $(SRC_DIR)/main.c

ALL_SOURCES = $(APP_SOURCES) $(RTE_SOURCES) $(BSW_SOURCES) $(MAIN_SOURCE)
OBJECTS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(ALL_SOURCES))

# Test Sources
TEST_SOURCES = $(wildcard $(TEST_DIR)/unit/*.c)
TEST_OBJECTS = $(patsubst $(TEST_DIR)/%.c,$(BUILD_DIR)/test_%.o,$(TEST_SOURCES))
TEST_EXECUTABLE = $(BUILD_DIR)/test_runner

# Output Files
ELF_FILE = $(BUILD_DIR)/$(PROJECT).elf
BIN_FILE = $(BUILD_DIR)/$(PROJECT).bin
HEX_FILE = $(BUILD_DIR)/$(PROJECT).hex
MAP_FILE = $(BUILD_DIR)/$(PROJECT).map

# Default Target
all: $(ELF_FILE) $(BIN_FILE) $(HEX_FILE) size

# Create Build Directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/application
	mkdir -p $(BUILD_DIR)/rte
	mkdir -p $(BUILD_DIR)/bsw

# Compile Source Files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@echo "Compiling $<"
	$(CC) $(CFLAGS) -c $< -o $@

# Link ELF File
$(ELF_FILE): $(OBJECTS)
	@echo "Linking $(ELF_FILE)"
	$(CC) $(OBJECTS) $(LDFLAGS) -Wl,-Map=$(MAP_FILE) -o $@

# Generate Binary File
$(BIN_FILE): $(ELF_FILE)
	$(OBJCOPY) -O binary $< $@

# Generate Hex File
$(HEX_FILE): $(ELF_FILE)
	$(OBJCOPY) -O ihex $< $@

# Display Size Information
size: $(ELF_FILE)
	@echo "=== Memory Usage ==="
	$(SIZE) $(ELF_FILE)

# Unit Tests (Native Build Only)
test: TARGET = native
test: CFLAGS += -DUNIT_TEST -coverage
test: LDFLAGS += -coverage
test: $(TEST_EXECUTABLE)
	@echo "Running unit tests..."
	./$(TEST_EXECUTABLE)
	@echo "Generating coverage report..."
	gcov $(ALL_SOURCES)
	lcov --capture --directory $(BUILD_DIR) --output-file $(BUILD_DIR)/coverage.info
	genhtml $(BUILD_DIR)/coverage.info --output-directory $(BUILD_DIR)/coverage_html
	@echo "Coverage report: $(BUILD_DIR)/coverage_html/index.html"

$(TEST_EXECUTABLE): $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) $(TEST_OBJECTS)
	$(CC) $^ $(LDFLAGS) -o $@

$(BUILD_DIR)/test_%.o: $(TEST_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(TEST_DIR) -c $< -o $@

# Static Analysis
analyze:
	@echo "Running static analysis..."
	cppcheck --enable=all --inconclusive --std=c11 \
		--suppress=missingIncludeSystem \
		--suppress=unusedFunction \
		$(SRC_DIR)

# MISRA C Compliance Check
misra:
	@echo "Checking MISRA C compliance..."
	cppcheck --addon=misra.json --std=c11 $(SRC_DIR)

# Flash to Target (OpenOCD)
flash: $(BIN_FILE)
	openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
		-c "program $(BIN_FILE) 0x08000000 verify reset exit"

# Flash to Target (J-Link)
flash-jlink: $(HEX_FILE)
	JLinkExe -device STM32F407VG -if SWD -speed 4000 \
		-CommanderScript config/jlink_flash.jlink

# Debug with GDB (OpenOCD)
debug:
	openocd -f interface/stlink.cfg -f target/stm32f4x.cfg &
	arm-none-eabi-gdb $(ELF_FILE) \
		-ex "target remote localhost:3333" \
		-ex "monitor reset halt" \
		-ex "load" \
		-ex "monitor reset init"

# Clean Build Artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.gcov *.gcda *.gcno

# Clean All (including dependencies)
distclean: clean
	rm -f $(PROJECT).tar.gz

# Create Release Archive
release: all
	tar -czf $(PROJECT)-$(VERSION).tar.gz \
		$(SRC_DIR) $(TEST_DIR) config arxml \
		Makefile README.md requirements

# Documentation Generation
docs:
	doxygen config/Doxyfile

# Format Code
format:
	find $(SRC_DIR) -name "*.c" -o -name "*.h" | xargs clang-format -i

# Hardware-in-the-Loop Tests
hil-test:
	@echo "Running HIL tests..."
	cd $(TEST_DIR)/hil && python3 run_hil_tests.py --config hil_config.yaml

# CAN Database Generation
can-gen:
	@echo "Generating CAN code from DBC..."
	cantools generate_c_source config/can_database.dbc \
		--output-dir $(SRC_DIR)/bsw/can_generated

# Help
help:
	@echo "BMS ECU Build System"
	@echo "===================="
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build ELF, BIN, and HEX files (default)"
	@echo "  test         - Run unit tests with coverage"
	@echo "  analyze      - Run static analysis (cppcheck)"
	@echo "  misra        - Check MISRA C compliance"
	@echo "  flash        - Flash firmware via OpenOCD"
	@echo "  flash-jlink  - Flash firmware via J-Link"
	@echo "  debug        - Start GDB debug session"
	@echo "  clean        - Remove build artifacts"
	@echo "  release      - Create release tarball"
	@echo "  docs         - Generate Doxygen documentation"
	@echo "  format       - Format code with clang-format"
	@echo "  hil-test     - Run Hardware-in-the-Loop tests"
	@echo "  can-gen      - Generate CAN code from DBC"
	@echo ""
	@echo "Build Configurations:"
	@echo "  make TARGET=native  - Build for host (testing)"
	@echo "  make TARGET=arm     - Build for ARM target (default)"
	@echo ""
	@echo "Examples:"
	@echo "  make clean all test     - Clean build and test"
	@echo "  make TARGET=arm flash   - Build and flash to hardware"

# Phony Targets
.PHONY: all test analyze misra flash flash-jlink debug clean distclean release docs format hil-test can-gen help size
