FROM fedora:40
RUN dnf -y install \
    curl gcc make rust cargo rpm-build rust-packaging \
    && dnf clean all
