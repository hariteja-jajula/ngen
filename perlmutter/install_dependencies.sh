#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGEN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
JOBS="${JOBS:-8}"

module load PrgEnv-gnu
module load cmake

cd "$NGEN_ROOT"

# Boost 1.86.0
if [[ ! -d "$NGEN_ROOT/boost_1_86_0" ]]; then
    curl -fL \
      -o boost_1_86_0.tar.bz2 \
      https://sourceforge.net/projects/boost/files/boost/1.86.0/boost_1_86_0.tar.bz2/download

    tar -xjf boost_1_86_0.tar.bz2
    rm boost_1_86_0.tar.bz2
fi

# UDUNITS2 2.2.28
mkdir -p "$NGEN_ROOT/deps"

if [[ ! -f "$NGEN_ROOT/deps/install/lib/libudunits2.so" ]]; then
    cd "$NGEN_ROOT/deps"

    curl -fL -O \
      https://downloads.unidata.ucar.edu/udunits/2.2.28/udunits-2.2.28.tar.gz

    tar -xzf udunits-2.2.28.tar.gz
    cd udunits-2.2.28

    ./configure \
      CC=cc \
      --prefix="$NGEN_ROOT/deps/install"

    make -j "$JOBS"
    make install
fi

echo "Dependencies ready."
echo "BOOST_ROOT=$NGEN_ROOT/boost_1_86_0"
echo "UDUNITS2_ROOT=$NGEN_ROOT/deps/install"
