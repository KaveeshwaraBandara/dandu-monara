# Environment record

Fill in the "Observed" column with real command output. If anything differs from the pinned value, stop and find out why before moving on.

**Machine:** _TODO (laptop model)_ · **Recorded:** 2026-10-07 · **Updated:** 2026-10-08

| Item | Pinned | Verify with | Observed | Status |
|---|---|---|---|---|
| OS | Ubuntu 24.04 LTS | `lsb_release -ds` | Ubuntu 24.04.5 LTS | ✅ |
| Kernel | — | `uname -r` | 7.0.0-34-generic (HWE; 24.04 GA kernel is 6.8) | ℹ️ recorded |
| GPU / driver | — | `lspci -k \| grep -A3 -i vga` | _TODO_ | ⬜ |
| PX4 | v1.17.0 | `git -C ~/PX4-Autopilot describe --tags` | v1.17.0 | ✅ |
| Gazebo | Harmonic | `gz sim --version` | Gazebo Sim 8.15.0 (gz-sim 8 = Harmonic) | ✅ |
| ARM toolchain | (from ubuntu.sh) | `dpkg -l \| grep gcc-arm-none-eabi` | `gcc-arm-none-eabi 15:13.2.rel1-2` at `/usr/bin/arm-none-eabi-gcc` | ✅ |
| QGroundControl | stable AppImage | Help → About | _TODO_ | ⬜ |
| ROS 2 (Phase 4) | Jazzy | `printenv ROS_DISTRO` | not installed yet | ⏳ |

Note: `lsb_release` also prints "No LSB modules are available." This is harmless stderr noise.

## Open issues

None.

## Troubleshooting log

Record each problem as: symptom → exact error text → root cause → fix → source that confirmed it.

### 2026-10-07 — ARM toolchain printed no version (resolved 2026-10-08)
- **Symptom:** `arm-none-eabi-gcc --version | head -1` printed nothing in the one-line environment check.
- **Check:** `command -v arm-none-eabi-gcc` → `/usr/bin/arm-none-eabi-gcc`; `dpkg -l | grep gcc-arm-none-eabi` → `ii gcc-arm-none-eabi 15:13.2.rel1-2 amd64`
- **Root cause:** the toolchain is installed. The empty line was not a missing compiler; the exact cause was not reproduced.
- **Fix:** none needed.
- **Confirmed by:** dpkg package record and binary present on `PATH`.

### Known starting points
- **Gazebo slow on integrated graphics:** `HEADLESS=1 make px4_sitl gz_x500` runs physics without the 3D window; QGC still shows everything.
- **Gazebo window glitches under Wayland:** try logging in with the "Ubuntu on Xorg" session.
- **QGC doesn't see the vehicle:** confirm PX4 is running and that nothing else is bound to UDP 14550.
- **Don't** run this stack in an Ubuntu 26.04 / ROS 2 Lyrical container. PX4 doesn't support 26.04 as a dev host yet.
