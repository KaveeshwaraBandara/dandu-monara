# Environment record

Fill in the "Observed" column with real command output. If anything differs from the pinned value, stop and find out why before moving on.

**Machine:** _TODO (laptop model)_ · **Recorded:** 2026-10-07

| Item | Pinned | Verify with | Observed | Status |
|---|---|---|---|---|
| OS | Ubuntu 24.04 LTS | `lsb_release -ds` | Ubuntu 24.04.5 LTS | ✅ |
| Kernel | — | `uname -r` | 7.0.0-34-generic (HWE; 24.04 GA kernel is 6.8) | ℹ️ recorded |
| GPU / driver | — | `lspci -k \| grep -A3 -i vga` | _TODO_ | ⬜ |
| PX4 | v1.17.0 | `git -C ~/PX4-Autopilot describe --tags` | v1.17.0 | ✅ |
| Gazebo | Harmonic | `gz sim --version` | Gazebo Sim 8.15.0 (gz-sim 8 = Harmonic) | ✅ |
| ARM toolchain | (from ubuntu.sh) | `arm-none-eabi-gcc --version` | **no output** — see open issue below | ⚠️ |
| QGroundControl | stable AppImage | Help → About | _TODO_ | ⬜ |
| ROS 2 (Phase 4) | Jazzy | `printenv ROS_DISTRO` | not installed yet | ⏳ |

Note: `lsb_release` also prints "No LSB modules are available." This is harmless stderr noise.

## Open issues

### ARM toolchain not reporting a version (2026-10-07)
- **Symptom:** `arm-none-eabi-gcc --version | head -1` printed nothing.
- **Impact:** none for SITL. It is needed only to build firmware for a real flight controller (Phase 8).
- **Check:** `command -v arm-none-eabi-gcc` and `dpkg -l | grep gcc-arm-none-eabi`
- **Root cause:** _TODO_
- **Fix:** _TODO_
- **Confirmed by:** _TODO_

## Troubleshooting log

Record each problem as: symptom → exact error text → root cause → fix → source that confirmed it.

Known starting points:
- **Gazebo slow on integrated graphics:** `HEADLESS=1 make px4_sitl gz_x500` runs physics without the 3D window; QGC still shows everything.
- **Gazebo window glitches under Wayland:** try logging in with the "Ubuntu on Xorg" session.
- **QGC doesn't see the vehicle:** confirm PX4 is running and that nothing else is bound to UDP 14550.
- **Don't** run this stack in an Ubuntu 26.04 / ROS 2 Lyrical container. PX4 doesn't support 26.04 as a dev host yet.
