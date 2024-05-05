FROM ubuntu:18.04 as builder

RUN apt-get update && apt-get install -y \
    build-essential \
    nasm \
    gcc

WORKDIR /app
COPY . .

RUN cd src && nasm main.asm -f elf && ld -m elf_i386 -s -o main main.o

FROM ubuntu:18.04 as runner

WORKDIR /app
COPY --from=builder /app/src/main .
COPY ./test .

EXPOSE 8080

CMD ["./main", "8080"]