#!/bin/bash

sudo apt update -y
sudo apt upgrade -y
sudo apt install -y automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev git libgpiod2 libgpiod-dev
sudo apt install -y cmake gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib gdb-multiarch

cd ~
mkdir pico
cd pico


# install OPENOCD
echo "installing OpenOCD"

git clone https://github.com/raspberrypi/openocd.git --recursive --branch rp2040 --depth=1

cd openocd

./bootstrap

./configure --enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio

make -j4
sudo make install


# install PICO SDK
echo "installing pico-sdk"
cd ~/pico

git clone https://github.com/raspberrypi/pico-sdk.git
cd pico-sdk
git submodule update --init

export PICO_SDK_PATH=~/pico/pico-sdk

echo 'export PICO_SDK_PATH=~/pico/pico-sdk' >> ~/.bashrc
source ~/.bashrc

echo "PICO_SDK Installed"
echo 'export PICO_SDK_PATH=$HOME/pico/pico-sdk'

# install PICO Examples
echo "installing pico-examples"

cd ~/pico

git clone https://github.com/raspberrypi/pico-examples.git

echo "PICO Examples Installed"
echo 'Path is: $HOME/pico/pico-examples'


cd pico-examples

mkdir build
cd build
cmake ..


# modify blink to use pin 26

input_file="$HOME/pico/pico-examples/blink/blink.c"
output_file="$HOME/pico/pico-examples/blink/new_blink.c"
new_define="#define PICO_DEFAULT_LED_PIN 26"

# Check if the replacement has already been completed
if grep -q "$new_define" "$input_file"; then
    echo "LED pin number replacement already completed. Skipping."
else
    sed '/#include "pico\/stdlib.h"/a #undef PICO_DEFAULT_LED_PIN\n#define PICO_DEFAULT_LED_PIN 26' "$input_file" > "$output_file"
    rm "$input_file"
    mv "$output_file" "$input_file"
fi


# build and upload firmware

make blink

openocd -f interface/raspberrypi-swd.cfg -f target/rp2040.cfg -c "program blink/blink.elf verify reset exit"

echo "Completed. Blink program installed."
