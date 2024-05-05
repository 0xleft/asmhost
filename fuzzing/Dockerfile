# syntax=docker/dockerfile-upstream:master-labs
FROM ubuntu:18.04 as afl-builder

RUN apt-get update
RUN apt-get -y install sudo \
    apt-utils \
    build-essential \
    openssl \
    clang \
    graphviz-dev \
    libcap-dev

# Download and compile AFLNet
ENV LLVM_CONFIG="llvm-config-6.0"

ADD --keep-git-dir=true https://github.com/aflnet/aflnet.git /opt/aflnet
WORKDIR /opt/aflnet

RUN make clean all && \
    cd llvm_mode && \
    make

# Set up environment variables for AFLNet
ENV AFLNET="/opt/aflnet"
ENV PATH="${PATH}:${AFLNET}"
ENV AFL_PATH="${AFLNET}"
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1

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

COPY --from=afl-builder /opt/aflnet/afl-fuzz /usr/bin/afl-fuzz
COPY --from=afl-builder /opt/aflnet/afl-clang-fast /usr/bin/afl-clang-fast
COPY --from=afl-builder /opt/aflnet/afl-replay /usr/bin/afl-replay

COPY --from=target-builder /app/src/main .

COPY ./test .
COPY ./fuzzing/fuzz.sh .

CMD ["./fuzz.sh"]