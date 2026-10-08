#!/usr/bin/env bash
# tmux workspace for SITL work.
#   window "sim", top pane:    PX4 SITL + Gazebo   (make px4_sitl <model>)
#   window "sim", bottom pane: shell in this repo  (notes, scripts, ROS 2 later)
#   window "qgc":              QGroundControl, if the AppImage is found
# Usage:
#   ./scripts/sim.sh                 # start (or re-attach to) the workspace, model gz_x500
#   ./scripts/sim.sh <model>         # any model from the PX4 "Gazebo Vehicles" page
#   HEADLESS=1 ./scripts/sim.sh      # no Gazebo GUI (lighter on integrated GPUs)
#   ./scripts/sim.sh stop            # clean PX4 shutdown, close the session, kill leftover Gazebo
set -euo pipefail

command -v tmux >/dev/null || { echo "tmux not installed: sudo apt install tmux"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source-path=SCRIPTDIR
source "${SCRIPT_DIR}/versions.env"

PX4_DIR="${PX4_DIR:-$HOME/PX4-Autopilot}"
SESSION="drone"
QGC_APPIMAGE="${QGC_APPIMAGE:-$HOME/Applications/QGroundControl-x86_64.AppImage}"

# Attach from a plain terminal, or switch to it if we're already inside tmux.
attach_session() {
  if [[ -n "${TMUX:-}" ]]; then
    exec tmux switch-client -t "${SESSION}"
  else
    exec tmux attach-session -t "${SESSION}"
  fi
}

# Gazebo processes launched by PX4 SITL.
# PX4 starts the Gazebo server and GUI with '&' from rcS, which it runs via system("/bin/sh ...").
# That shell exits after startup, so Gazebo is re-parented and survives PX4. Every process the
# SITL build target starts inherits PX4_SIM_MODEL, which is how we tell them apart from any
# other Gazebo you might be running.
px4_gz_pids() {
  local pid
  for pid in $(pgrep -f "gz sim"); do
    if tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep -q '^PX4_SIM_MODEL='; then
      echo "${pid}"
    fi
  done
}

kill_px4_gz() {
  local pids
  mapfile -t pids < <(px4_gz_pids)
  if (( ${#pids[@]} > 0 )); then
    echo ">> Stopping PX4's Gazebo processes:"
    ps -o pid=,args= -p "$(IFS=,; echo "${pids[*]}")"
    kill "${pids[@]}" 2>/dev/null || true
    sleep 1
    mapfile -t pids < <(px4_gz_pids)
    if (( ${#pids[@]} > 0 )); then
      kill -9 "${pids[@]}" 2>/dev/null || true
    fi
  fi
}

stop_sim() {
  if tmux has-session -t "${SESSION}" 2>/dev/null; then
    echo ">> Asking PX4 to shut down cleanly"
    tmux send-keys -t "${SESSION}:sim.{top}" "shutdown" C-m
    sleep 3
    tmux kill-session -t "${SESSION}"
    echo ">> tmux session '${SESSION}' closed"
  else
    echo ">> No '${SESSION}' session running"
  fi
  kill_px4_gz
  echo ">> Stopped."
}

if [[ "${1:-}" == "stop" ]]; then
  stop_sim
  exit 0
fi

MODEL="${1:-gz_x500}"

[[ -d "${PX4_DIR}" ]] || { echo "PX4 not found at ${PX4_DIR}. Run scripts/setup_px4.sh first."; exit 1; }

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  attach_session
fi

# A Gazebo left over from an earlier run would make PX4 attach to the old world
# ("gazebo already running world") and skip starting the GUI. Start clean instead.
kill_px4_gz

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
attach_session
