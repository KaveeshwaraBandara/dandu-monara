# Lab 00 — Results

**Date:** 2026-10-07
**Setup:** PX4 `v1.17.0` SITL · Gazebo Harmonic · model `gz_x500` · vehicle on the ground
**Raw evidence:** [`evidence/pxh_session.txt`](evidence/pxh_session.txt) (`uorb top`, `listener vehicle_local_position`, `param show MPC_XY_VEL_MAX`)

All source references are to the PX4 `v1.17.0` tag and were checked in the source, not taken from tutorials.

---

## Q1 — Which process is the "drone" and which is the "world"? What crosses between them?

**Drone:** the `px4` process (the `pxh>` shell). It is the same flight-stack code that runs on a Pixhawk, built for a POSIX/Linux target.
**World:** Gazebo (`gz sim`). It simulates physics, sensors, and the effect of the motors on the airframe.

The **`gz_bridge`** PX4 module connects them over Gazebo's gz-transport. Three kinds of data cross the boundary.

| Direction | What | Where it shows up |
|---|---|---|
| World → Drone | **Time.** `gz_bridge` subscribes to `/world/<world>/clock` and sets PX4's clock from it, so simulation time drives PX4. | `GZBridge.cpp` (`px4_clock_settime`) |
| World → Drone | **Sensor data**: IMU, magnetometer, air pressure, GNSS | `sensor_accel` / `sensor_gyro` 250 Hz, `sensor_mag` 100 Hz, `sensor_baro` 50 Hz, `sensor_gps` 31 Hz |
| Drone → World | **Motor commands**: rotor speeds published to the Gazebo topic `/x500/command/motor_speed` | `actuator_motors` / `actuator_outputs` 250 Hz |

**Key insight:** PX4 never "knows" it is simulated. It only sees sensor topics and produces motor commands. That is why the same code can run against Gazebo, SIH, or real hardware.

**Ground truth:** `gz_bridge` also publishes `vehicle_*_groundtruth` topics. These are the simulator's perfect state, which a real drone never has. Comparing `vehicle_local_position` against `vehicle_local_position_groundtruth` measures estimator error directly (used in Phase 3).

**Sources:** `src/modules/simulation/gz_bridge/GZBridge.hpp`, `GZBridge.cpp`, `GZMixingInterfaceESC.cpp`; `ROMFS/px4fmu_common/init.d-posix/px4-rc.gzsim`

---

## Q2 — What does `uorb top` say about how PX4 is structured?

PX4 is a set of **independent modules that never call each other directly**. They communicate only by publishing and subscribing to **uORB topics**; this run had 122 active topics.

| Column | Meaning |
|---|---|
| INST | Instance number for multi-instance topics |
| #SUB | Number of subscribers |
| RATE | Publish rate (Hz) |
| #Q | Queue depth |
| SIZE | Message size (bytes) |

### The control pipeline, read from the rates

```
sensor_gyro / sensor_accel   250 Hz (#Q 8)
  └─► sensor_combined        250 Hz
        └─► EKF2 ─► vehicle_attitude 250 Hz · vehicle_local_position 125 Hz
trajectory_setpoint           50 Hz
  └─► position controller ─► vehicle_attitude_setpoint 125 Hz
        └─► attitude controller ─► vehicle_rates_setpoint 250 Hz
              └─► rate controller ─► vehicle_torque_setpoint + vehicle_thrust_setpoint 250 Hz
                    └─► control_allocator ─► actuator_motors 250 Hz ─► Gazebo
```

**Pattern:** the outer loops are slower (50 → 125 Hz) and the inner loops are faster (250 Hz). This is **cascaded control**, the starting point for Phase 2.

### Other observations

- **`telemetry_status` has instances 0–3.** These are four separate MAVLink links (see Q4).
- **`vehicle_status` has 56 subscribers and `vehicle_local_position` has 40.** System state and position are consumed by almost every module. `actuator_motors` has only 4.
- **`sensor_gyro` / `sensor_accel` use #Q 8, while most topics use #Q 1.** Raw IMU samples are queued so none are lost. For setpoints only the latest value matters.

### Parameter output

`x MPC_XY_VEL_MAX [631,1100] : 12.0000` decodes as follows:

- `x` means the parameter is used by a running module.
- There is no `+`, so the value is still the default.
- `[631,1100]` is the index among *used* parameters, then the index among *all* parameters (`src/systemcmds/param/param.cpp`).
- The value is a 12 m/s maximum horizontal speed.

The summary line `1003/1920 parameters used` means only the modules actually running use their parameters.

**Open question for Phase 3:** why is `vehicle_attitude` published at 250 Hz but `vehicle_local_position` at 125 Hz?

---

## Q3 — In `vehicle_local_position`, which way is +z? Why?

**+z is Down.** PX4's local frame is **NED**: x = North, y = East, z = Down. The message definition says it directly: *"Down position (negative altitude) in NED earth-fixed frame"* (`msg/versioned/VehicleLocalPosition.msg`).

**From my data:**

- **Position.** `z = -0.01430` means about 1.4 cm *above* the origin, so the vehicle is on the ground. This is consistent with `vx, vy, vz ≈ 0`.
- **Origin.** `ref_lat 47.397971, ref_lon 8.546163` is a point in Zurich, PX4's default simulated home.
- **Heading.** `heading = 1.67649 rad ≈ 96°` from North, so the vehicle faces roughly East. Probable cause: Gazebo's world frame is ENU, so a model spawned facing Gazebo's +x faces East, which is ≈ 90° in PX4.
- **Heading uncertainty.** `heading_var = 0.02987 rad²` gives σ ≈ 0.17 rad ≈ 10°. The 6° offset is therefore within the estimator's own stated uncertainty while stationary on the ground.

**Why NED/FRD:** it is the aerospace convention. Gravity points along +z. The body frame FRD (forward-right-down) gives positive pitch = nose up and positive yaw = clockwise viewed from above, the same direction as a compass heading. Altitude is simply `-z`.

**Why it matters:** ROS uses **ENU/FLU**, so z (and more) flips at the PX4 ↔ ROS 2 boundary. This is a classic source of bugs in Phase 4.

---

## Q4 — Where did QGC get its connection from?

PX4 SITL starts **four MAVLink instances** (`ROMFS/px4fmu_common/init.d-posix/px4-rc.mavlink`). These are the four `telemetry_status` instances in Q2.

| Link | Local port | Remote port |
|---|---|---|
| GCS | 18570 | 14550 (default) |
| API / Offboard | 14580 | 14540 |
| Camera (payload) | 14280 | 14030 |
| Gimbal | 13030 | 13280 |

The GCS link is started as `mavlink start -x -u 18570 -r 4000000 -f`, with **no target specified**. PX4 therefore uses the defaults:

- **Remote port 14550**, commented as *"GCS port per MAVLink spec"* (`src/modules/mavlink/mavlink_main.h`).
- **Target address `127.0.0.1`** (`mavlink_main.cpp`).

PX4 streams heartbeats and telemetry to `localhost:14550`. QGC listens on UDP 14550 by default and auto-connects when it hears a heartbeat. Zero configuration is needed because both run on the same machine.

**Consequences:**

- A QGC on a *different* machine will not auto-connect, because PX4 only sends to localhost.
- MAVSDK and my own apps will use the **14540** API link (Phase 4).

---

## Verification experiments (pending)

- [ ] `commander takeoff`, then `listener vehicle_local_position`. Expect `z ≈ -MIS_TAKEOFF_ALT`.
  - `param show MIS_TAKEOFF_ALT` → _
  - observed `z` while hovering → _
- [ ] `listener vehicle_local_position_groundtruth`. Compare its heading with the estimated `1.676 rad`.
  - ground-truth heading → _
  - conclusion about the spawn-orientation hypothesis → _

## Sources (PX4 `v1.17.0`)

- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/modules/simulation/gz_bridge/GZBridge.hpp
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/modules/simulation/gz_bridge/GZBridge.cpp
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/modules/simulation/gz_bridge/GZMixingInterfaceESC.cpp
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/ROMFS/px4fmu_common/init.d-posix/px4-rc.gzsim
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/ROMFS/px4fmu_common/init.d-posix/px4-rc.mavlink
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/modules/mavlink/mavlink_main.h
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/modules/mavlink/mavlink_main.cpp
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/src/systemcmds/param/param.cpp
- https://github.com/PX4/PX4-Autopilot/blob/v1.17.0/msg/versioned/VehicleLocalPosition.msg
