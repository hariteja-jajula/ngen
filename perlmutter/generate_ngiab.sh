#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGEN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_ROOT="${OUTPUT_ROOT:-$(dirname "$NGEN_ROOT")}"

GAGE="${GAGE:-10154200}"
START="${START:-2022-01-01}"
END="${END:-2023-01-01}"
RUN_NAME="${RUN_NAME:-ngen_1year}"

if [[ -z "${PSCRATCH:-}" ]]; then
    echo "PSCRATCH is not defined."
    exit 1
fi

# uv and SQLite-backed NGIAB files should not live on NERSC Global Home/DVS.
export UV_CACHE_DIR="$PSCRATCH/.uv-cache"
export UV_TOOL_DIR="$PSCRATCH/.uv-tools"
export UV_TOOL_BIN_DIR="$PSCRATCH/.uv-bin"

mkdir -p \
    "$UV_CACHE_DIR" \
    "$UV_TOOL_DIR" \
    "$UV_TOOL_BIN_DIR"

# NGIAB currently stores the CONUS hydrofabric under ~/.ngiab.
# Give the process a scratch-backed HOME so the SQLite GeoPackage
# is not placed on Global Home/DVS.
NGIAB_HOME="$PSCRATCH/ngiab-home"
mkdir -p "$NGIAB_HOME"

UVX="$(command -v uvx || true)"

if [[ -z "$UVX" ]]; then
    echo "uvx not found."
    echo "Install uv first:"
    echo 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    exit 1
fi

echo "Generating NGIAB workload:"
echo "  gage:        $GAGE"
echo "  start:       $START"
echo "  end:         $END"
echo "  output:      $OUTPUT_ROOT/$RUN_NAME"

HOME="$NGIAB_HOME" \
UV_CACHE_DIR="$UV_CACHE_DIR" \
UV_TOOL_DIR="$UV_TOOL_DIR" \
UV_TOOL_BIN_DIR="$UV_TOOL_BIN_DIR" \
"$UVX" ngiab-prep \
    -i "gage-${GAGE}" \
    -sfr \
    --start "$START" \
    --end "$END" \
    --output_root "$OUTPUT_ROOT" \
    -o "$RUN_NAME"

python "$SCRIPT_DIR/patch_ngiab_run.py" \
    "$OUTPUT_ROOT/$RUN_NAME" \
    "$NGEN_ROOT"

echo
echo "NGIAB workload ready:"
echo "$OUTPUT_ROOT/$RUN_NAME"
