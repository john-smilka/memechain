#!/bin/bash
# Script to add and initialize git submodules with locked versions
set -e  # Exit immediately on error

# Add silkpre (commit 3322bb8)
echo "Adding silkpre (3322bb8)..."
git submodule add -f https://github.com/torquem-ch/silkpre.git deps/silkpre
(cd deps/silkpre && git checkout 3322bb8)

# Add evmone (v0.11.0)
echo "Adding evmone (v0.11.0)..."
git submodule add -f https://github.com/ethereum/evmone.git deps/evmone
(cd deps/evmone && git checkout v0.11.0)

# Add boost (boost-1.75.0)
echo "Adding boost (1.75.0)..."
git submodule add -f https://github.com/boostorg/boost.git deps/boost
(cd deps/boost && git fetch --tags && git checkout boost-1.75.0)

# Add cryptopp (CRYPTOPP_8_9_0)
echo "Adding cryptopp (8.9.0)..."
git submodule add -f https://github.com/weidai11/cryptopp.git deps/cryptopp
(cd deps/cryptopp && git fetch --tags && git checkout CRYPTOPP_8_9_0)

# Add gmp (v6.2.1)
echo "Adding gmp (6.2.1)..."
git submodule add -f https://gmplib.org/repo/gmp.git deps/gmp
(cd deps/gmp && git fetch --tags && git checkout v6.2.1)

# Add libfmt (7.1.3)
echo "Adding libfmt (7.1.3)..."
git submodule add -f https://github.com/fmtlib/fmt.git deps/libfmt
(cd deps/libfmt && git fetch --tags && git checkout 7.1.3)

# Add openssl (openssl-3.5.0)
echo "Adding openssl (3.5.0)..."
git submodule add -f https://github.com/openssl/openssl.git deps/openssl
(cd deps/openssl && git fetch --tags && git checkout openssl-3.5.0)

# Add protobuf (v3.21.9)
echo "Adding protobuf (3.21.9)..."
git submodule add -f https://github.com/protocolbuffers/protobuf.git deps/protobuf
(cd deps/protobuf && git fetch --tags && git checkout v3.21.9)

# Add rocksdb (v9.6.1)
echo "Adding rocksdb (9.6.1)..."
git submodule add -f https://github.com/facebook/rocksdb.git deps/rocksdb
(cd deps/rocksdb && git fetch --tags && git checkout v9.6.1)

# Add spdlog (v1.8.2)
echo "Adding spdlog (1.8.2)..."
git submodule add -f https://github.com/gabime/spdlog.git deps/spdlog
(cd deps/spdlog && git fetch --tags && git checkout v1.8.2)

# Initialize and recursively update all submodules
echo "Initializing and recursively updating all submodules..."
git submodule update --init --recursive

# Check submodule status
echo "Checking submodule status..."
git submodule status

echo "✅ All submodules added and initialized successfully!"
echo "Next steps:"
echo "1. git add .gitmodules deps/"
echo "2. git commit -m 'Add submodules with version locking'"