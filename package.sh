#!/usr/bin/env bash
set -euo pipefail

ADDON_DIR="oGlowClassic"
BUILD_DIR="${BUILD_DIR:-dist}"
DEFAULT_VARIANTS=(era mop)

declare -A INTERFACE_FOR_VARIANT=(
  [era]=11508
  [mop]=50502
)

version=$(awk -F': *' '/^## Version:/ {print $2; exit}' "$ADDON_DIR/oGlowClassic.toc")
version=${version//$'\r'/}
version=${version:-dev}

variants=("$@")
if [ "${#variants[@]}" -eq 0 ]; then
  variants=("${DEFAULT_VARIANTS[@]}")
fi

mkdir -p "$BUILD_DIR"

for variant in "${variants[@]}"; do
  interface="${INTERFACE_FOR_VARIANT[$variant]:-}"
  if [ -z "${interface:-}" ]; then
    echo "Unknown variant \"$variant\". Known variants: ${!INTERFACE_FOR_VARIANT[*]}" >&2
    exit 1
  fi

  iface_str="${interface}"
  if [ "${#iface_str}" -eq 5 ]; then
    major=${iface_str:0:1}
    minor=$((10#${iface_str:1:2}))
    patch=$((10#${iface_str:3:2}))
    interface_version="${major}.${minor}.${patch}"
  else
    interface_version="${interface}"
  fi

  stage="$BUILD_DIR/stage-$variant"
  rm -rf "$stage"
  mkdir -p "$stage"
  cp -a "$ADDON_DIR" "$stage/"

  toc_path="$stage/$ADDON_DIR/oGlowClassic.toc"
  python3 - "$toc_path" "$interface" <<'PY'
import sys

toc_path, target_interface = sys.argv[1:]

lines = open(toc_path, encoding="utf-8").read().splitlines()
for idx, line in enumerate(lines):
    if line.startswith("## Interface:"):
        lines[idx] = f"## Interface: {target_interface}"
        break
else:
    sys.exit("Interface line not found in TOC")

with open(toc_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
PY

  zip_name="$BUILD_DIR/oGlowClassic-${interface_version}.zip"

  if command -v zip >/dev/null 2>&1; then
    (
      cd "$stage" >/dev/null
      zip -qr "../$(basename "$zip_name")" "$ADDON_DIR"
    )
  else
    python3 - "$stage" "$zip_name" <<'PY'
import os
import sys
import zipfile

stage, zip_path = sys.argv[1:]
stage = os.path.abspath(stage)
zip_path = os.path.abspath(zip_path)

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(stage):
        for name in files:
            full_path = os.path.join(root, name)
            # Preserve the addon folder as the top-level entry.
            rel_path = os.path.relpath(full_path, stage)
            zf.write(full_path, arcname=rel_path)
PY
  fi

  rm -rf "$stage"
  echo "Built $zip_name (Interface $interface, addon version $version)"
done
