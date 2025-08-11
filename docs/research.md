# Research

## Upstream
- **Repository:** https://github.com/volta-cli/volta
- **License:** MIT
- **Latest release:** discovered via GitHub API `https://api.github.com/repos/volta-cli/volta/releases/latest` (fallback: scrape HTML).

## Build
- Volta is written in Rust and builds with the stable toolchain using `cargo`.
- Upstream claims to produce static binaries for Linux.

## Installer behavior
- Upstream installer modifies user shell profiles; RPM packages should instead drop scripts in `/etc/profile.d/`.

## Fedora Rust macros and vendoring
- Use `%cargo_prep`, `%cargo_build`, `%cargo_install`, and `%cargo_test` macros.
- Vendoring crates via `%cargo_prep` provides reproducible builds.

## cargo-rpm
- `cargo-rpm` can generate RPMs from a Rust project but is less flexible than a handwritten spec. Using Fedora macros keeps closer to distro guidelines.
