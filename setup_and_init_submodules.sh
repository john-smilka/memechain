#!/bin/bash
set -e

LOG_FILE="submodule_setup.log"
ERROR_LOG_FILE="submodule_setup_errors.log"
PROGRESS_FILE="submodule_setup_progress.txt"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" "$ERROR_LOG_FILE"
}


gitmodules_cleanup() {
    if [ -f .gitmodules ]; then
        sed -i '/submodule  \.\.\/deps\//,/^$/d' .gitmodules
    fi
    for mod in boost cryptopp evmone libfmt openssl protobuf rocksdb silkpre spdlog gmp; do
        git config -f .git/config --remove-section "submodule../deps/$mod" 2>/dev/null || true
    done
}
gitmodules_cleanup


if [ ! -f .gitmodules ]; then
    touch .gitmodules
    git add .gitmodules
fi

clean_submodule() {
    local path=$1
    if [ -f .gitmodules ] && grep -q "$path" .gitmodules; then
        git config -f .gitmodules --remove-section "submodule.$path" 2>/dev/null || true
        sed -i "/submodule \"$path\"/,/^$/d" .gitmodules || true
    fi
    git config --remove-section "submodule.$path" 2>/dev/null || true
    rm -rf ".git/modules/$path" 2>/dev/null || true
    rm -rf "$path" 2>/dev/null || true
}

add_submodule() {
    local name=$1
    local url=$2
    local version=$3
    local path=$4

    echo "Processing $name ($version)..."
    
    if [ -d "$path" ]; then
        cd "$path"
        git fetch --all
        git fetch --tags
        if git rev-parse --verify "$version" >/dev/null 2>&1 && [ "$(git rev-parse HEAD)" = "$(git rev-parse $version)" ]; then
            echo "$name already at $version, skipping add"
            cd - >/dev/null
            return 0
        fi
        cd - >/dev/null
    fi

    clean_submodule "$path"

    if ! git submodule add -f "$url" "$path"; then
        echo "Failed to add $name submodule"
        return 1
    fi
    git add .gitmodules 2>/dev/null || true

   
    if ! (cd "$path" && git fetch --all && git fetch --tags && git checkout "$version"); then
        echo "Cannot checkout $name version $version"
        return 1
    fi

    git add "$path"
    echo "$name added and checked out to $version successfully"
    return 0
}


add_submodule "silkpre"   "https://github.com/MeMeChainLab/silkpre-mmc.git"         "cb29435"         "deps/silkpre"
add_submodule "evmone"    "https://github.com/ethereum/evmone.git"                  "v0.11.0"         "deps/evmone"
add_submodule "boost"     "https://github.com/boostorg/boost.git"                   "boost-1.75.0"    "deps/boost"
add_submodule "cryptopp"  "https://github.com/weidai11/cryptopp.git"                "CRYPTOPP_8_9_0"  "deps/cryptopp"
add_submodule "libfmt"    "https://github.com/fmtlib/fmt.git"                       "7.1.3"           "deps/libfmt"
add_submodule "openssl"   "https://github.com/openssl/openssl.git"                  "openssl-3.0.5"   "deps/openssl"
add_submodule "protobuf"  "https://github.com/protocolbuffers/protobuf.git"         "v3.21.9"         "deps/protobuf"
add_submodule "rocksdb"   "https://github.com/facebook/rocksdb.git"                 "v9.6.1"          "deps/rocksdb"
add_submodule "spdlog"   "https://github.com/gabime/spdlog.git"                    "v1.8.2"           "deps/spdlog"

log_message "Starting to update all submodules..."
if ! git submodule update --init --recursive; then
    log_error "Failed to update submodules"
    exit 1
fi
log_message "All submodules setup and initialization completed successfully"