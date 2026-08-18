#!/bin/bash
#
# Prints oc login commands for every resourceClaim referenced by a Workshop object.
# Requires: oc (already logged in), jq.

set -euo pipefail

usage() {
  echo "Usage: $0 <guid> [namespace]" >&2
  echo "Example: $0 nrvv2" >&2
  echo "Example: $0 nrvv2 a-different-namespace-name" >&2
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage
  exit 1
fi

GUID="$1"
NAMESPACE="${2:-user-jboeselm-redhat-com}"

if ! oc whoami &>/dev/null; then
  echo "Warning: not logged in to a cluster (oc whoami failed)." >&2
  exit 1
fi

if ! oc get project "$NAMESPACE" &>/dev/null; then
  echo "Warning: namespace '$NAMESPACE' not found on the current cluster (wrong cluster?)." >&2
  exit 1
fi

# The Workshop resource name is "<catalogItemName>-<guid>", not the guid alone.
ALL_WORKSHOPS=()
while IFS= read -r line; do
  [ -n "$line" ] && ALL_WORKSHOPS+=("$line")
done < <(
  oc get workshops -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null
)

# Quoting $GUID inside the case pattern matches it literally, so glob/regex
# metacharacters in the guid can't change which workshop is selected.
WORKSHOP_CANDIDATES=()
for NAME in "${ALL_WORKSHOPS[@]}"; do
  case "$NAME" in
    "$GUID" | *"-$GUID") WORKSHOP_CANDIDATES+=("$NAME") ;;
  esac
done

if [ "${#WORKSHOP_CANDIDATES[@]}" -eq 0 ]; then
  echo "Warning: no workshop matching guid '$GUID' found in namespace '$NAMESPACE'." >&2
  exit 1
elif [ "${#WORKSHOP_CANDIDATES[@]}" -gt 1 ]; then
  echo "Warning: multiple workshops matched guid '$GUID' in namespace '$NAMESPACE': ${WORKSHOP_CANDIDATES[*]}" >&2
  exit 1
fi

WORKSHOP_NAME="${WORKSHOP_CANDIDATES[0]}"

WORKSHOP_JSON=$(oc get workshop "$WORKSHOP_NAME" -n "$NAMESPACE" -o json 2>/dev/null) || {
  echo "Warning: workshop '$WORKSHOP_NAME' not found in namespace '$NAMESPACE'." >&2
  exit 1
}

# status.resourceClaims is an object keyed by resourceclaim name (some catalog
# items may instead use an array of names/objects, so tolerate both shapes).
CLAIM_NAMES=()
while IFS= read -r line; do
  [ -n "$line" ] && CLAIM_NAMES+=("$line")
done < <(
  jq -r '
    (.status.resourceClaims // {}) as $rc
    | if ($rc | type) == "object" then ($rc | keys[])
      elif ($rc | type) == "array" then
        ($rc[] | if type == "string" then . else (.name // .resourceName // empty) end)
      else empty
      end
  ' <<<"$WORKSHOP_JSON" | sort -u
)

if [ "${#CLAIM_NAMES[@]}" -eq 0 ]; then
  echo "Warning: no resourceClaims found in workshop '$GUID'." >&2
  exit 1
fi

for CLAIM in "${CLAIM_NAMES[@]}"; do
  CLAIM_JSON=$(oc get resourceclaim "$CLAIM" -n "$NAMESPACE" -o json 2>/dev/null) || {
    echo "Warning: resourceclaim '$CLAIM' not found in namespace '$NAMESPACE'." >&2
    continue
  }

  # Find the first object anywhere in the claim (e.g. status.summary.provision_data)
  # that carries all three login fields with actual (non-empty) values. jq treats ""
  # as truthy, so fields are checked against null and "" explicitly.
  IFS=$'\t' read -r URL USERNAME PASSWORD <<<"$(
    jq -r '
      def present: . != null and . != "";
      [.. | objects
        | select(.openshift_api_url? // "" | present)
        | select(.openshift_cluster_admin_username? // "" | present)
        | select(.openshift_cluster_admin_password? // "" | present)
      ][0] // {}
      | [.openshift_api_url, .openshift_cluster_admin_username, .openshift_cluster_admin_password]
      | map(. // "")
      | @tsv
    ' <<<"$CLAIM_JSON"
  )"

  if [ -z "$URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Warning: missing login details for resourceclaim '$CLAIM'." >&2
    continue
  fi

  echo "oc login --insecure-skip-tls-verify --server='$URL' --username='$USERNAME' --password='$PASSWORD'"
done
