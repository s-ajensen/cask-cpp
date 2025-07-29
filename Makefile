CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -g
INCLUDES = -Isrc -Ispec/lib
SYSTEM_INCLUDES = -isystem lib

SRC_DIR = src
SPEC_DIR = spec
BUILD_DIR = build
LIB_DIR = lib
DEPS_LOG = log/deps.log

SPEC_SOURCES = $(wildcard $(SPEC_DIR)/*_spec.cpp)
SPEC_OBJECTS = $(patsubst $(SPEC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SPEC_SOURCES))
SPEC_MAIN = $(BUILD_DIR)/test.o
TEST_RUNNER = $(BUILD_DIR)/run_tests

SOURCES = $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS = $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SOURCES))
MAIN = $(BUILD_DIR)/ttt

$(DEPS_LOG):
	@mkdir -p log
	@echo "Build started at $$(date)\n" > $(DEPS_LOG)

.PHONY: all
all: test

.PHONY: test
test: $(TEST_RUNNER)
	@echo "Running tests..."
	@./$(TEST_RUNNER)

$(TEST_RUNNER): $(SPEC_MAIN) $(SPEC_OBJECTS) $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS))
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(MAIN): $(OBJECTS)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(BUILD_DIR)/test.o: $(SPEC_DIR)/test.cpp $(SPEC_DIR)/lib/catch.hpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SYSTEM_INCLUDES) -c $< -o $@

$(BUILD_DIR)/%_spec.o: $(SPEC_DIR)/%_spec.cpp $(SPEC_DIR)/lib/bdd.hpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SYSTEM_INCLUDES) -c $< -o $@

$(BUILD_DIR)/main.o: $(SRC_DIR)/main.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SYSTEM_INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(SYSTEM_INCLUDES) -c $< -o $@

.PHONY: main
main: $(MAIN)

.PHONY: run
run: $(MAIN)
	@./$(MAIN) $(ARGS)

.PHONY: watch
watch:
	@echo "Watching for changes. Press Ctrl+C to stop."
	@while true; do \
		clear; \
		make test --no-print-directory; \
		fswatch -1 -r src spec --exclude build || true; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: clean_deps
clean_deps:
	rm -rf $(LIB_DIR)
	rm -rf $(SPEC_DIR)/$(LIB_DIR)
	rm -rf $(DEPS_LOG)

.PHONY: deps
deps: $(SPEC_DIR)/lib/catch.hpp $(SPEC_DIR)/lib/bdd.hpp $(LIB_DIR)/immer

$(SPEC_DIR)/lib/catch.hpp: $(DEPS_LOG)
	@echo "Installing Catch2..."
	@mkdir -p $(SPEC_DIR)/lib
	@curl -sL https://github.com/catchorg/Catch2/releases/download/v2.13.10/catch.hpp \
    		-o $@ >> $(DEPS_LOG) 2>&1

$(SPEC_DIR)/lib/bdd.hpp: $(DEPS_LOG)
	@echo "Installing c2_bdd..."
	@mkdir -p $(SPEC_DIR)/lib
	@curl -sL https://raw.githubusercontent.com/s-ajensen/c2_bdd/refs/heads/master/c2_bdd.hpp \
            -o $@ >> $(DEPS_LOG) 2>&1

$(LIB_DIR)/immer: $(DEPS_LOG)
	@echo "Installing immer..."
	@mkdir -p lib
	@rm -rf lib/immer-temp
	@cd lib && \
	git clone --depth 1 --branch v0.8.1 https://github.com/arximboldi/immer.git immer-temp \
    		>> ../$(DEPS_LOG) 2>&1 && \
	mv immer-temp/immer . && \
	rm -rf immer-temp

.PHONY: check
check:
	@$(CXX) $(CXXFLAGS) $(INCLUDES) $(SYSTEM_INCLUDES) -fsyntax-only $(SPEC_DIR)/*_spec.cpp

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make test       - Build and run tests (default)"
	@echo "  make watch      - Auto-run tests on file changes (fswatch)"
	@echo "  make check      - Quick syntax check"
	@echo "  make deps       - Download test dependencies"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make clean_deps - Remove installed dependencies"