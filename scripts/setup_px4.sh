#!/usr/bin/env bash
# Clone PX4-Autopilot at the pinned tag and install the official toolchain.
# Source of truth: https://docs.px4.io/main/en/dev_setup/dev_env_linux_ubuntu
# Usage: ./scripts/setup_px4.sh            (PX4 goes to ~/PX4-Autopilot)
#        PX4_DIR=/path ./scripts/setup_px4.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR
source "${SCRIPT_DIR}/versions.env"
PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"

# --- Host sanity checks -------------------------------------------------------
. /etc/os-release
if [[ "${VERSION_ID}" != "24.04" && "${VERSION_ID}" != "22.04" ]]; then
  echo "WARNING: Ubuntu ${VERSION_ID} is not a PX4-supported dev host (use ${UBUNTU_VERSION})." >&2
  read -rp "Continue anyway? [y/N] " ans
  [[ "${ans}" == "y" ]] || exit 1
fi

free_gb="$(df -BG --output=avail "$HOME" | tail -1 | tr -dc '0-9')"
if (( free_gb < 30 )); then
  echo "WARNING: only ${free_gb} GB free in \$HOME. PX4 + toolchain + Gazebo + builds need plenty of room." >&2
fi

# --- Get PX4 at the pinned version ---------------------------------------------
if [[ ! -d "${PX4_DIR}" ]]; then
  echo ">> Cloning PX4-Autopilot ${PX4_VERSION} into ${PX4_DIR}"
  git clone --recursive --branch "${PX4_VERSION}" \
    https://github.com/PX4/PX4-Autopilot.git "${PX4_DIR}"
else
  echo ">> Found ${PX4_DIR}; checking out ${PX4_VERSION}"
  git -C "${PX4_DIR}" fetch --tags
  git -C "${PX4_DIR}" checkout "${PX4_VERSION}"
  git -C "${PX4_DIR}" submodule update --init --recursive
fi

echo ">> PX4 version: $(git -C "${PX4_DIR}" describe --tags)"

# --- Official toolchain + simulator install -----------------------------------
bash "${PX4_DIR}/Tools/setup/ubuntu.sh"

cat << MSG

Done. Next:
  1. Reboot (or at least log out and back in) before building.
  2. cd ${PX4_DIR} && make px4_sitl gz_x500
  3. Record the verification outputs in docs/setup/ENVIRONMENT.md
MSG
