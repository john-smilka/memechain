#!/bin/sh

echo "-- start make depend:"

SHDIR=$(dirname `readlink -f $0`)
DEPS_DIR=$SHDIR/deps
BUILD_DEPS_DIR=$SHDIR/deps_build  

echo "project root: $SHDIR"
echo "prime deps: $DEPS_DIR"
echo "build root: $BUILD_DEPS_DIR"


echo "copy files..."
rsync -a --delete $DEPS_DIR/ $BUILD_DEPS_DIR/ || exit 1

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
        cd $PROTOBUF_DIR && mkdir -p build && cd build && cmake .. && make -j$COMPILE_NUM
fi

# boost
if [ ! -f "$BOOST_DIR/stage/lib/libboost_system.a" ]; then
	cd $BOOST_DIR && ./bootstrap.sh --prefix=$BOOST_DIR/stage && ./b2 -j$COMPILE_NUM --build-dir=$BOOST_DIR/build_tmp install
fi

# libfmt
if [ ! -f "$LIBFMT_DIR/libfmt.a" ]; then
    compile_and_move "libfmt" \
        cd $LIBFMT_DIR && rm -rf CMakeCache.txt && cmake -B . -S . -DCMAKE_POSITION_INDEPENDENT_CODE=ON && make -j$COMPILE_NUM
fi

# spdlog
if [ ! -f "$SPDLOG_DIR/libspdlog.a" ]; then
    compile_and_move "spdlog" \
        cd $SPDLOG_DIR && fmt_DIR=$LIBFMT_DIR cmake -DSPDLOG_FMT_EXTERNAL=yes . && make -j$COMPILE_NUM

fi


if [ ! -f "$SILKPRE_DIR/build/lib/libsilkpre-standalone.a" ]; then 
cd $SILKPRE_DIR
cp -f ../.././utils/silkpre/CMakeLists.txt ./CMakeLists.txt
cp -f ../.././utils/silkpre/lib/CMakeLists.txt ./lib/CMakeLists.txt

cd $SILKPRE_DIR && rm -rf build && cmake -S . -B build && cd build && make -j$COMPILE_NUM 
echo "silkpre compile" 
check_compile_result "silkpre" || exit 1
fi

# evmone
if [ ! -f "$EVMONE_DIR/build/lib64/libevmone-standalone.a" ]; then
        cd $EVMONE_DIR && rm -rf build && cmake -S . -B build -DBUILD_SHARED_LIBS=OFF && cd build && make -j$COMPILE_NUM
fi

# cryptopp
if [ ! -f "$CRYPTOPP_DIR/libcryptopp.a" ]; then
        cd $CRYPTOPP_DIR && make -j$COMPILE_NUM" 
fi

cd $SHDIR
echo "-- make depend done."