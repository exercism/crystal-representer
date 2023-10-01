#!/usr/bin/env bash

set -euo pipefail

echo "Building representator"
crystal build src/cli.cr --release -o bin/representer
