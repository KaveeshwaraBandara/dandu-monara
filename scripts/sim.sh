#!/usr/bin/env bash
# tmux workspace for SITL work.
#   window "sim", top pane:    PX4 SITL + Gazebo   (make px4_sitl <model>)
#   window "sim", bottom pane: shell in this repo  (notes, scripts, ROS 2 later)
#   window "qgc":              QGroundControl, if the AppImage is found
# Usage:
#   ./scripts/sim.sh                 # default model gz_x500
#   ./scripts/sim.sh <model>         # any model from the PX4 "Gazebo Vehicles" page
#   HEADLESS=1 ./scripts/sim.sh      # no Gazebo GUI (lighter on integrated GPUs)
set -euo pipefail

command -v tmux >/dev/null || { echo "tmux not installed: sudo apt install tmux"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source-path=SCRIPTDIR
source "${SCRIPT_DIR}/versions.env"

PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"
MODEL="${1:-gz_x500}"
SESSION="drone"
QGC_APPIMAGE="${QGC_APPIMAGE:-$HOME/Applications/QGroundControl-x86_64.AppImage}"

[[ -d "${PX4_DIR}" ]] || { echo "PX4 not found at ${PX4_DIR}. Run scripts/setup_px4.sh first."; exit 1; }

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  exec tmux attach -t "${SESSION}"
fi

SIM_CMD="make px4_sitl ${MODEL}"
if [[ -n "${HEADLESS:-}" ]]; then
  SIM_CMD="HEADLESS=1 ${SIM_CMD}"
fi

tmux new-session -d -s "${SESSION}" -n sim -c "${PX4_DIR}"
tmux send-keys -t "${SESSION}:sim" "${SIM_CMD}" C-m
tmux split-window -v -t "${SESSION}:sim" -c "${REPO_ROOT}"

if [[ -x "${QGC_APPIMAGE}" ]]; then
  tmux new-window -d -t "${SESSION}" -n qgc "${QGC_APPIMAGE}"
else
  echo "Note: QGC not found at ${QGC_APPIMAGE} (set QGC_APPIMAGE=/path/to/AppImage)."
fi

tmux select-pane -t "${SESSION}:sim.{top}"
exec tmux attach -t "${SESSION}"
