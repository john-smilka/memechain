#!/bin/sh

echo "-- start make depend:"

SHDIR=$(dirname `readlink -f $0`)
DEPS_DIR=$SHDIR/deps
BUILD_DEPS_DIR=$SHDIR/deps_build  

echo "project root: $SHDIR"
echo "prime deps: $DEPS_DIR"
echo "build root: $BUILD_DEPS_DIR"


#echo "copy files..."
#rsync -a --delete $DEPS_DIR/ $BUILD_DEPS_DIR/ || exit 1

OPENSSL_DIR=$BUILD_DEPS_DIR/openssl
ROCKSDB_DIR=$BUILD_DEPS_DIR/rocksdb
PROTOBUF_DIR=$BUILD_DEPS_DIR/protobuf
BOOST_DIR=$BUILD_DEPS_DIR/boost
LIBFMT_DIR=$BUILD_DEPS_DIR/libfmt
SPDLOG_DIR=$BUILD_DEPS_DIR/spdlog
EVMONE_DIR=$BUILD_DEPS_DIR/evmone
SILKPRE_DIR=$BUILD_DEPS_DIR/silkpre
CRYPTOPP_DIR=$BUILD_DEPS_DIR/cryptopp

COMPILE_NUM=`cat /proc/cpuinfo| grep "processor" | wc -l`;

check_compile_result() {
    if [ $? -eq 0 ]; then
        echo "$1 compile success"
        return 0
    else
        echo "$1 compile failed"
        return 1
    fi
}
# openssl
if [ ! -f "$OPENSSL_DIR/libcrypto.a" ]; 
then
        cd $OPENSSL_DIR && ./Configure && make -j$COMPILE_NUM 
fi

# rocksdb
if [ ! -f "$ROCKSDB_DIR/librocksdb.a" ]; then
        cd $ROCKSDB_DIR && make static_lib USE_RTTI=1 -j$COMPILE_NUM
fi


# protobuf
if [ ! -f "$PROTOBUF_DIR/build/libprotobuf.a" ]; then
        cd $PROTOBUF_DIR && mkdir -p build && cd build && cmake -Dprotobuf_BUILD_TESTS=OFF .. && make -j$COMPILE_NUM
fi

# libfmt
if [ ! -f "$LIBFMT_DIR/libfmt.a" ]; then
    compile_and_move "libfmt" \
        cd $LIBFMT_DIR && rm -rf CMakeCache.txt && cmake -B . -S . -DCMAKE_POSITION_INDEPENDENT_CODE=ON && make -j$COMPILE_NUM
fi

cd $SHDIR
echo "-- make depend done."
