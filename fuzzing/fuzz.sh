#!/bin/sh
/opt/aflnet/afl-fuzz -i /app/fuzzing/seed -o out-asmhost -N tcp://127.0.0.1/9001 -P HTTP -m none -d -q 3 -s 3 -K -R -Q -D 20 main