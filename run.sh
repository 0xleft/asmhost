set -e

cd src
rm -f main
nasm main.asm -f elf
ld -m elf_i386 -s -o main main.o
rm main.o
./main $@
rm -f main
cd ..