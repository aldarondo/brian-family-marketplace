# jellyfin plugin

Discover and queue movies and TV shows for the Jellyfin library via the Jellyfin MCP server running on the NAS.

## Access

Charles only (`"access": "charles"` in marketplace.json).

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| New releases | `/new-releases` | Recent movies and TV from the past 30–90 days |
| Old releases | `/old-releases` | Acclaimed older content by genre and decade |

## MCP server

The plugin connects to `http://${NAS_IP}:8000/sse` — the `jellyfin-mcp` Docker container
defined in `jellyfin-automation/docker-compose.yml`.

Set `NAS_IP` in your `.env` (e.g. `192.168.1.x` or `nas.local`).

## Setup

1. Deploy the MCP container on the NAS:
   ```bash
   cd ~/Documents/GitHub/jellyfin-automation
   python deploy.py --update
   ```
2. Set `NAS_IP` in the brian-family-marketplace `.env`.
3. Ensure `RADARR_API_KEY`, `SONARR_API_KEY`, `TMDB_API_KEY`, `JELLYFIN_URL`,
   and `JELLYFIN_API_KEY` are set in the NAS `.env` (used by the container).
