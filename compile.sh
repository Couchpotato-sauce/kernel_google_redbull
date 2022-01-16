#!/bin/sh

# Clone clang from defined repo
git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang cloned-clang

# Clone arter97's arm64-gcc and arm32-gcc repo's
git clone --depth=1 https://github.com/arter97/arm64-gcc arm64-gcc
git clone --depth=1 https://github.com/arter97/arm32-gcc arm32-gcc

# Clone Kramflash
git clone --depth=1 https://github.com/Couchpotato-sauce/kramflash kramflash

# Export the PATH variable
export PATH="$(pwd)/cloned-clang/bin:/$(pwd)/arm32-gcc/bin:$(pwd)/arm64-gcc/bin:${PATH}"

# Clean up out
find out -delete
mkdir out

# Setup the build environment
source setup.sh

# Make config
mc

# Build the kernel
kmake 

# Create payload dir under kramflash/rd 
mkdir -p kramflash/rd/payload

# Concate the DTB and copy the concated DTB and Image.lz4 to kramflash/rd/payload
cat out/arch/arm64/boot/dts/google/*.dtb > dtb
cp dtb kramflash/rd/payload/dtb
cp out/arch/arm64/boot/Image.lz4 kramflash/rd/payload/Image.lz4

# Install pigz as its required to pack the image
apt install -y pigz

cd kramflash

# Pack the image containing the compiled kernel and a bootable alpine ramdisk used to flash the kernel
bash pack-img.sh

# Set some variables required to rename the image created by pack-image.sh
BUILD_TIME=$(date +"%d%m%Y-%H%M")
KERNEL_NAME=Sleepy-"${BUILD_TIME}"

# Rename the image created by pack-image.sh using above created variables
mv flash.img "$KERNEL_NAME".img

FILE="$KERNEL_NAME".img
if [ -f "$FILE" ]; then
    echo "The kernel has successfully been compiled and can be found in $(pwd)/"$KERNEL_NAME".img"
    FILE_CI="$KERNEL_NAME".img
    if [ -f "$FILE_CI" ]; then
        curl --connect-timeout 10 -T "$FILE_CI" https://oshi.at
        curl --connect-timeout 10 --upload-file "$FILE_CI" https://transfer.sh
        echo " "
    fi
else
    echo "The kernel has failed to compile. Please check the terminal output for further details."
    exit 1
fi
