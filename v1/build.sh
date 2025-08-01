#!/bin/bash

# TODO: replace bash file with cmake

CC=gcc

$CC -o bin/raymp main.c -lm -lpthread
