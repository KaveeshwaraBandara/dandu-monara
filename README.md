# Dandu Monara

> A hands-on, simulation-first path from zero to professional drone engineer — PX4 SITL, Gazebo, ROS 2, and eventually real hardware.

*Dandu Monara is King Ravana's flying machine in Sri Lankan legend. This repo builds the real thing, one verified step at a time.*

## Stack (pinned)

| Component | Version | Reason |
|---|---|---|
| Host OS | Ubuntu 24.04 LTS | PX4's CI/release target (26.04 not yet supported) |
| Autopilot | PX4-Autopilot `v1.17.0` | Latest stable at repo start; upgrades are deliberate, journaled exercises |
| Simulator | Gazebo Harmonic | Installed by PX4's `ubuntu.sh` on 24.04 |
| ROS 2 | Jazzy (LTS) | PX4's recommended ROS 2 platform on 24.04 |
| PX4 ↔ ROS 2 | uXRCE-DDS | PX4's recommended middleware (Zenoh is newer/experimental) |
| Ground station | QGroundControl (AppImage) | Official PX4 GCS |

Pinned values live in [`scripts/versions.env`](scripts/versions.env).

## Roadmap

Phases are gated by **exit criteria, not dates**. Details: [docs/ROADMAP.md](docs/ROADMAP.md).

- [ ] **Phase 0 — Foundation:** toolchain, repo, first SITL flight
- [ ] **Phase 1 — Operate:** QGC, flight modes, missions, parameters, failsafes, logs
- [ ] **Phase 2 — Physics & Control:** rotations, 6-DoF dynamics, allocation, cascaded control, tuning
- [ ] **Phase 3 — Estimation:** Kalman filtering, EKF2, sensor fusion, GNSS-denied flight
- [ ] **Phase 4 — Interfaces:** MAVLink/MAVSDK, ROS 2 + uXRCE-DDS, offboard, external modes
- [ ] **Phase 5 — Inside PX4:** uORB, modules, custom messages, airframes, Gazebo models
- [ ] **Phase 6 — Perception & Autonomy:** cameras, precision landing, avoidance, companion compute
- [ ] **Phase 7 — Scale & Reliability:** multi-vehicle, integration tests, CI with headless SITL
- [ ] **Phase 8 — Real Hardware:** build, calibrate, tune, fly, analyse logs, regulations

## Repository layout

```
dandu-monara/
├── docs/
│   ├── ROADMAP.md          # phases, labs, exit criteria, official sources
│   ├── setup/              # environment record + troubleshooting
│   ├── notes/              # one concept per file, every claim sourced
│   └── journal/            # one file per session: YYYY-MM-DD.md
├── labs/                   # one folder per lab: README + code + results
├── ros2_ws/src/            # my ROS 2 packages (Phase 4+)
├── px4_modules/            # out-of-tree PX4 modules (Phase 5+)
├── sim/{models,worlds}/    # custom Gazebo models and worlds
├── tools/                  # Python utilities (log analysis, MAVSDK scripts)
├── scripts/                # setup + launch scripts, pinned versions
├── logs/                   # local .ulg flight logs (git-ignored)
└── media/                  # plots, screenshots, videos for write-ups
```

PX4 itself is **not** vendored here. It lives at `~/PX4-Autopilot`, checked out at the pinned tag by `scripts/setup_px4.sh`. My code extends PX4 from the outside (out-of-tree modules, ROS 2 packages, Gazebo models), so upgrading PX4 never means untangling my changes from upstream.

## Quick start

```bash
./scripts/setup_px4.sh     # clone PX4 at the pinned tag + official toolchain install
# reboot, then:
./scripts/sim.sh           # tmux: PX4 SITL + Gazebo x500 (+ QGC if installed)
```

## Conventions

- **Sources:** official docs (docs.px4.io, docs.ros.org, gazebosim.org, mavlink.io) or source code first. Secondhand tutorials only as pointers, never as the reference.
- **Journal:** every session gets `docs/journal/YYYY-MM-DD.md` — what I did, what broke, how I verified it, what I learned.
- **Branches:** one per lab (`phase1/missions`), merged via PR. PR descriptions double as documentation.
- **Commits:** Conventional Commits — `feat:`, `fix:`, `docs:`, `chore:`, plus `exp:` for experiments.
- **Milestones:** each completed phase → tag `phase-N` + a GitHub Release with a short write-up, plots, and a video.
