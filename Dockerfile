FROM ubuntu:rolling

RUN	apt update \
&&	apt install -y build-essential bison flex texinfo python-dev g++-mingw-w64-x86-64 p7zip-full git curl xz-utils rdfind

WORKDIR /mnt/host

ENTRYPOINT ["bash", "build-bleeding-edge-toolchain.sh", "--skip-documentation", "--enable-win64"]
