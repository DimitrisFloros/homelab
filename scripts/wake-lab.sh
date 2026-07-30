#!/bin/bash

case "$1" in
  pve01)
    echo "Waking pve01..."
    wakeonlan 18:3d:2d:ec:77:72
    ;;
  pve02)
    echo "Waking pve02..."
    wakeonlan 18:3d:2d:f8:06:97
    ;;
  pve03)
    echo "Waking pve03..."
    wakeonlan 18:3d:2d:f5:ee:b8
    ;;
  all)
    echo "Waking all nodes..."
    wakeonlan 18:3d:2d:ec:77:72
    wakeonlan 18:3d:2d:f8:06:97
    wakeonlan 18:3d:2d:f5:ee:b8
    ;;
  *)
    echo "Usage: wake-lab [pve02|pve03|pve04|all]"
    ;;
esac
