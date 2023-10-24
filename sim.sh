set -e

iverilog -o build/test test/*.v src/*.v -s $1
vvp build/test

