# Troubleshooting

- **Cargo network failures:** ensure the build container has network access or vendored crates.
- **Missing Rust toolchain:** the Dockerfiles install `rustup` and the stable toolchain.
- **SELinux denials:** verify file permissions and consider using `setenforce 0` for debugging.
- **Binary fails to run:** confirm `/etc/profile.d/volta.sh` is sourced so `VOLTA_HOME` and PATH are set.
