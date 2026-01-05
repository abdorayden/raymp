#!/bin/bash

set -xe

gcc -ggdb -o main_rmp_manager main_rmp_manager.c rmp_manager.c -llua5.4 -lm -ldl
