#!/bin/bash

set -xe

FLAGS="-ggdb -L./files/third_party/raylib-5.0_linux_amd64/lib/ -I:./files/third_party/raylib-5.0_linux_amd64/include/ -lraylib -lm"

gcc -o main main.c $FLAGS
