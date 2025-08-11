# Maintenance

1. Run `./scripts/get-latest-volta.sh` to check for a new upstream release.
2. If a newer version exists, update the spec with `./scripts/update-spec-version.sh <version>`.
3. Build and test the RPM:
   ```bash
   ./scripts/build-rpm.sh --distro fedora --arch x86_64 --mode source
   ./scripts/test-in-container.sh dist/fedora/x86_64/volta-*.rpm
   ```
4. Commit the changes and open a pull request.
5. If source builds fail due to dependency issues, temporarily build in `--mode bundled` to use the upstream binary.
