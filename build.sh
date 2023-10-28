set -e

tool="docker run -it --rm -v $(pwd):/app -u $(id -u):$(id -g) -w /app gcr.io/hdl-containers/impl/icestorm"

rm -rf build
mkdir -p build

python gen_chr_rom.py
python gen_scancode_rom.py
$tool yosys -p "synth_ice40 -top top -json build/ice40.json" src/*.v
$tool nextpnr-ice40 --hx1k --package vq100 --asc build/ice40.asc --pcf ice40hx1k-evb.pcf --json build/ice40.json
$tool icepack build/ice40.asc build/ice40.bin
truncate -s 32K build/ice40.bin
cat build/scancode_rom.bin >> build/ice40.bin
