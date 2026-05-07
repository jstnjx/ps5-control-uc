# Changelog

All notable changes to this project will be documented in this file. The
format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-05-07

### Changed
- Switched credential storage from legacy `credentials.json` format to
  native `pyremoteplay` profile storage (`daemon/.pyremoteplay/.profile.json`).
- `daemon.py` now loads profiles directly via `Profiles.load()` instead
  of converting ps5-mqtt-style registration blobs.
- `docker-compose.yml` now mounts the pyremoteplay profile directory into
  the container (`./.pyremoteplay:/root/.pyremoteplay`) instead of a
  single credentials file.
- Pairing flow now uses pyremoteplay's native registration/profile flow.
- Updated documentation and installer guidance for modern Debian/Ubuntu
  systems using PEP 668 protected Python environments.

### Fixed
- Fixed broken `pair.sh` recursion / duplicated installer logic.
- Fixed pairing on modern Debian/Ubuntu systems with PEP 668
  externally-managed Python environments.
- Fixed missing Docker build dependencies (`gcc`, `build-essential`) that
  prevented `netifaces` from compiling inside the pairing container.
- Fixed missing runtime dependency `async_timeout` in newer pyremoteplay
  dependency resolution chains.
- Fixed Remote Play OAuth redirect handling for Sony's current auth flow.
- Fixed pairing/install failures where registration succeeded but no
  `credentials.json` was produced.
- Fixed compatibility with private PSN profiles by preferring Sony OAuth
  Account ID lookup over third-party public-profile scraping.
- Fixed installer assumptions about pyremoteplay output locations
  (`~/.pyremoteplay` vs local working directory).
- Replaced the unreliable `psn.flipscreen.games` Account ID lookup path
  with `https://www.psntools.com/psn-account-checker` in documentation
  and onboarding guidance.

### Added
- Persistent pyremoteplay profile directory bind mount:
  `daemon/.pyremoteplay/`
- Pairing container now automatically installs required build/runtime
  dependencies before running registration.
- Pairing diagnostics now expose generated pyremoteplay profile files for
  troubleshooting.
- Improved update flow for forks and self-hosted GitHub remotes.
- Native pyremoteplay profile persistence across container rebuilds and
  daemon updates.

---

## Original upstream changelog below this point

The entries below refer to the original
`sbr-labs/ps5-control-uc` project before fork-specific compatibility,
Docker, OAuth, and pyremoteplay persistence updates were added in the
`this` fork.

---

## [0.4.1] - 2026-05-06

### Added
- `get-account-id.sh` + `get-account-id.py` — Sony OAuth-based PSN
  Account ID lookup. Works for **private PSN profiles** too (the
  flipscreen.games tool only works for public profiles). Runs inside a
  one-shot Docker container, no Python install needed locally.
- `install.sh` now offers to run the OAuth helper at the pairing step
  when you don't already have your Account ID.
- README updated with both Account ID lookup paths.

## [0.4.0] - 2026-05-06

Initial public release.

### Added
- Python daemon (`daemon/`) wraps `pyremoteplay` and exposes a REST API on
  port 8456 for button presses, wake/standby, app launch, and state.
- Unfolded Circle Remote 3 integration (`integration/`) forwards button
  presses to the daemon over HTTP.
- One-shot installer (`install.sh`) handles Docker check, PS5 IP collection,
  Remote Play pairing (via `pair.sh`), build, and start.
- One-shot updater (`update.sh`) pulls from GitHub, rebuilds the daemon,
  and tells you if the integration tarball needs re-uploading to the
  Remote 3.
- Integration build script (`integration/build.sh`) for those who want
  to verify or modify the source.