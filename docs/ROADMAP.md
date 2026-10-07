# Roadmap

Each phase has four parts: **Learn** (concepts), **Build** (labs in `labs/`), **Read** (official sources), and **Exit criteria** (proof you're done). Move on when the exit criteria are met, not when time runs out. Doc titles below are page names on docs.px4.io — use the version selector to match `PX4_VERSION`.

---

## Phase 0 — Foundation

**Learn:** what SITL is; how PX4, Gazebo, and QGroundControl talk to each other (MAVLink over UDP, the simulator bridge).

**Build**
- `labs/00-foundation` — host check, toolchain install, first build, first takeoff/land from the `pxh>` shell, QGC connected.
- Poke the internals: `uorb top`, `listener vehicle_local_position`, `param show MPC_*`, `top`.

**Read:** Basic Concepts · Ubuntu Development Environment · Building the Code · Gazebo Simulation

**Exit criteria:** x500 takes off and lands in Gazebo; QGC shows live telemetry; environment versions recorded in `docs/setup/ENVIRONMENT.md`; first journal entry pushed.

---

## Phase 1 — Operate (think like a pilot and a test engineer)

**Learn:** flight modes (Position, Altitude, Stabilized, Acro, Hold, Mission, Return, Offboard) and what sensors each requires; arming and preflight checks; parameters; failsafes; geofence; the ULog format.

**Build**
- Fly manually with QGC's virtual joystick; feel the difference between Position, Altitude, and Stabilized.
- Plan and fly a survey mission; add a geofence and deliberately breach it.
- Trigger failsafes on purpose (low battery, data-link loss, sensor failure via Failure Injection).
- Analyse every flight: Flight Review + PlotJuggler, then write `tools/plot_ulog.py` with `pyulog` (attitude setpoint vs. estimate, mode changes, failsafe events).

**Read:** Flight Modes (MC) · Mode Requirements · Safety Configuration (Failsafes) · Failsafe Simulation · Geofence · Failure Injection · Log Analysis using Flight Review · ULog File Format

**Exit criteria:** a logged mission + failsafe demo, and a write-up explaining from the log alone *why* each failsafe fired.

---

## Phase 2 — Physics & Control (the core of "pro")

**Learn**
- Frames: NED/FRD (PX4) vs ENU/FLU (ROS); rotation matrices, Euler angles, quaternions, and why gimbal lock matters.
- Rigid-body dynamics: Newton–Euler equations for a quadrotor; rotor thrust/torque models; drag.
- Control allocation: mapping body torques + thrust to motor commands (the mixer matrix).
- Cascaded control: position → velocity → acceleration/attitude → body rate → torque; PID, anti-windup, feed-forward, D-term filtering, notch filters.

**Build**
- Lab 2.1 — 1-D altitude sim in Python with a PID; tune by hand, plot step responses.
- Lab 2.2 — planar (2-D) quadrotor sim; cascaded attitude + position control.
- Lab 2.3 — full 3-D quadrotor sim with quaternions + allocation; hover and track waypoints.
- Lab 2.4 — map your sim onto PX4: read `src/modules/mc_rate_control`, `mc_att_control`, `mc_pos_control`, `control_allocator`.
- Lab 2.5 — SITL tuning experiment: change rate/attitude gains, record step responses, compare before/after.

**Read:** Controller Diagrams · Control Allocation · PID Tuning Guide (Manual/Advanced) · Filter/Control Latency Tuning
Theory: Mahony, Kumar & Corke, *Multirotor Aerial Vehicles: Modeling, Estimation, and Control of Quadrotor* (IEEE RAM, 2012); Beard & McLain, *Small Unmanned Aircraft: Theory and Practice*.

**Exit criteria:** your own sim hovers and tracks waypoints; you can draw PX4's multicopter control loop from memory; a tuning report with plots.

---

## Phase 3 — State Estimation

**Learn:** Bayes filtering; KF, EKF, error-state KF; IMU error models (bias, noise, random walk); GNSS, barometer, magnetometer, optical flow, VIO; EKF2's architecture (delayed fusion horizon, output predictor), innovations and test ratios.

**Build**
- Lab 3.1 — 1-D Kalman filter fusing accelerometer + barometer for altitude.
- Lab 3.2 — 2-D EKF fusing IMU + GNSS; replay a SITL ULog through it and compare with EKF2's output.
- Lab 3.3 — break it: GNSS loss, magnetometer faults; diagnose using innovations.
- Lab 3.4 — GNSS-denied flight in SITL (optical flow or external vision model from the Gazebo Vehicles page).

**Read:** Using PX4's Navigation Filter (EKF2) · GNSS-Denied & Degraded Flight · Switching State Estimators
Theory: Solà, *Quaternion kinematics for the error-state Kalman filter*; Thrun et al., *Probabilistic Robotics* ch. 2–3.

**Exit criteria:** diagnose an estimator failure from a log alone; your EKF tracks EKF2 closely on replayed data.

---

## Phase 4 — Interfaces (talking to the drone)

**Learn:** MAVLink messages and microservices (command, mission, parameter); MAVSDK; PX4–ROS 2 architecture over uXRCE-DDS; matching `px4_msgs` to the firmware's message definitions (and the message translation node when they differ); QoS compatibility; NED↔ENU conversions; offboard mode requirements.

**Build**
- Lab 4.1 — MAVSDK-Python: takeoff, goto, mission upload, telemetry logger.
- Lab 4.2 — ROS 2 Jazzy workspace in `ros2_ws/` with `px4_msgs` at the branch matching `PX4_VERSION` (verify with `git branch -r`) and the Micro XRCE-DDS Agent version the PX4 docs list for Jazzy.
- Lab 4.3 — offboard control: square, then figure-8, in Python and C++.
- Lab 4.4 — PX4 ROS 2 Interface Library: a custom **external flight mode** that appears in QGC like a native mode.

**Read:** MAVSDK · ROS 2 User Guide · ROS 2 Offboard Control Example · uXRCE-DDS · PX4 ROS 2 Interface Library · Control Interface · ROS 2 Message Translation Node · mavlink.io

**Exit criteria:** your external mode is selectable from QGC and flies a pattern; frame and QoS gotchas documented in `docs/notes/`.

---

## Phase 5 — Inside PX4

**Learn:** NuttX vs POSIX targets; modules, work queues, scheduling; uORB pub/sub; parameters and metadata; startup scripts and airframe files; build system and kconfig; message versioning.

**Build**
- Lab 5.1 — Writing your First Application (`hello_sky`).
- Lab 5.2 — a work-queue module in `px4_modules/` (out-of-tree) that subscribes to attitude and publishes a custom uORB topic.
- Lab 5.3 — bridge that custom topic to ROS 2 via `dds_topics.yaml`.
- Lab 5.4 — custom Gazebo model + airframe (different mass/arm length, or a hexacopter); verify it flies.
- Lab 5.5 — debug SITL with GDB.

**Read:** PX4 System Architecture · PX4 Flight Stack Architecture · uORB Messaging · Application/Module Template · Out-of-Tree Modules · Adding a New Airframe · Gazebo Vehicles / Worlds / Plugins · Debugging with GDB

**Exit criteria:** your module runs in SITL and its topic is visible in ROS 2; your custom airframe flies.

---

## Phase 6 — Perception & Autonomy

**Learn:** camera models and calibration; `ros_gz` bridging; fiducial markers; the precision-landing pipeline; external vision/VIO fusion; obstacle representation and Collision Prevention; planning (A*, RRT*, minimum-snap trajectories); companion-computer architecture.

**Build**
- Lab 6.1 — Gazebo world with an ArUco/AprilTag pad → camera → ROS 2 detector → landing target → precision landing.
- Lab 6.2 — depth camera → obstacle distance → collision prevention.
- Lab 6.3 — planner through a cluttered world.
- Lab 6.4 — split architecture: SITL on the laptop, perception on the Jetson Orin NX over the network (realistic companion setup).
- Stretch — semantic commands with a VLM ("land next to the red car").

**Read:** Precision Landing · Vision Target Estimator · Collision Prevention · Visual Inertial Odometry · Companion Computers · Video Streaming

**Exit criteria:** autonomous marker landing from altitude with *measured* accuracy over repeated trials; obstacle-avoidance demo video.

---

## Phase 7 — Scale & Reliability

**Learn:** multi-vehicle namespacing; formation basics; integration testing; CI for robotics.

**Build**
- Lab 7.1 — multi-vehicle SITL with ROS 2.
- Lab 7.2 — integration tests (MAVSDK or PX4 ROS 2 Interface Library tests).
- Lab 7.3 — GitHub Actions running a headless SITL mission test on every PR.
- Adopt PX4 test cards as flight-test checklists.

**Read:** Multi-Vehicle Sim · ROS 2 Multi Vehicle Simulation · Integration Testing · Test Flights · SIH Simulation

**Exit criteria:** CI is green on a headless mission test for every PR.

---

## Phase 8 — Real Hardware

**Learn:** frames, motors (KV), props, ESC protocols (DShot), LiPo chemistry and safety, power modules, GNSS/compass placement, vibration isolation, RC and telemetry links, Remote ID; local regulations (Civil Aviation Authority of Sri Lanka) before any outdoor flight.

**Build:** choose a PX4 developer kit or a documented build; bench tests; sensor calibration; actuator setup; HITL with the Jetson as companion; first-flight checklist; autotune; log review after every flight.

**Read:** Developer Kits · Assembly · Standard Configuration · First Flight Guidelines · Auto-tune · HITL Simulation · Holybro Pixhawk Jetson Baseboard

**Exit criteria:** stable Position and Mission flights with a log review for each; flight-test reports using test cards.

---

## Optional extensions

Fixed-wing and VTOL; learned control (PX4's neural-network control modules); ArduPilot for comparison; upstream contributions to PX4.
