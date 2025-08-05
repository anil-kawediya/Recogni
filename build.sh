#!/bin/bash
# Convenience wrapper for build script
exec "$(dirname "$0")/scripts/build_vcs.sh" "$@"
