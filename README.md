# docker-gr-iridium-toolkit
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/rpatel3001/docker-gr-iridium-toolkit/deploy.yml?branch=master)](https://github.com/rpatel3001/docker-gr-iridium-toolkit/actions/workflows/deploy.yml)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

A Docker image to use the [gr-iridium](https://github.com/muccc/gr-iridium) and [iridium-toolkit](https://github.com/muccc/iridium-toolkit) software from the [Chaos Computer Club München](https://muc.ccc.de/) to parse ACARS messages on the Iridium network.

Under active development, everything is subject to change without notice.

---

## Docker Compose

```
services:
  irdm:
    container_name: irdm
    hostname: irdm
    image: ghcr.io/rpatel3001/docker-gr-iridium-toolkit
#    build: docker-gr-iridium-toolkit
    restart: always
    tty: true # actually needed, for iridium-parser.py
    ports:
      - 8888:8888 # for beam map
      - 8889:8889 # for mt map
    device_cgroup_rules:
      - 'c 189:* rwm'
    volumes:
      - /dev:/dev:rw
      - ./irdm.conf:/opt/irdm.conf:ro
    environment:
#      - ENABLE_MTPOS_MAP=true
#      - ENABLE_MTPOS_MAP_LOG=true
#      - DISABLE_EXTRACTOR=true
#      - LOG_EXTRACTOR_STATS=true
#      - LOG_MAP=true
#      - EXTRACTOR_ARGS= -D 8  # Valid values when running high sample rate are 1, 2, 4, 8 and 16
      - PARSER_ARGS= --harder --uw-ec # runs slower, remove uw-ec then harder if message rate is high
      - STATION_ID=XX-YYYY-IRDM
      - OUTPUT_SERVER=acarshub
      - OUTPUT_SERVER_PORT=5558
```

irdm.conf has details of your SDR device. Full details can be found [here](https://github.com/muccc/gr-iridium?tab=readme-ov-file#configuration-file). An example for using an RTL-SDR with max gain and bias-tee enabled:

```
[osmosdr-source]
sample_rate=2500000
center_freq=1625600000

# Uncomment to use the RTL-SDR's Bias Tee if available
device_args='rtl=0,bias=1'

# Automatic bandwidth
bandwidth=0

# LNA gain
gain=49.6
```
