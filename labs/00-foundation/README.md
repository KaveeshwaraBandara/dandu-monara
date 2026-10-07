# Lab 00 — Foundation

**Goal:** a verified PX4 SITL + Gazebo + QGC setup, and a first flight driven from the PX4 shell.

## Checklist
- [ ] Host is Ubuntu 24.04 (`lsb_release -ds`)
- [ ] `./scripts/setup_px4.sh` completed, machine rebooted
- [ ] `make px4_sitl gz_x500` builds and Gazebo shows the x500
- [ ] In `pxh>`: `commander takeoff` → hovers; `commander land` → lands and disarms
- [ ] QGroundControl auto-connects and shows attitude, position, and mode
- [ ] Explored: `uorb top`, `listener vehicle_local_position`, `param show MPC_XY_VEL_MAX`, `top`
- [ ] `docs/setup/ENVIRONMENT.md` filled in
- [ ] Journal entry committed and pushed

## Questions to answer in `results.md` (in your own words)
1. Which process is the "drone" and which is the "world"? What crosses between them?
2. What does `uorb top` tell you about how PX4 is structured internally?
3. In `listener vehicle_local_position`, which way is +z? Why might that be?
4. Where did QGC get its connection from — you never configured an IP address.
