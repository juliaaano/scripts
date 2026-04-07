#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <clusterresourcequota-name>"
  echo "Example: $0 tenant-user-6wqjq"
  exit 1
fi

QUOTA_NAME="$1"

# Verify the quota exists
if ! oc get clusterresourcequota "$QUOTA_NAME" &>/dev/null; then
  echo "Error: ClusterResourceQuota '$QUOTA_NAME' not found."
  exit 1
fi

# Print truncated raw output (header + total status only)
echo "=== Raw ClusterResourceQuota ==="
echo ""
YAML=$(oc get clusterresourcequota "$QUOTA_NAME" -o yaml)
echo "$YAML" | head -2
echo "  ... (truncated) ..."
echo "  total:"
echo "$YAML" | sed -n '/^  total:/,/^  [^ ]/p' | grep -v '^  [^ ]' | grep -v '^$'
echo ""

# Parse values from the YAML we already fetched (no extra API calls)
yaml_val() {
  echo "$YAML" | grep "^\s*$1:" | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/'
}

# Extract from hard: and used: sections separately
HARD_SECTION=$(echo "$YAML" | sed -n '/^    hard:/,/^    used:/p')
USED_SECTION=$(echo "$YAML" | sed -n '/^    used:/,/^  [^ ]/p')

yaml_hard() { echo "$HARD_SECTION" | grep "^\s*$1:" | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/'; }
yaml_used() { echo "$USED_SECTION" | grep "^\s*$1:" | head -1 | sed 's/.*: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/'; }

REQ_CPU_USED=$(yaml_used "requests.cpu")
REQ_CPU_HARD=$(yaml_hard "requests.cpu")
REQ_MEM_USED=$(yaml_used "requests.memory")
REQ_MEM_HARD=$(yaml_hard "requests.memory")
LIM_CPU_USED=$(yaml_used "limits.cpu")
LIM_CPU_HARD=$(yaml_hard "limits.cpu")
LIM_MEM_USED=$(yaml_used "limits.memory")
LIM_MEM_HARD=$(yaml_hard "limits.memory")

# Convert bytes to human-readable Gi (with ~ prefix)
bytes_to_gi() {
  local bytes=$1
  if [[ "$bytes" =~ ^[0-9]+$ ]]; then
    awk "BEGIN { printf \"~%.1f Gi\", $bytes / (1024*1024*1024) }"
  else
    echo "$bytes"
  fi
}

# Format CPU with comma separators (e.g., 18935m -> 18,935m)
format_cpu() {
  local val=$1
  if [[ "$val" =~ ^([0-9]+)m$ ]]; then
    local num="${BASH_REMATCH[1]}"
    local formatted
    formatted=$(printf "%'d" "$num")
    echo "${formatted}m"
  else
    echo "$val"
  fi
}

# Format quota limit (add "cores" suffix for plain numbers)
format_quota() {
  local val=$1
  if [[ "$val" =~ ^[0-9]+$ ]]; then
    echo "$val cores"
  else
    echo "$val"
  fi
}

# Format values
FMT_REQ_CPU_USED=$(format_cpu "$REQ_CPU_USED")
FMT_REQ_CPU_HARD=$(format_quota "$REQ_CPU_HARD")
FMT_REQ_MEM_USED=$(bytes_to_gi "$REQ_MEM_USED")
FMT_REQ_MEM_HARD=$(format_quota "$REQ_MEM_HARD")
FMT_LIM_CPU_USED=$(format_cpu "$LIM_CPU_USED")
FMT_LIM_CPU_HARD=$(format_quota "$LIM_CPU_HARD")
FMT_LIM_MEM_USED=$(bytes_to_gi "$LIM_MEM_USED")
FMT_LIM_MEM_HARD=$(format_quota "$LIM_MEM_HARD")

# Print table
echo "=== Quota Summary: $QUOTA_NAME ==="
echo ""
printf "┌─────────────────┬────────────┬────────────┐\n"
printf "│ %-15s │ %-10s │ %-10s │\n" "Resource" "Used" "Quota"
printf "├─────────────────┼────────────┼────────────┤\n"
printf "│ %-15s │ %-10s │ %-10s │\n" "requests.cpu" "$FMT_REQ_CPU_USED" "$FMT_REQ_CPU_HARD"
printf "├─────────────────┼────────────┼────────────┤\n"
printf "│ %-15s │ %-10s │ %-10s │\n" "requests.memory" "$FMT_REQ_MEM_USED" "$FMT_REQ_MEM_HARD"
printf "├─────────────────┼────────────┼────────────┤\n"
printf "│ %-15s │ %-10s │ %-10s │\n" "limits.cpu" "$FMT_LIM_CPU_USED" "$FMT_LIM_CPU_HARD"
printf "├─────────────────┼────────────┼────────────┤\n"
printf "│ %-15s │ %-10s │ %-10s │\n" "limits.memory" "$FMT_LIM_MEM_USED" "$FMT_LIM_MEM_HARD"
printf "└─────────────────┴────────────┴────────────┘\n"
