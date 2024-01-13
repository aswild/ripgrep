FROM rust:1-bookworm

RUN set -x && \
    apt-get update && \
    apt-get -y upgrade && \
    cargo install cargo-deb && \
    chmod -R ugo+rwX $CARGO_HOME

CMD ["bash"]
