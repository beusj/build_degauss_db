# Stage 1: Build env
FROM debian:12-slim as build

ARG DATA_YEAR=2025

# Non-interactive config for tzdata install
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
RUN apt-get update && apt-get install -y tzdata
RUN dpkg-reconfigure --frontend noninteractive tzdata  # Optional; sets to UTC

RUN apt-get update && \
    apt-get install -y awscli unzip \
    sqlite3 libsqlite3-dev \ 
    sudo build-essential \ 
    pkg-config flex \
    wget curl git ruby ruby-dev \
    make

RUN gem install sqlite3 json Text

WORKDIR /workspace
COPY Makefile.ruby .
COPY /src ./src
COPY /lib ./lib
COPY /gemspec ./gemspec
COPY /build ./build

RUN make -f Makefile.ruby install \
    && gem install Geocoder-US-2.0.4.gem

RUN chmod +x build/tiger_import build/build_indexes build/rebuild_cluster build/rebuild_metaphones

COPY entrypoint.sh /workspace/entrypoint.sh
RUN chmod +x /workspace/entrypoint.sh
CMD ["/workspace/entrypoint.sh"]