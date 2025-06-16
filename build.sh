#!/bin/bash

# Set log file environment variable
export LOGFILE="$(pwd)/build.log"

# Function to log messages to both console and log file
log_message() {
    echo "$1" | tee -a "$LOGFILE"
}

# Initialize log file
: > "$LOGFILE"
log_message "Starting build process at $(date)"

# Check if cmake is installed and version is >= 3.15.0
log_message "Checking cmake installation and version..."
if ! command -v cmake &> /dev/null; then
    log_message "Error: cmake is not installed. Please install cmake version 3.15.0 or higher."
    exit 1
fi

CMAKE_VERSION=$(cmake --version | head -n1 | cut -d" " -f3)
CMAKE_MAJOR=$(echo "$CMAKE_VERSION" | cut -d. -f1)
CMAKE_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f2)
CMAKE_PATCH=$(echo "$CMAKE_VERSION" | cut -d. -f3)

if [ "$CMAKE_MAJOR" -lt 3 ] || { [ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 15 ]; }; then
    log_message "Error: cmake version $CMAKE_VERSION is too old. Required version is 3.15.0 or higher."
    exit 1
fi
log_message "Found cmake version $CMAKE_VERSION"

# Check if git is installed and version is >= 2.0.0
log_message "Checking git installation and version..."
ISGIT=0
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d" " -f3)
    GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
    GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)
    
    if [ "$GIT_MAJOR" -gt 2 ] || { [ "$GIT_MAJOR" -eq 2 ] && [ "$GIT_MINOR" -ge 0 ]; }; then
        ISGIT=1
        log_message "Found git version $GIT_VERSION"
    else
        log_message "Warning: git version $GIT_VERSION is too old. Required version is 2.0.0 or higher."
    fi
else
    log_message "Warning: git is not installed."
fi

# Execute appropriate script based on ISGIT value
log_message "Executing dependency setup based on git availability..."
if [ "$ISGIT" -eq 0 ]; then
    log_message "Running make_dep_build.sh as git is not available or version is too old"
    if [ -f "./dep_build/make_dep_build.sh" ]; then
        bash ./dep_build/make_dep_build.sh 2>&1 | tee -a "$LOGFILE"
        if [ $? -ne 0 ]; then
            log_message "Error: make_dep_build.sh failed"
            exit 1
        fi
    else
        log_message "Error: make_dep_build.sh not found in dep_build directory"
        exit 1
    fi
else
    log_message "Running setup_and_init_submodules.sh as git is available"
    if [ -f "./setup_and_init_submodules.sh" ]; then
        bash ./setup_and_init_submodules.sh 2>&1 | tee -a "$LOGFILE"
        if [ $? -ne 0 ]; then
            log_message "Error: setup_and_init_submodules.sh failed"
            exit 1
        fi
    else
        log_message "Error: setup_and_init_submodules.sh not found"
        exit 1
    fi
fi

# Create build directory and run cmake
log_message "Creating build directory and running cmake..."
mkdir -p build
cd build || { log_message "Error: Failed to change to build directory"; exit 1; }
cmake .. 2>&1 | tee -a "$LOGFILE"
if [ $? -ne 0 ]; then
    log_message "Error: cmake configuration failed"
    exit 1
fi

log_message "Build setup completed successfully at $(date)"