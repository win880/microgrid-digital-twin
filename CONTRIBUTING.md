
# Contributing

Thanks for your interest in contributing! This project aims to be a practical, production-lean microgrid digital twin with MPC/RL controllers and an iOS client.

## Quick start (dev)
- Requirements:
  - Rust (stable), cargo, rustup
  - macOS + Xcode (only if you want to build iOS artifacts locally)
- Build & test:
  - `cargo build`
  - `cargo test -p controller-mpc`
  - `cargo run -p api` → http://127.0.0.1:8080/health
- iOS artifacts (macOS):
  - `./scripts/bootstrap.sh`
  - Universal static lib: `./scripts/build_ios_universal.sh`
  - XCFramework: `./scripts/build_ios_xcframework.sh`
- iOS artifacts (CI):
  - GitHub Actions → "Build iOS Universal Lib" / "Build iOS XCFramework"

## Controller features and flags
- `controller-mpc` supports multiple solvers:
  - Default: `osqp-solver`
  - Fallback/alternative: `clarabel-solver`
- Switch to Clarabel only:
  - `cargo build -p controller-mpc --no-default-features --features clarabel-solver`

## Style, linting, tests
- Format: `cargo fmt --all`
- Lint: `cargo clippy --all-targets -- -D warnings`
- Test: `cargo test`
- Prefer `anyhow` for top-level errors and `thiserror` for library error types.
- Minimize `unsafe`; document and justify if needed.

## Commit/PR guidelines
- Branch names: `feat/...`, `fix/...`, `chore/...`, `docs/...`.
- Commit style (recommended): Conventional Commits (e.g., `feat(sim): add SOC terminal cost`).
- PRs should:
  - Explain scope and motivation.
  - Include tests where possible.
  - Pass `fmt`, `clippy`, and `test`.
- Avoid committing build outputs (e.g., `.a`, `.xcframework`); use Actions artifacts instead.

## Dependencies & workspace
- Prefer reusing `[workspace.dependencies]` in `Cargo.toml` root.
- Keep crates cohesive and small (simulator, controller-mpc, safety, storage, api, ffi).
- Document non-trivial algorithms or numerical choices in code comments.

## Security & disclosures
- Do not include secrets in code or CI configs.
- Report security issues privately first if possible.

## License
- By contributing, you agree that your contributions will be licensed under the MIT License (see LICENSE).
