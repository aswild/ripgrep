FROM rust:1-bullseye

RUN set -x && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends asciidoctor && \
    cargo install cargo-deb && \
    chmod -R ugo+rwX $CARGO_HOME

CMD ["bash"]
