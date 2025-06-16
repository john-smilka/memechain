#!/bin/bash

# Check if unzip command is available
if ! command -v unzip &> /dev/null; then
    echo "unzip command not found. Exiting."
    exit 1
fi

# Set log file environment variable
export LOGFILE="$(pwd)/3rd_download.log"

# Function to log messages to both console and log file
log_message() {
    echo "$1" | tee -a "$LOGFILE"
}

# Create log file if it doesn't exist
touch "$LOGFILE"

# Define target directory for extraction
DEPS_BUILD_DIR="$(pwd)/../deps_build"

# Create deps_build directory if it doesn't exist
mkdir -p "$DEPS_BUILD_DIR"

# Function to download and extract file
download_and_extract() {
    local url=$1
    local filename=$2
    local extract_dir=$3

    # Check if file already exists
    if [ -f "$filename" ]; then
        log_message "File $filename already exists, skipping download."
        return 0
    fi

    # Download file using curl
    log_message "Downloading $filename from $url..."
    if curl -L -o "$filename" "$url"; then
        log_message "Download successful: $filename"
        
        # Extract file to specified directory
        log_message "Extracting $filename to $extract_dir..."
        mkdir -p "$extract_dir"
        if [[ "$filename" == *.tar.gz ]]; then
            tar -xzf "$filename" -C "$extract_dir"
        elif [[ "$filename" == *.tar.xz ]]; then
            tar -xJf "$filename" -C "$extract_dir"
        elif [[ "$filename" == *.zip ]]; then
            unzip -q "$filename" -d "$extract_dir"
        fi
        log_message "Extraction completed for $filename"
    else
        log_message "Download failed for $filename"
        rm -f "$filename"
        return 1
    fi
}

# Download and extract evmone v0.11.0
download_and_extract "https://github.com/ethereum/evmone/releases/download/v0.11.0/evmone-0.11.0-linux-x86_64.tar.gz" \
    "evmone-0.11.0-linux-x86_64.tar.gz" "$DEPS_BUILD_DIR/evmone"

# Download and extract silkpre commit 3322bb898ac9528fc2cf9a8df1e48360420d0c1a
download_and_extract "https://github.com/torquem-ch/silkpre/archive/3322bb898ac9528fc2cf9a8df1e48360420d0c1a.tar.gz" \
    "silkpre-3322bb898ac9528fc2cf9a8df1e48360420d0c1a.tar.gz" "$DEPS_BUILD_DIR/silkpre"

# Download and extract boost v1.75.0
download_and_extract "https://github.com/boostorg/boost/archive/refs/tags/boost-1.75.0.tar.gz" \
    "boost-1.75.0.tar.gz" "$DEPS_BUILD_DIR/boost"

# Download and extract cryptopp v8.9
download_and_extract "https://github.com/weidai11/cryptopp/releases/download/CRYPTOPP_8_9_0/cryptopp890.zip" \
    "cryptopp890.zip" "$DEPS_BUILD_DIR/cryptopp"

# Download and extract gmp v6.2.1
download_and_extract "https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz" \
    "gmp-6.2.1.tar.xz" "$DEPS_BUILD_DIR/gmp"

# Download and extract libfmt v7.1.3
download_and_extract "https://github.com/fmtlib/fmt/releases/download/7.1.3/fmt-7.1.3.zip" \
    "fmt-7.1.3.zip" "$DEPS_BUILD_DIR/fmt"

# Download and extract openssl v3.5.0
download_and_extract "https://github.com/openssl/openssl/releases/download/openssl-3.5.0/openssl-3.5.0.tar.gz" \
    "openssl-3.5.0.tar.gz" "$DEPS_BUILD_DIR/openssl"

# Download and extract protobuf v3.21.9
download_and_extract "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.21.9.zip" \
    "protobuf-3.21.9.zip" "$DEPS_BUILD_DIR/protobuf"

# Download and extract rocksdb v9.6.1
download_and_extract "https://github.com/facebook/rocksdb/archive/refs/tags/v9.6.1.zip" \
    "rocksdb-9.6.1.zip" "$DEPS_BUILD_DIR/rocksdb"

# Download and extract spdlog v1.8.2
download_and_extract "https://github.com/gabime/spdlog/archive/refs/tags/v1.8.2.zip" \
    "spdlog-1.8.2.zip" "$DEPS_BUILD_DIR/spdlog"

# Completion message
log_message "All downloads and extractions completed."