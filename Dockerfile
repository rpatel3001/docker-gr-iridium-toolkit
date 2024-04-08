FROM rust:1.77.0 as builder
WORKDIR /tmp/acars-bridge
# hadolint ignore=DL3008,DL3003,SC1091
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends libzmq3-dev

RUN set -x && \
    git clone https://github.com/sdr-enthusiasts/acars-bridge.git . && \
    cargo build --release && \
    # clean up the apt-cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cp /tmp/acars-bridge/target/release/acars-bridge . && \
    cargo clean

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:soapyrtlsdr

ENV OUTPUT_SERVER="acarshub" \
    OUTPUT_SERVER_PORT="5558" \
    OUTPUT_SERVER_MODE="udp"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY iridium-toolkit.patch /tmp/iridium-toolkit.patch

# hadolint ignore=DL3008,SC2086,DL4006,SC2039
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    TEMP_PACKAGES+=() && \
    # temp
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(gnuradio-dev) && \
    TEMP_PACKAGES+=(libsndfile1-dev) && \
    # keep
    KEPT_PACKAGES+=(python3) && \
    KEPT_PACKAGES+=(python3-prctl) && \
    KEPT_PACKAGES+=(pypy3) && \
    KEPT_PACKAGES+=(gnuradio) && \
    KEPT_PACKAGES+=(gr-osmosdr) && \
    KEPT_PACKAGES+=(libsndfile1) && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    # install pip dependencies
    pypy3 -m pip install --force-reinstall --break-system-packages crcmod zmq && \
    # install iridium-toolkit
    git clone https://github.com/muccc/iridium-toolkit.git /opt/iridium-toolkit && \
    pushd /opt/iridium-toolkit && \
    mv html/map.html html/index.html && \
    rm html/example.sh && \
    git apply /tmp/iridium-toolkit.patch && \
    popd && \
    # install gr-iridium
    git clone https://github.com/muccc/gr-iridium.git /src/gr-iridium && \
    pushd /src/gr-iridium && \
    cmake -B build && \
    cmake --build build -j`nproc` && \
    cmake --install build && \
    ldconfig && \
    popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY --from=builder /tmp/acars-bridge/acars-bridge /opt/acars-bridge
COPY rootfs /
