#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGEN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
JOBS="${JOBS:-16}"

module load PrgEnv-gnu
module load cmake
module load cray-hdf5
module load cray-netcdf

export BOOST_ROOT="$NGEN_ROOT/boost_1_86_0"
export UDUNITS2_ROOT="$NGEN_ROOT/deps/install"

# Required because some NGen targets don't currently inherit
# the UDUNITS include/library paths correctly.
export CPATH="$UDUNITS2_ROOT/include:${CPATH:-}"
export CPLUS_INCLUDE_PATH="$UDUNITS2_ROOT/include:${CPLUS_INCLUDE_PATH:-}"
export LIBRARY_PATH="$UDUNITS2_ROOT/lib:${LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="$UDUNITS2_ROOT/lib:${LD_LIBRARY_PATH:-}"

cd "$NGEN_ROOT"

git submodule update --init --recursive

cmake -S . -B build_real \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=cc \
    -DCMAKE_CXX_COMPILER=CC \
    -DCMAKE_Fortran_COMPILER=ftn \
    -DBOOST_ROOT="$BOOST_ROOT" \
    -DUDUNITS2_ROOT="$UDUNITS2_ROOT" \
    -DNGEN_WITH_MPI=ON \
    -DNGEN_WITH_NETCDF=ON \
    -DNGEN_WITH_SQLITE=ON \
    -DNGEN_WITH_UDUNITS=ON \
    -DNGEN_WITH_BMI_C=ON \
    -DNGEN_WITH_BMI_FORTRAN=ON \
    -DNGEN_WITH_PYTHON=OFF \
    -DNGEN_WITH_ROUTING=OFF \
    -DNGEN_WITH_TESTS=OFF \
    -DNGEN_WITH_EXTERN_NOAH_OWP_MODULAR=ON

cmake --build build_real --target ngen -- -j "$JOBS"

echo
echo "Build complete:"
"$NGEN_ROOT/build_real/ngen" --info
