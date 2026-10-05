#!/usr/bin/env python3

from pathlib import Path
import argparse
import re

parser = argparse.ArgumentParser()
parser.add_argument("run_dir", help="Generated NGIAB run directory")
parser.add_argument("ngen_root", help="NGen repository root")
args = parser.parse_args()

run_dir = Path(args.run_dir).resolve()
ngen_root = Path(args.ngen_root).resolve()

src = run_dir / "config/realization.json"
dst = run_dir / "config/realization.perlmutter.json"

if not src.exists():
    raise SystemExit(f"Missing realization: {src}")

text = src.read_text()

replacements = {
    "/dmod/shared_libs/libslothmodel.so":
        ngen_root / "extern/sloth/cmake_build/libslothmodel.so",

    "/dmod/shared_libs/libsurfacebmi.so":
        ngen_root / "extern/noah-owp-modular/cmake_build/libsurfacebmi.so",

    "/dmod/shared_libs/libcfebmi.so.1.0.0":
        ngen_root / "extern/cfe/cmake_build/libcfebmi.so",
}

for old, new in replacements.items():
    text = text.replace(old, str(new))

dst.write_text(text)

parameter_dir = (
    ngen_root /
    "extern/noah-owp-modular/noah-owp-modular/parameters"
)

config_dir = run_dir / "config/cat_config/NOAH-OWP-M"

count = 0

for config in config_dir.glob("*.input"):

    text = config.read_text()

    # Use spaces/tabs rather than \s so we don't consume the newline.
    updated, replacements_made = re.subn(
        r'(?im)^[ \t]*parameter_dir[ \t]*=[ \t]*'
        r'[\'"][^\'"]*[\'"][ \t]*,?',
        f' parameter_dir = "{parameter_dir}/",',
        text,
    )

    if replacements_made:
        config.write_text(updated)
        count += 1

print(f"Created {dst}")
print(f"Updated Noah parameter_dir in {count} configurations")
