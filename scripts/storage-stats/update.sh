#!/bin/zsh
set -eu

if [[ -z "${STORAGE_PATH:-}" || -z "${OUTPUT_FILE:-}" ]]; then
  print -u2 "STORAGE_PATH and OUTPUT_FILE are required"
  exit 2
fi

if [[ ! -d "$STORAGE_PATH" ]]; then
  print -u2 "Storage path does not exist: $STORAGE_PATH"
  exit 1
fi

output_directory="${OUTPUT_FILE:h}"
if [[ ! -d "$output_directory" ]]; then
  print -u2 "Output directory does not exist: $output_directory"
  exit 1
fi

temporary="$(mktemp "${OUTPUT_FILE}.XXXXXX")"
cleanup() {
  rm -f "$temporary"
}
trap cleanup EXIT

/bin/df -kP "$STORAGE_PATH" | /usr/bin/awk '
  NR == 2 {
    printf "{\"total\":%.0f,\"used\":%.0f,\"available\":%.0f}\n", $2 * 1024, $3 * 1024, $4 * 1024
  }
' > "$temporary"

chmod 644 "$temporary"
/bin/mv "$temporary" "$OUTPUT_FILE"
trap - EXIT
