# Volta RPM Packaging

This repository contains tooling to build and test RPM packages for [Volta](https://volta.sh/), a Rust-based JavaScript toolchain manager.

## Building

Use the helper scripts in `scripts/` to build the RPM in a container. For example:

```bash
./scripts/build-rpm.sh --distro fedora --arch x86_64 --mode source
```

Artifacts will be placed under `dist/<distro>/<arch>/`.

## Installation

Install the resulting package with your package manager. The RPM installs Volta under `/usr/lib/volta` and links the main binary to `/usr/bin/volta`. PATH and `VOLTA_HOME` are set via `/etc/profile.d/volta.sh`.

```bash
sudo dnf install ./volta-*.rpm
```

## Testing

Run the smoke test script to verify the RPM inside a container:

```bash
./scripts/test-in-container.sh dist/fedora/x86_64/volta-*.rpm
```

## Contributing

See `docs/maintenance.md` for guidance on updating the package when new versions of Volta are released.
