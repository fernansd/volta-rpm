# PLAN for Codex: Research, build, and ship an RPM for **Volta** (latest)

## 0) Goal & scope

* Build a reproducible RPM that installs Volta system-wide on RPM distros (Fedora/RHEL/CentOS Stream/openSUSE), for `x86_64` and `aarch64`.
* Default to building **from source** with Cargo (preferred for distro hygiene), but also support a **binary-repack** path as a fallback when needed.
* Automatically track “latest” Volta release and build it.
* Publish build artifacts via GitHub Releases.

**Key facts to anchor on:** Volta is a Rust-based JS toolchain manager; upstream provides a curl installer that edits shell profiles; “latest” can be discovered via GitHub Releases; Fedora provides Cargo RPM macros; `cargo-rpm` is an optional helper. ([volta.sh](https://volta.sh/?utm_source=chatgpt.com), [docs.volta.sh](https://docs.volta.sh/guide/getting-started?utm_source=chatgpt.com), [GitHub](https://github.com/volta-cli/volta/releases?utm_source=chatgpt.com), [docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/packaging-guidelines/Rust/?utm_source=chatgpt.com))

---

## 1) Research checklist (capture findings in `docs/research.md`)

1. Confirm upstream repo, license, and the current **latest** release tag & assets. Record how to query it programmatically (GitHub API + fallback to HTML). ([GitHub](https://github.com/volta-cli/volta/releases?utm_source=chatgpt.com))
2. Note build instructions & expectations (Rust stable, static binary claim, etc.). ([volta.sh](https://volta.sh/?utm_source=chatgpt.com))
3. Summarize Volta’s installer behavior (modifies shell startup files) and decide what the RPM should do instead (use `profile.d`). ([docs.volta.sh](https://docs.volta.sh/guide/getting-started?utm_source=chatgpt.com))
4. Read Fedora Rust packaging macros (`%cargo_prep`, `%cargo_build`, `%cargo_install`, `%cargo_test`) and any vendoring guidance; decide on vendoring strategy for reproducible builds. ([docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/packaging-guidelines/Rust/?utm_source=chatgpt.com))
5. Evaluate `cargo-rpm` as an alternative path and document tradeoffs vs. native spec + macros. ([GitHub](https://github.com/iqlusioninc/cargo-rpm?utm_source=chatgpt.com))

**Deliverable:** `docs/research.md` with links, decisions, and a short rationale for each.

---

## 2) Repository layout (create)

```
volta-rpm/
  README.md
  LICENSE
  .tool-versions (or rust-toolchain.toml)
  .github/workflows/build.yml
  scripts/
    get-latest-volta.sh
    update-spec-version.sh
    build-rpm.sh
    test-in-container.sh
  packaging/rpm/
    volta.spec
    sources/
      profile.d/volta.sh
      profile.d/volta.csh
  docs/
    research.md
    maintenance.md
    troubleshooting.md
  container/
    fedora.Dockerfile
    rhel9.Dockerfile
    opensuse.Dockerfile
```

---

## 3) Packaging design (decisions Codex should implement)

* **Install layout**

  * Place Volta under `/usr/lib/volta` (or `/usr/lib64/volta` only if needed), with the main binary linked into `/usr/bin/volta`.
  * Ship `/etc/profile.d/volta.sh` and `/etc/profile.d/volta.csh` that add `/usr/lib/volta/bin` to `PATH` and set `VOLTA_HOME=/usr/lib/volta`.
  * Do **not** auto-modify user dotfiles (that’s what the curl installer does; RPMs shouldn’t). ([docs.volta.sh](https://docs.volta.sh/guide/getting-started?utm_source=chatgpt.com))
* **Two build modes (selectable via `--with bundled` or similar):**

  1. **From source (default):**

     * Use Fedora Rust macros: `%cargo_prep` (vendor crates), `%cargo_build`, `%cargo_install`, `%cargo_test`. ([docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/packaging-guidelines/Rust/?utm_source=chatgpt.com))
     * Vendor dependencies for reproducibility.
  2. **Binary repack (fallback):**

     * Download official `volta-<ver>-linux.tar.gz` from Releases, verify checksum, and repackage into filesystem layout above. ([GitHub](https://github.com/volta-cli/volta/releases?utm_source=chatgpt.com))
* **Architectures:** build `x86_64` and `aarch64`; allow opt-out if upstream asset missing (binary path) or a crate limits support (source path).
* **SELinux / permissions:** no daemons; ensure binaries are `0755`, dirs `0755`.
* **Obsoletes/Conflicts/Provides:** none expected; name package `volta` (`volta-cli` as `Provides`).

---

## 4) Spec file (create `packaging/rpm/volta.spec`)

Include:

* `Name: volta`, `Version:` templated, `Release: 1%{?dist}`, `License:` per upstream, `URL:` upstream repo, `Source0:` pointing to the tarball (source or vendor snapshot as appropriate).
* `BuildRequires:` `rust`, `cargo`, `gcc`, `make`, and `rust-packaging`/`cargo-rpm-macros` for macros. ([docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/packaging-guidelines/Rust/?utm_source=chatgpt.com))
* `%prep` → `%autosetup` and `%cargo_prep` (if building from source).
* `%build` → `%cargo_build`.
* `%install` → `%cargo_install` and then install `profile.d` files and the `/usr/bin/volta` symlink.
* `%check` → `%cargo_test` (allow network off; skip tests if they require it).
* `%files` with `%config(noreplace)` for `/etc/profile.d/*`.
* `%post` message: brief note about opening a new shell or sourcing `/etc/profile.d/volta.sh`.

**Deliverable:** a working spec with both `%{with bundled}` conditional branch for binary-repack and default Rust build branch.

---

## 5) Version automation (latest tracking)

* `scripts/get-latest-volta.sh`:

  * Query GitHub Releases API for `volta-cli/volta` and echo `tag_name`. Fallback: scrape releases HTML if API rate-limited. ([GitHub](https://github.com/volta-cli/volta/releases?utm_source=chatgpt.com))
* `scripts/update-spec-version.sh`:

  * Take a version input (or call the script above), update `Version:` and `Source0:` in `volta.spec`, and stage changes.
* Wire this into CI so a nightly (or weekly) job opens a PR when a newer version exists.

---

## 6) Build scripts & containerized builds

* `container/*Dockerfile` images that install build deps (dnf/zypper), Rust toolchain, and RPM macros.
* `scripts/build-rpm.sh`:

  * Accept `--distro fedora|rhel|opensuse`, `--arch`, `--mode source|bundled`.
  * Run `rpmbuild` inside the matching container; emit artifacts into `dist/<distro>/<arch>/`.
* `scripts/test-in-container.sh`:

  * Install the built RPM in a clean container.
  * Run `volta --version` and a smoke test: `volta help`.
  * Optional: offline check to ensure no network is required for the binary to run.
  * (Skip networked integration like `volta install node` in CI unless quarantined.)

---

## 7) CI/CD (GitHub Actions)

* Workflow `build.yml`:

  * Matrix: `{distro: [fedora-40, rhel-9, opensuse-leap], arch: [x86_64, aarch64]}` (qemu+container for aarch64).
  * Steps: checkout → determine latest → update spec → build (source mode) → test → upload artifacts.
* Release job:

  * On tag `v<version>-rpm`, attach `.rpm` files to the GitHub Release with checksums.
* Scheduled job (weekly) to bump when upstream has a newer tag.

---

## 8) Documentation

* `README.md`: how to build locally, supported distros/arches, quick install via `dnf install ./volta-*.rpm`, and how PATH is set through `/etc/profile.d/volta.sh`.
* `docs/maintenance.md`: how to approve bump PRs, what to do if Cargo deps break, switching to binary-repack temporarily.
* `docs/troubleshooting.md`: common failures (cargo network, missing toolchain), SELinux hints.

---

## 9) Acceptance criteria

* `rpmbuild` succeeds in CI for at least Fedora (source mode).
* Installing the RPM:

  * Places `volta` in `/usr/bin`, `VOLTA_HOME=/usr/lib/volta`, and PATH wired via `/etc/profile.d/*`.
  * `volta --version` shows the packaged version.
* CI automatically detects and proposes updates when upstream releases a new version.
* Artifacts published on a GitHub Release.
* No user dotfiles are modified; no root-owned files under `$HOME`.

