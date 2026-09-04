#!/usr/bin/env bash
# Fetch the pinned Linux x64 Eigen-AVX2 KataGo package for a local build.
# The binary and models are deliberately not committed: they exceed GitHub's
# normal file-size limit. Their URLs and SHA-256 values live in the manifest.
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MANIFEST="$ROOT/packaging/katago-linux-x64.json"
DESTINATION="$ROOT/packaging/katago"
VERIFY_ONLY=false

case "${1:-}" in
    "") ;;
    --verify) VERIFY_ONLY=true ;;
    *) echo "usage: tools/setup_katago.sh [--verify]" >&2; exit 2 ;;
esac

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
    echo "KataGo setup supports only Linux x86_64 (Eigen-AVX2)." >&2
    exit 2
fi
for command in sha256sum python3; do
    command -v "$command" >/dev/null || {
        echo "KataGo setup requires '$command'." >&2; exit 2; }
done
if ! "$VERIFY_ONLY"; then
    for command in curl; do
        command -v "$command" >/dev/null || {
            echo "KataGo setup requires '$command'." >&2; exit 2; }
    done
fi

eval "$(python3 - "$MANIFEST" <<'PY'
import json
import shlex
import sys

with open(sys.argv[1]) as source:
    manifest = json.load(source)

binary = manifest["binary"]
print("BINARY_PATH=" + shlex.quote(binary["path"]))
print("BINARY_URL=" + shlex.quote(binary["archive_url"]))
print("BINARY_SHA=" + shlex.quote(binary["sha256"]))
for index, model in enumerate(manifest["models"]):
    print("MODEL_PATH_%d=" % index + shlex.quote(model["path"]))
    print("MODEL_URL_%d=" % index + shlex.quote(model["url"]))
    print("MODEL_SHA_%d=" % index + shlex.quote(model["sha256"]))
print("MODEL_COUNT=" + str(len(manifest["models"])))
PY
)"

verify_file() {
    local path="$1"
    local expected="$2"
    [ -f "$path" ] || return 1
    [ "$(sha256sum "$path" | awk '{print $1}')" = "$expected" ]
}

verify_package() {
    local missing=false
    if ! verify_file "$DESTINATION/${BINARY_PATH#katago/}" "$BINARY_SHA"; then
        echo "missing or invalid KataGo binary: $DESTINATION/${BINARY_PATH#katago/}" >&2
        missing=true
    fi
    for ((index = 0; index < MODEL_COUNT; index++)); do
        local path_variable="MODEL_PATH_$index"
        local sha_variable="MODEL_SHA_$index"
        local path="${!path_variable}"
        local sha="${!sha_variable}"
        if ! verify_file "$DESTINATION/${path#katago/}" "$sha"; then
            echo "missing or invalid KataGo model: $DESTINATION/${path#katago/}" >&2
            missing=true
        fi
    done
    ! "$missing"
}

if "$VERIFY_ONLY"; then
    verify_package && echo "KataGo package verified." && exit 0
    exit 1
fi

temporary="$(mktemp -d)"
cleanup() { rm -rf "$temporary"; }
trap cleanup EXIT

echo "Downloading KataGo Eigen-AVX2 binary…"
archive="$temporary/katago.zip"
curl --fail --location --retry 3 --output "$archive" "$BINARY_URL"
python3 - "$archive" "$temporary/extracted" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
source_binary="$(find "$temporary/extracted" -type f \( -path '*/bin/katago' -o -name katago \) -print -quit)"
if [ -z "$source_binary" ]; then
    echo "KataGo archive did not contain a katago binary." >&2
    exit 1
fi
if ! verify_file "$source_binary" "$BINARY_SHA"; then
    echo "KataGo archive failed checksum verification." >&2
    exit 1
fi

mkdir -p "$DESTINATION/bin"
install -m 755 "$source_binary" "$DESTINATION/bin/katago"

for ((index = 0; index < MODEL_COUNT; index++)); do
    path_variable="MODEL_PATH_$index"
    url_variable="MODEL_URL_$index"
    sha_variable="MODEL_SHA_$index"
    path="${!path_variable}"
    url="${!url_variable}"
    sha="${!sha_variable}"
    target="$DESTINATION/${path#katago/}"
    if verify_file "$target" "$sha"; then
        echo "Verified existing $(basename "$target")"
        continue
    fi
    echo "Downloading $(basename "$target")…"
    mkdir -p "$(dirname "$target")"
    curl --fail --location --retry 3 --output "$target.part" "$url"
    if ! verify_file "$target.part" "$sha"; then
        echo "Model failed checksum verification: $(basename "$target")" >&2
        rm -f "$target.part"
        exit 1
    fi
    mv "$target.part" "$target"
done

verify_package
echo "KataGo package installed and verified."
