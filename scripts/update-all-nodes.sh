#!/bin/bash

NODES=("pve02" "pve03" "pve04")

for node in "${NODES[@]}"; do
  echo ""
  echo "==============================="
  echo " Updating $node"
  echo "==============================="
  ssh root@$node "apt update && apt upgrade -y" 2>&1
  if [ $? -eq 0 ]; then
    echo ">>> $node updated successfully"
  else
    echo ">>> ERROR: $node update failed"
  fi
done

echo ""
echo "==============================="
echo " All nodes processed"
echo "==============================="
