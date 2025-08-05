#!/bin/bash
# Convenience wrapper for cleanup script
exec "$(dirname "$0")/scripts/cleanup.sh" "$@"
