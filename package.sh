#!/usr/bin/env bash
set -euo pipefail

ADDON_DIR="oGlowClassic"
BUILD_DIR="${BUILD_DIR:-dist}"
DEFAULT_VARIANTS=(era tbc mop forever)

declare -A INTERFACE_FOR_VARIANT=(
  [era]=11509
  [tbc]=20506
  [mop]=50504
  [forever]=16001
)

declare -A CLIENT_VERSION_FOR_VARIANT=(
  [era]=1.15.9
  [tbc]=2.5.6
  [mop]=5.5.4
  [forever]=1.60.1
)

version=$(awk -F': *' '/^## Version:/ {print $2; exit}' "$ADDON_DIR/oGlowClassic.toc")
version=${version:-dev}

variants=("$@")
if [ "${#variants[@]}" -eq 0 ]; then
  variants=("${DEFAULT_VARIANTS[@]}")
fi

mkdir -p "$BUILD_DIR"

for variant in "${variants[@]}"; do
  interface="${INTERFACE_FOR_VARIANT[$variant]:-}"
  client_version="${CLIENT_VERSION_FOR_VARIANT[$variant]:-}"
  if [ -z "$interface" ] || [ -z "$client_version" ]; then
    echo "Unknown variant \"$variant\". Known variants: era tbc mop forever" >&2
    exit 1
  fi

  stage=$(mktemp -d "$BUILD_DIR/.stage-${variant}.XXXXXX")
  zip_path="$BUILD_DIR/oGlowClassic-${version}-${variant}.zip"
  trap 'rm -rf "$stage"' EXIT

  cp -a "$ADDON_DIR" "$stage/"

  toc_path="$stage/$ADDON_DIR/oGlowClassic.toc"
  python3 - "$toc_path" "$interface" <<'PYTHON'
import sys

toc_path, target_interface = sys.argv[1:]
lines = open(toc_path, encoding="utf-8").read().splitlines()
for index, line in enumerate(lines):
    if line.startswith("## Interface:"):
        lines[index] = f"## Interface: {target_interface}"
        break
else:
    sys.exit("Interface line not found in TOC")

with open(toc_path, "w", encoding="utf-8", newline="\n") as toc_file:
    toc_file.write("\n".join(lines) + "\n")
PYTHON

  rm -f "$zip_path"
  python3 - "$stage" "$zip_path" "$ADDON_DIR" "$interface" <<'PYTHON'
import os
import sys
import zipfile

stage, zip_path, addon_dir, target_interface = sys.argv[1:]
source_dir = os.path.join(stage, addon_dir)

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for root, directories, files in os.walk(source_dir):
        directories.sort()
        for name in sorted(files):
            full_path = os.path.join(root, name)
            archive.write(full_path, os.path.relpath(full_path, stage))

with zipfile.ZipFile(zip_path) as archive:
    invalid_member = archive.testzip()
    if invalid_member:
        sys.exit(f"ZIP integrity check failed for {invalid_member}")

    names = archive.namelist()
    if len(names) != len(set(names)):
        sys.exit("ZIP contains duplicate entries")
    if not names or any(not name.startswith(addon_dir + "/") for name in names):
        sys.exit("ZIP must contain exactly one top-level addon directory")

    toc_name = f"{addon_dir}/{addon_dir}.toc"
    if toc_name not in names:
        sys.exit("ZIP does not contain the addon TOC")
    toc = archive.read(toc_name).decode("utf-8")
    interface_lines = [line for line in toc.splitlines() if line.startswith("## Interface:")]
    if interface_lines != [f"## Interface: {target_interface}"]:
        sys.exit("ZIP TOC does not contain exactly the requested Interface value")
PYTHON

  rm -rf "$stage"
  trap - EXIT
  echo "Built $zip_path (WoW $client_version, Interface $interface, addon version $version)"
done
