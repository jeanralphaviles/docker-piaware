FROM debian:bullseye as builder

ENV PIAWARE_VERSION 7.2

RUN apt update && \
    apt install -y \
      autoconf \
      build-essential \
      debhelper \
      devscripts \
      git \
      libboost-filesystem-dev \
      libboost-program-options-dev \
      libboost-regex-dev \
      libboost-system-dev \
      libz-dev \
      patchelf \
      python3-dev \
      python3-setuptools \
      python3-venv \
      socat \
      tcl8.6-dev \
      wget

# Workaround from version 3.8.1. Should be removed in the future.
RUN apt install -y libssl-dev tcl-dev chrpath
RUN git clone http://github.com/flightaware/tcltls-rebuild.git /tcltls-rebuild
WORKDIR /tcltls-rebuild
RUN ./prepare-build.sh bullseye
WORKDIR /tcltls-rebuild/package-bullseye
RUN dpkg-buildpackage -b
RUN apt install -y ../tcl-tls_*.deb

RUN git clone https://github.com/flightaware/piaware_builder.git /piaware_builder
WORKDIR /piaware_builder
RUN git fetch --all --tags && git checkout tags/v${PIAWARE_VERSION}
RUN ./sensible-build.sh bullseye
WORKDIR /piaware_builder/package-bullseye
RUN dpkg-buildpackage -b
RUN apt install -y ../piaware_*.deb

FROM debian:bullseye

ENV MLAT yes

RUN apt update && \
    apt install -y \
      itcl3 \
      libtcl8.6 \
      socat \
      tcl8.6-dev \
      tcllib \
      tclx8.4 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/bin/piaware /usr/bin/piaware
COPY --from=builder /usr/lib/piaware /usr/lib/piaware
COPY --from=builder /usr/bin/piaware-config /usr/bin/piaware-config
COPY --from=builder /usr/lib/piaware-config /usr/lib/piaware-config
COPY --from=builder /usr/lib/piaware_packages /usr/lib/piaware_packages
COPY --from=builder /usr/lib/Tcllauncher1.8 /usr/lib/Tcllauncher1.8
COPY --from=builder /usr/lib/tcltk /usr/lib/tcltk
COPY --from=builder /usr/lib/fa_adept_codec /usr/lib/fa_adept_codec
COPY --from=builder /etc/piaware.conf /etc/piaware.conf

WORKDIR /
COPY start.sh /
RUN chmod +x /start.sh

ENTRYPOINT [ "/start.sh" ]
