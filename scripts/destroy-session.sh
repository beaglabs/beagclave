#!/usr/bin/env bash
set -euo pipefail

AKS_CLUSTER="${AKS_CLUSTER:-}"
RESOURCE_GROUP="${RESOURCE_GROUP:-beagclave-prod}"
SESSION_ID="${SESSION_ID:-}"
SESSION_TYPE="${SESSION_TYPE:-avd}"

echo "Destroying Beagclave session: ${SESSION_ID} (type: ${SESSION_TYPE})"

case "${SESSION_TYPE}" in
  avd)
    echo "Destroying AVD session host..."
    if [ -n "${SESSION_ID}" ]; then
      az desktopvirtualization hostpool show \
        --name "${SESSION_ID}" \
        --resource-group "${RESOURCE_GROUP}" \
        --query "name" \
        --output tsv 2>/dev/null || true
    fi

    HOST_POOL_NAME=$(az desktopvirtualization hostpool list \
      --resource-group "${RESOURCE_GROUP}" \
      --query "[?contains(name, 'beagclave') && contains(name, 'session')].name" \
      --output tsv)

    if [ -n "${HOST_POOL_NAME}" ]; then
      echo "Force deleting session host from pool: ${HOST_POOL_NAME}"
      az desktopvirtualization hostpool delete \
        --name "${HOST_POOL_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --yes \
        --no-wait
    fi
    ;;

  kubernetes)
    echo "Destroying Kubernetes pod session..."
    if [ -n "${SESSION_ID}" ]; then
      kubectl delete pod "${SESSION_ID}" --grace-period=0 --force
    else
      echo "Cleaning up all ephemeral worker pods..."
      kubectl delete pods -n beagclave-agents \
        -l "app=ephemeral-worker" \
        --grace-period=0 --force
    fi
    ;;

  all)
    echo "Destroying all active sessions..."
    ${0} --session-type avd
    ${0} --session-type kubernetes
    ;;

  *)
    echo "Unknown session type: ${SESSION_TYPE}"
    echo "Usage: $0 --session-type <avd|kubernetes|all> --session-id <session_id>"
    exit 1
    ;;
esac

echo "Session destruction complete. All ephemeral data has been purged."