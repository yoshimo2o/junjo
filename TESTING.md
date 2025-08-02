# Testing Guide

This document explains how to run and write tests for the junjo project.

## Prerequisites

### Install Bats (Bash Automated Testing System)

**macOS (using Homebrew):**
```bash
brew install bats-core
```

**Ubuntu/Debian:**
```bash
sudo apt-get install bats
```

**Manual Installation:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run All Tests
```bash
# From project root
bats tests/

# Or run specific test files
bats tests/parser_file.bats
bats tests/parser_timestamp.bats
```

### Run Tests with Verbose Output
```bash
# Show detailed output for each test
bats -t tests/

# Or for a specific file
bats -t tests/parser_file.bats
```

### Run Specific Tests
```bash
# Run tests matching a pattern
bats tests/parser_file.bats -f "duplicate marker"

# Run a single test by name
bats tests/parser_file.bats -f "parse simple JPG file"
```

### Watch Mode (Continuous Testing)
```bash
# Install entr for file watching
brew install entr  # macOS
sudo apt-get install entr  # Ubuntu

# Watch for changes and auto-run tests
find lib/ tests/ -name "*.sh" -o -name "*.bats" | entr -c bats tests/
```

## Test Structure

### Test Files Organization
```
tests/
├── parser_file.bats           # File parsing component tests
├── parser_timestamp.bats      # Timestamp parsing tests
└── ...                        # Additional test files
```

### Test File Format
Each `.bats` file follows this structure:

```bash
#!/usr/bin/env bats

# Load required libraries
load '../lib/configs.sh'
load '../lib/parser_file.sh'

@test "descriptive test name" {
  # Setup
  local var1 var2 var3

  # Execute
  function_under_test "input" var1 var2 var3

  # Assert
  [ "$var1" = "expected_value" ]
  [ "$var2" = "expected_value" ]
}
```

## Current Test Coverage

### `parser_file.bats` - File Path Component Parsing
Tests the `get_media_file_path_components` function:

#### Basic Functionality
- ✅ Simple extensions (`.JPG`, `.MP4`)
- ✅ Compound extensions (`.HEIC.MOV`, `.JPG.MP4`)
- ✅ Case preservation in extensions

#### Duplicate Marker Detection
- ✅ Detects automatic duplicate suffixes: `(1)`, `(2)`, `(15)`
- ✅ Preserves intentional numbering: `(01)`, `(009)`, `(0)`
- ✅ Handles spaces around markers: `IMG 1234 (1).jpg`

#### Path Handling
- ✅ Current directory: `./file.jpg`
- ✅ Relative paths: `photos/file.jpg`
- ✅ Absolute paths: `/full/path/file.jpg`
- ✅ Nested paths: `./2023/vacation/file.jpg`

#### Edge Cases
- ✅ Files with spaces in names
- ✅ Mixed case extensions
- ✅ Double-digit duplicate markers

### `parser_timestamp.bats` - Timestamp Parsing
Tests timestamp normalization and conversion functions.

## Writing New Tests

### Best Practices

1. **Descriptive Test Names**
   ```bash
   @test "parse compound extension with duplicate marker"
   # Good: Clear what's being tested

   @test "test function"
   # Bad: Not descriptive
   ```

2. **Test One Thing at a Time**
   ```bash
   @test "detect duplicate marker" {
     # Focus on just duplicate marker detection
   }

   @test "preserve case in extensions" {
     # Focus on just case preservation
   }
   ```

3. **Use Clear Assertions**
   ```bash
   [ "$result" = "expected" ]              # String equality
   [ "$status" -eq 0 ]                     # Exit status
   [[ "$result" =~ pattern ]]              # Regex match
   [ -f "$file" ]                          # File exists
   ```

4. **Test Edge Cases**
   - Empty inputs
   - Special characters
   - Boundary conditions
   - Error conditions

### Adding Tests for New Functions

1. **Create or update test file:**
   ```bash
   # For new library file lib/new_feature.sh
   touch tests/new_feature.bats
   ```

2. **Load required libraries:**
   ```bash
   #!/usr/bin/env bats

   load '../lib/configs.sh'
   load '../lib/new_feature.sh'
   ```

3. **Write comprehensive tests:**
   ```bash
   @test "function handles normal input" {
     # Test happy path
   }

   @test "function handles edge cases" {
     # Test boundary conditions
   }

   @test "function handles errors gracefully" {
     # Test error conditions
   }
   ```

## Debugging Tests

### View Test Output
```bash
# Run with verbose output to see what failed
bats -t tests/parser_file.bats

# Add debug output to tests
@test "my test" {
  echo "Debug: variable value is $variable" >&3
  [ "$variable" = "expected" ]
}
```

### Common Test Failures

1. **Variable Not Set**
   ```bash
   # Error: variable not found
   [ "$undefined_var" = "value" ]

   # Fix: Check variable is set
   [ -n "$variable" ]
   [ "$variable" = "value" ]
   ```

2. **Path Issues**
   ```bash
   # Error: library not found
   load '../lib/missing.sh'

   # Fix: Check path from test file location
   load '../lib/existing.sh'
   ```

3. **Function Not Available**
   ```bash
   # Error: function not found
   my_function "input"

   # Fix: Ensure library is loaded
   load '../lib/library_with_function.sh'
   ```

## Continuous Integration

For automated testing in CI/CD:

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Bats
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          sudo ./install.sh /usr/local
      - name: Run Tests
        run: bats tests/
```

## Coverage Goals

- [ ] All public functions have tests
- [ ] Critical paths are tested
- [ ] Edge cases are covered
- [ ] Error conditions are handled
- [ ] Integration tests for main workflows

Run `bats tests/` to execute all tests and ensure everything works correctly!
