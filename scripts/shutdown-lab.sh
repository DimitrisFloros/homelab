#!/bin/bash

case "$1" in
  pve01)
    echo "Shutting down pve01..."
    ssh root@pve01 "pvecm expected 1 && shutdown -h now"
    ;;
  pve02)
    echo "Shutting down pve02..."
    ssh root@pve02 "shutdown -h now"
    ;;
  pve03)
    echo "Shutting down pve03..."
    ssh root@pve03 "shutdown -h now"
    ;;
  all)
    echo "Shutting down pve02 and pve03 first..."
    ssh root@pve02 "shutdown -h now"
    ssh root@pve03 "shutdown -h now"
    echo "Waiting 30 seconds for nodes to power off..."
    sleep 30
    echo "Setting quorum to 1 and shutting down pve01..."
    ssh root@pve01 "pvecm expected 1 && shutdown -h now"
    ;;
  workers)
    echo "Shutting down pve02 and pve03 (keeping pve01 running)..."
    ssh root@pve02 "shutdown -h now"
    ssh root@pve03 "shutdown -h now"
    echo "Setting quorum to 1 on pve01..."
    ssh root@pve01 "pvecm expected 1"
    echo "pve02 and pve03 shutting down. pve01 remains online."
    ;;
  *)
    echo "Usage: shutdown-lab [pve01|pve02|pve03|all|workers]"
    echo ""
    echo "  pve01    — shut down master node only"
    echo "  pve02    — shut down lab node only"
    echo "  pve03    — shut down security node only"
    echo "  all      — shut down all nodes (pve02/pve03 first, then pve01)"
    echo "  workers  — shut down pve02 and pve03, keep pve01 running"
    ;;
esac
