#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <firewall-id>"
    exit 1
fi

FIREWALL_ID="$1"
TEMP_FILE=$(mktemp)

# Ensure temp file is cleaned up on exit
trap 'rm -f "$TEMP_FILE"' EXIT

# Get current rules
if ! linode-cli firewalls rules-list "$FIREWALL_ID" --json > "$TEMP_FILE"; then
    echo "Failed to fetch current rules"
    exit 1
fi

# Open in editor
if [ -z "$EDITOR" ]; then
    EDITOR="nano"
fi
$EDITOR "$TEMP_FILE"

# Validate JSON
if ! jq empty "$TEMP_FILE" 2>/dev/null; then
    echo "Error: File contains invalid JSON"
    exit 1
fi

# Extract values from JSON
INBOUND=$(jq -c '.[0].inbound' "$TEMP_FILE")
OUTBOUND=$(jq -c '.[0].outbound' "$TEMP_FILE")
INBOUND_POLICY=$(jq -r '.[0].inbound_policy' "$TEMP_FILE")
OUTBOUND_POLICY=$(jq -r '.[0].outbound_policy' "$TEMP_FILE")

# Update rules with extracted values
if linode-cli firewalls rules-update \
    "$FIREWALL_ID" \
    --inbound "$INBOUND" \
    --outbound "$OUTBOUND" \
    --inbound_policy "$INBOUND_POLICY" \
    --outbound_policy "$OUTBOUND_POLICY"; then
    echo "Firewall rules updated successfully"
else
    echo "Failed to update firewall rules"
    exit 1
fi
