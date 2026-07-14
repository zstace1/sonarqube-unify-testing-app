# Makefile for SDLC Metrics Demo - C Application

CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -I./src/c
TEST_CFLAGS = -Wall -Wextra -std=c11 -I.

# Source files
SRC_DIR = src/c
TEST_DIR = tests/c
BUILD_DIR = build
TEST_RESULTS_DIR = test-results

# Source and object files
SOURCES = $(SRC_DIR)/main.c $(SRC_DIR)/calculator.c
OBJECTS = $(BUILD_DIR)/main.o $(BUILD_DIR)/calculator.o
TEST_SOURCES = $(TEST_DIR)/test_calculator.c $(SRC_DIR)/calculator.c
TEST_OBJECTS = $(BUILD_DIR)/test_calculator.o $(BUILD_DIR)/calculator_test.o

# Output executables
MAIN_EXEC = $(BUILD_DIR)/calculator
TEST_EXEC = $(BUILD_DIR)/test_calculator

.PHONY: all clean test dirs

# Default target
all: dirs $(MAIN_EXEC)

# Create necessary directories
dirs:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(TEST_RESULTS_DIR)

# Build main application
$(MAIN_EXEC): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^

$(BUILD_DIR)/main.o: $(SRC_DIR)/main.c $(SRC_DIR)/calculator.h
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/calculator.o: $(SRC_DIR)/calculator.c $(SRC_DIR)/calculator.h
	$(CC) $(CFLAGS) -c $< -o $@

# Build and run tests
test: dirs $(TEST_EXEC)
	@echo "Running C unit tests..."
	./$(TEST_EXEC)

$(TEST_EXEC): $(TEST_DIR)/test_calculator.c $(SRC_DIR)/calculator.c
	$(CC) $(TEST_CFLAGS) -o $@ $^

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(TEST_RESULTS_DIR)
	@echo "Cleaned build and test directories"

# Run the calculator application
run: $(MAIN_EXEC)
	./$(MAIN_EXEC)

# Help target
help:
	@echo "SDLC Metrics Demo - C Application Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make all      - Build the calculator application (default)"
	@echo "  make test     - Build and run unit tests"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make run      - Run the calculator application"
	@echo "  make help     - Show this help message"
