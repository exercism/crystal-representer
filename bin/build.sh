#!/usr/bin/env bash

set -euo pipefail

echo "Building representator"
crystal build src/representer.cr --release -o bin/representer
