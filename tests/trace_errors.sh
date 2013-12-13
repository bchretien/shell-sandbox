#!/bin/bash

# Run wrong command
echo "Running wrong command..."
thisshoulddefinitelyfail

echo
echo "Running wrong command with traces enabled..."

# Enable verbose traces
source ../src/utils/verbose-set-e-combo-ideal.sh

# Run the wrong command again
thisshoulddefinitelyfail
