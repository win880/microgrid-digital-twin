

[![iOS Universal Lib](https://github.com/OWNER/REPO/actions/workflows/ios_build.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ios_build.yml) [![iOS XCFramework](https://github.com/OWNER/REPO/actions/workflows/xcframework_build.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/xcframework_build.yml)

> Vervang OWNER/REPO hierboven met jouw GitHub gebruikersnaam en repo-naam nadat je gepusht hebt.


#### MPC variabelen en constraints (ASCII)

```
Per stap t:
  x_t = [ g_t, e_t, c_t, d_t, u_t, s_{t+1} ]

Power balance:
  g_t - e_t - c_t + d_t - u_t = L_t - PV_t

SOC-dynamiek:
  s_{t+1} = s_t + k*(η_c*c_t - d_t/η_d)
  waar k = dt_hours / battery_kWh

Box-constraints:
  0 ≤ g_t ≤ g_max
  0 ≤ e_t ≤ e_max
  0 ≤ c_t ≤ c_max
  0 ≤ d_t ≤ d_max
  0 ≤ u_t ≤ u_max
  s_min ≤ s_{t+1} ≤ s_max

Kosten (per stap):
  J_t = p_buy_t*g_t - p_sell_t*e_t + λ_CO2*EI_t*(g_t - e_t)
        + α*(c_t + d_t) + β*u_t
Terminal:
  J_T += γ*(s_T - s_ref)^2

Warm-start (horizon shift):
  x_init^(t) ← [ x_{1}^{(t-1)}, x_{2}^{(t-1)}, ..., x_{H-1}^{(t-1)}, x_{H-1}^{(t-1)} ]
```


# Microgrid Digital Twin (Rust + iOS)

Een volledig werkbare basis voor een microgrid digital twin met horizon-MPC (SOC-dynamiek), OSQP-primair met Clarabel fallback, warm-starts met horizon-shift, iOS SwiftUI app + C FFI, en GitHub Actions voor iOS builds.

## TL;DR
- Build en test core: `cargo build && cargo test -p controller-mpc`
- Lokaal iOS (macOS): `./scripts/bootstrap.sh` en dan:
  - Universal .a: `./scripts/build_ios_universal.sh`
  - XCFramework: `./scripts/build_ios_xcframework.sh`
- CI (GitHub Actions): check de workflows “Build iOS Universal Lib” en “Build iOS XCFramework”; download artifacts in de run.
- iOS in Xcode: voeg de gemaakte `.a` + header, of de `.xcframework` toe (Do Not Embed).

## Features
- Rust kern met:
  - Simulator + horizon-MPC met SOC-dynamiek en box-constraints
  - Kosten: energieprijs ± CO2, degradatie- en gebruikstermen, terminal SOC-penalty
  - OSQP solver (primair) + warme start (`prob.warm_start`)
  - Clarabel conische fallback (equalities + box/ongelijkheden via positieve kegel)
- iOS SwiftUI client met C FFI bridge (geen bridging header nodig; gebruikt `@_silgen_name`)
- Scripts voor iOS build (universal `.a` of `.xcframework`)
- Workflows voor macOS CI builds met artifacts
- ML forecasting stubs (PyTorch → Core ML voorbeeldpad)

## Architectuur (overzicht)
- core/simulator: systeemtoestand, forecasts, MPC-aanroep, warm-start beheer
- core/controller-mpc: QP-opbouw (P, q, A, l, u), OSQP en Clarabel solve
- core/ffi: C-interface voor iOS (init, set_forecasts, step, get_plan)
- ios/MicrogridApp: SwiftUI app + RustBridge (CoreEngine.swift)
- scripts: bootstrap, bindings genereren, iOS build scripts
- .github/workflows: iOS universal build en XCFramework build

## Repo-structuur (beknopt)
```
.
├─ core/
│  ├─ simulator/
│  ├─ controller-mpc/
│  ├─ controller-rl/
│  ├─ safety/
│  ├─ storage/
│  ├─ api/
│  └─ ffi/
├─ ios/MicrogridApp/
│  └─ RustBridge/
├─ ml/forecasting/
├─ scripts/
└─ .github/workflows/
```

## Snelstart (developer)
### Vereisten
- Rust stable (`rustup`, `cargo`), macOS + Xcode voor iOS builds
- cbindgen (wordt automatisch geïnstalleerd door scripts/CI indien nodig)

### Build & test
```bash
cargo build
cargo test -p controller-mpc
cargo run -p api  # http://127.0.0.1:8080/health
```

## iOS builds (lokaal op macOS)
### Bootstrap eens
```bash
./scripts/bootstrap.sh
```
### Universal static library (.a)
```bash
./scripts/build_ios_universal.sh
# Output: ios/MicrogridApp/RustBridge/libmicrogrid.a + microgrid_ffi.h
```
### XCFramework (aanbevolen)
```bash
./scripts/build_ios_xcframework.sh
# Output: build/MicrogridFFI.xcframework + ios/MicrogridApp/RustBridge/microgrid_ffi.h
```

## iOS integratie in Xcode
- Universal .a route:
  - Voeg `libmicrogrid.a` en `microgrid_ffi.h` toe aan je app target (Do Not Embed)
  - Controleer `Library Search Paths` en `Header Search Paths` indien extern pad
- XCFramework route (makkelijker voor archs):
  - Voeg `MicrogridFFI.xcframework` toe (Do Not Embed)
  - `microgrid_ffi.h` enkel voor referentie (Swift gebruikt `@_silgen_name`)

## GitHub Actions (CI)
- Workflows:
  - `.github/workflows/ios_build.yml` → Universal .a + header (artifact: `microgrid-ios-artifacts`)
  - `.github/workflows/xcframework_build.yml` → XCFramework + header (artifact: `microgrid-xcframework`)
- Gebruik:
  - Push naar `main` of `Actions` → kies workflow → `Run workflow`
  - Open de workflow-run → sectie “Artifacts” rechts → download

## Configuratie (Engine parameters)
- `Params` (core/simulator) bevat o.a. `c_max, d_max, g_max, e_max, u_max, soc_min, soc_max, eta_c, eta_d, dt_sec, battery_kwh`
- Zet forecasts via FFI: `mg_set_forecasts(load, pv, ei, price)`; lengte bepaalt horizon

## MPC-formulering (samenvatting)
- Variabelen per stap t: grid-in/out (g,e), charge/discharge (c,d), curt (u), en s_{t+1}
- Box-constraints op alle variabelen incl. SOC-bounds
- Balans: g - e - c + d - u = load_hat - pv_hat
- SOC-dynamiek: s_{t+1} = s_t + (dt_hours/battery_kwh)*(eta_c*c - d/eta_d)
- Kosten: prijs±CO2 op g/e, penalties op (c,d,u), terminal SOC naar s_ref_terminal

## Warm-start en horizon-shift
- Vorige oplossing `x_{t}` wordt naar `x_{t+1}` geschoven en als init gebruikt
- OSQP `warm_start(x0)` wordt expliciet aangeroepen bij dimensionele match

## Clarabel fallback (conisch)
- Equalities → Zero cone; ongelijkheden en boxen → Nonnegative cone via herformulering
- Automatisch gebruikt als OSQP faalt; je kunt Clarabel ook als primaire feature inschakelen

## Nuttige scripts
- `scripts/gen_bindings.sh` → genereert C-header via cbindgen
- `scripts/build_ios_universal.sh` → bouwt `.a` + header (device + sim, universeel)
- `scripts/build_ios_xcframework.sh` → bouwt XCFramework (device + sim slices)

## Troubleshooting
- Arch mismatch / undefined symbols: gebruik de XCFramework of zorg dat `.a` slices matchen met je build target
- “clang not found” of link errors: Xcode CLI tools installeren (xcode-select --install)
- Rust iOS targets missen: `rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios-sim`
- OSQP linking: OSQP crate wordt statisch meegebouwd; check `cargo clean` + herbouw indien twijfel
- cbindgen ontbreekt: scripts/CI installeren automatisch; lokaal kun je `cargo install cbindgen`

## Roadmap (suggesties)
- Uitbreiding constraints (EV, demand response, feed-in caps)
- Meer MPC penalties en soft constraints
- Forecasting pipeline aansluiten (PyTorch → Core ML in iOS app)
- Persistente opslag en evaluatie dashboards

## License & Contributing
- License: MIT (zie `LICENSE`)
- Bijdragen: zie `CONTRIBUTING.md`

