# Homepage Storage Statistics

This macOS helper writes total, used, and available filesystem capacity as a
small JSON document consumed by Homepage's `customapi` widget. It does not list
files or collect filenames.

Run it directly by supplying the storage and output paths:

```bash
STORAGE_PATH="$PWD/runtime" \
OUTPUT_FILE="$PWD/runtime/homepage/host-stats/storage.json" \
./scripts/storage-stats/update.sh
```

For periodic updates, copy the example launchd property list and replace its
three `__...__` placeholders with local absolute paths. Keep the customized
property list outside the repository if those paths identify the host or user.
