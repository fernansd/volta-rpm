FROM registry.access.redhat.com/ubi9:latest
RUN dnf -y install \
    curl gcc make rust cargo rpm-build \
    && dnf clean all
