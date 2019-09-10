# dashboard-terminal-cleanup [DEPRECATED]

This Docker 🐳Image is used by the [gardener/dashboard](https://github.com/gardener/dashboard) component to clean up service accounts created for the web terminal feature.

# Configuration
You can set the following environment variables:

| Name | Default | Description |
| ---- |---------| ------------|
| NO_HEARTBEAT_DELETE_SECONDS| 86400 | Deletes the service account after `x` seconds if no heartbeat was received within this timeframe |
