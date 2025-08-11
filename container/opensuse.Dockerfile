FROM opensuse/leap:latest
RUN zypper --non-interactive install -y curl gcc make rust cargo rpm-build && \
    zypper clean -a
