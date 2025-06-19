#!/bin/bash
set -euxo pipefail

# Generate license information for all dependencies
echo "Collecting license information from Go modules..."
go-license-detector -f txt -o THIRD_PARTY_LICENSES.txt ./...

# Build and install the cobra-cli binary
# -ldflags="-s -w": Strip symbols and debug info for smaller binary
# -trimpath: Remove file system paths from binary for reproducibility
echo "Building cobra-cli..."
go install -ldflags="-s -w" -trimpath .

# Verify the installation worked
echo "Verifying cobra-cli installation..."
"${PREFIX}/bin/cobra-cli" --version

echo "Build completed successfully!"