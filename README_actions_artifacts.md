
### Using GitHub Actions Artifacts (Universal .a and XCFramework)

1) Trigger via Actions (Run workflow) of push naar main.
2) Download artifacts in de workflow-run (rechts → Artifacts):
   - `microgrid-ios-artifacts` (universal .a + header)
   - `microgrid-xcframework` (XCFramework + header)
3) Xcode: voeg de artifact toe (Do Not Embed). Voor XCFramework hoef je je geen zorgen te maken over arch-mismatches.
