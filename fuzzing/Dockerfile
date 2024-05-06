FROM ubuntu:18.04 as afl-builder

RUN apt-get update
RUN apt-get -y install sudo \
    apt-utils \
    build-essential \
    openssl \
    clang \
    graphviz-dev \
    libcap-dev \
    libtool-bin \
    wget \
    python \
    automake \
    autoconf \
    bison \
    libglib2.0-dev

# Download and compile AFLNet
# ENV LLVM_CONFIG="llvm-config-6.0"

ADD --keep-git-dir=true https://github.com/0xleft/aflnet.git /opt/aflnet
WORKDIR /opt/aflnet

RUN make clean all && \
    cd qemu_mode && \
    chmod +x build_qemu_support.sh && \
    ./build_qemu_support.sh

# Set up environment variables for AFLNet
ENV AFLNET="/opt/aflnet"
ENV PATH="${PATH}:${AFLNET}"
ENV AFL_PATH="${AFLNET}"

FROM ubuntu:18.04 as target-builder

RUN apt-get update && apt-get install -y \
    build-essential \
    nasm \
    gcc

WORKDIR /app
COPY . .

RUN cd src && nasm main.asm -f elf && ld -m elf_i386 -s -o main main.o

FROM ubuntu:18.04 as runner

WORKDIR /app

RUN apt-get update && apt-get -y install graphviz-dev libcap-dev

COPY --from=afl-builder /opt/aflnet /opt/aflnet
COPY --from=target-builder /app/fuzzing /app/fuzzing
COPY --from=target-builder /app/src/main /usr/bin/main
RUN chmod +x /usr/bin/main

COPY ./test .
COPY ./fuzzing/fuzz.sh .

RUN chmod +x fuzz.sh

CMD ["./fuzz.sh"]