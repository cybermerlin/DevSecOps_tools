#!/usr/bin/env sh
set -eu

get_virtual() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    if systemd-detect-virt > /dev/null; then
      if [ "$(systemd-detect-virt)" = 'wsl' ]; then
        echo "wsl -> distro: '$WSL_DISTRO_NAME'"
      fi
      return 0
    else
      return 1
    fi
  elif grep -qa 'hypervisor' /proc/cpuinfo; then
    echo "hypervisor present"
    return 0
  else
    return 1
  fi
}


if get_virtual >/dev/null; then
  echo "Running inside a virtual machine [$(get_virtual)]."
else
  echo "Running on bare metal."
fi
