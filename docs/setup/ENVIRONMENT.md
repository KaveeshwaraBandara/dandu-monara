# Environment record

Fill in the "Observed" column with real command output. If anything differs from the pinned value, stop and find out why before moving on.

| Item | Pinned | Verify with | Observed |
|---|---|---|---|
| OS | Ubuntu 24.04 LTS | `lsb_release -ds` | |
| Kernel | — | `uname -r` | |
| GPU / driver | — | `lspci -k \| grep -A3 -i vga` | |
| PX4 | v1.17.0 | `git -C ~/PX4-Autopilot describe --tags` | |
| Gazebo | Harmonic | `gz sim --version` | |
| ARM toolchain | (from ubuntu.sh) | `arm-none-eabi-gcc --version` | |
| QGroundControl | stable AppImage | Help → About | |
| ROS 2 (Phase 4) | Jazzy | `printenv ROS_DISTRO` | |

## Troubleshooting log

Record each problem as: symptom → exact error text → root cause → fix → source that confirmed it.

Known starting points:
- **Gazebo slow on integrated graphics:** `HEADLESS=1 make px4_sitl gz_x500` runs physics without the 3D window; QGC still shows everything.
- **Gazebo window glitches under Wayland:** try logging in with the "Ubuntu on Xorg" session.
- **QGC doesn't see the vehicle:** confirm PX4 is running and that nothing else is bound to UDP 14550.
- **Don't** run this stack in an Ubuntu 26.04 / ROS 2 Lyrical container — PX4 doesn't support 26.04 as a dev host yet.
