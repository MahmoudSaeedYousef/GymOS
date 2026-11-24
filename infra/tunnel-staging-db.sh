#!/usr/bin/env bash
#
# tunnel-staging-db.sh — Open an SSH local port-forward to the staging
# PostgreSQL database (gymos_dev) running on the VPS.
#
# Usage:
#   ./infra/tunnel-staging-db.sh
#
# Optional environment overrides:
#   VPS_HOST=145.239.199.125   VPS_USER=ubuntu
#   LOCAL_PORT=5435            REMOTE_DB_PORT=5432
#
# No passwords or secrets are stored here — SSH authentication uses your
# local SSH agent / key, or an interactive password prompt.
#

set -euo pipefail

VPS_HOST="${VPS_HOST:-145.239.199.125}"
VPS_USER="${VPS_USER:-ubuntu}"
LOCAL_PORT="${LOCAL_PORT:-5435}"
REMOTE_DB_PORT="${REMOTE_DB_PORT:-5432}"

TARGET="${VPS_USER}@${VPS_HOST}"

echo "Opening SSH tunnel: 127.0.0.1:${LOCAL_PORT} -> ${TARGET}:127.0.0.1:${REMOTE_DB_PORT}"
echo "Press Ctrl+C to close the tunnel."
echo
echo "While the tunnel is open, connect your IDE database client with:"
echo "  Host:     127.0.0.1"
echo "  Port:     ${LOCAL_PORT}"
echo "  Database: gymos_dev"
echo "  User / Password: your staging DB credentials (not stored in this script)"
echo

ssh -N -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_DB_PORT}" "${TARGET}"
