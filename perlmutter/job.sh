#!/bin/bash
#SBATCH -A m888
#SBATCH -C cpu
#SBATCH -q regular
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 2
#SBATCH -t 00:10:00
#SBATCH -J ngen_1year
#SBATCH -o slurm-%j.out
#SBATCH -e slurm-%j.err

set -euo pipefail

module load PrgEnv-gnu
module load cray-hdf5
module load cray-netcdf

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGEN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKDIR="${WORKDIR:-$(dirname "$NGEN_ROOT")/ngen_1year}"
NGEN="$NGEN_ROOT/build_real/ngen"

export UDUNITS2_ROOT="$NGEN_ROOT/deps/install"
export LD_LIBRARY_PATH="$UDUNITS2_ROOT/lib:${LD_LIBRARY_PATH:-}"
export OMP_NUM_THREADS=1

cd "$WORKDIR"

RUN_DIR="$WORKDIR/runs/$SLURM_JOB_ID"
mkdir -p "$RUN_DIR"

echo "========================================"
echo "NGen 1-year baseline"
echo "Job ID:      $SLURM_JOB_ID"
echo "Node:        $SLURMD_NODENAME"
echo "Start time:  $(date)"
echo "Working dir: $WORKDIR"
echo "========================================"

srun -n 1 -c 2 --cpu-bind=cores \
    /usr/bin/time -v -o "$RUN_DIR/timing.txt" \
    "$NGEN" \
    ./config/ngen_1year_subset.gpkg \
    all \
    ./config/ngen_1year_subset.gpkg \
    all \
    ./config/realization.perlmutter.json \
    > "$RUN_DIR/ngen.out" \
    2> "$RUN_DIR/ngen.err"

echo
echo "--- NGen timing ---"

grep -E \
    'Finished|NGen::init|NGen::simulation' \
    "$RUN_DIR/ngen.out" || true

echo
echo "--- System timing ---"

grep -E \
    'User time|System time|Percent of CPU|Elapsed|Maximum resident|File system inputs|File system outputs|Exit status' \
    "$RUN_DIR/timing.txt" || true

echo
echo "--- Warning count ---"

grep -c '^WARN:' "$RUN_DIR/ngen.err" || true

echo
echo "Results: $RUN_DIR"
