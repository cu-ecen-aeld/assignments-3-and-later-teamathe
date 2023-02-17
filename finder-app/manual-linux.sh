#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

PATH=$PATH:/home/jannikbrun/arm-cross-compiler/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin/  


OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.91
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
SYSROOT=../../arm-cross-compiler/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/
CROSS_COMPILE=../../arm-cross-compiler/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
	
	apt-get update && apt-get install -y bc u-boot-tools kmod cpio flex bison libssl-dev psmisc libelf-dev qemu-system-arm
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
	make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    # TODO: Add your kernel build steps here
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi
mkdir rootfs && cd rootfs && mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
 
# TODO: Create necessary base directories

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi
cd "$OUTDIR/busybox/"
pwd
# TODO: Make and install busybox
make distclean
make defconfig
make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 
make CONFIG_PREFIX="$OUTDIR/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
cd "$OUTDIR/rootfs/"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

cp $SYSROOT/libc/lib/ld-linux-aarch64.so.1 "$OUTDIR"/rootfs/lib/
cp $SYSROOT/libc/lib64/libm.so* "$OUTDIR"/rootfs/lib64/
cp $SYSROOT/libc/lib64/libresolv.so* "$OUTDIR"/rootfs/lib64/
cp $SYSRTOOT/libc/lib64/libc.so* "$OUTDIR"/rootfs/lib64/



# TODO: Make device nodes
mknod -m 660 "$OUTDIR"/rootfs/dev/null c 1 3
mknod -m 660 "$OUTDIR"/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}

make clean
make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH}
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer "$OUTDIR"/rootfs/home
cp finder.sh "$OUTDIR"/rootfs/home
cp finder-test.sh "$OUTDIR"/rootfs/home
mkdir "$OUTDIR"/rootfs/home/conf
cp conf/username.txt "$OUTDIR"/rootfs/home/conf
cp autorun-qemu.sh "$OUTDIR"/rootfs/home

# TODO: Chown the root directory
cd "$OUTDIR"/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"

find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd "$OUTDIR"
gzip -f initramfs.cpio

