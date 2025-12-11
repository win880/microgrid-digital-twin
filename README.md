
# Microgrid Digital Twin (Rust + iOS) — A→Z

Dit repo bevat:
- Rust kern (simulator + MPC met OSQP primair en Clarabel fallback, warm-start, horizon shift)
- iOS SwiftUI app met C FFI bridge
- Build-scripts voor iOS (universele .a en XCFramework)
- GitHub Actions workflows (macOS runners) om iOS artifacts te bouwen
- Optionele ML forecasting stub (PyTorch → Core ML)

Snelstart:
1) Rust host build/test (Linux/macOS):
   - `cargo build`
   - `cargo test -p controller-mpc`
   - `cargo run -p api` → http://127.0.0.1:8080/health
2) iOS artifacts op macOS lokaal:
   - `./scripts/bootstrap.sh`
   - `./scripts/build_ios_universal.sh` (snelle universele .a)
   - of `./scripts/build_ios_xcframework.sh` (aanbevolen XCFramework)
3) iOS artifacts via GitHub Actions (macOS CI):
   - Zie `README_actions_artifacts.md`

Bekijk ook `microgrid_all_in_one_guide_and_repo_snapshot.md` voor de volledige A→Z uitleg.
