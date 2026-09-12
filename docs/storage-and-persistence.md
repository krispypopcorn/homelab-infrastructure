# Storage and Persistence

The public templates separate source-controlled configuration from ignored
runtime data:

```text
config/                         publishable Homepage configuration
compose/                        publishable Compose definitions and examples
runtime/immich/library/         private photo/video data
runtime/immich/postgres/        private PostgreSQL files
runtime/homepage/host-stats/    generated capacity JSON
backups/                        private backup archives
```

Immich also uses a Docker named volume for its machine-learning model cache.
The cache can be repopulated; the PostgreSQL database and uploaded assets
require deliberate backup and restore planning.

Production paths may point to external storage rather than the example
`runtime/` directories. Those paths belong only in ignored `.env` files.

The storage-stat helper publishes capacity totals only. It does not enumerate
directories or filenames.
