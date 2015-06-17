#!/bin/bash

sleep 0.4;
#######################################################################
# This script is a part of Kernel-Core v3.3                           #
# Thx to all dev around the world :)                                  #
# neXTerUltim                                                         #
# 2015                                                                #
#                                                                     #
# Structure for building:                                             #
#                                                                     #
#--Quantum-Hammerhead/          (kernel source folder)                #
#------KERNEL-CORE/             (folder for needed files)             #
#--------ramdisk/               (kernel ramdisk for boot.img)         #
#--------toolchain/             (kernel toolchain - Dorimanx GCC5.1)  #
#--------tools/                 (tools to build ramdisk and boot.img) #
#------KERNEL-READY/            (output folder with zip structure)    #
#--------built/                 (already built kernel)                #
#--------kernel/                (kernel structure for .zip)           #
#------INFO/                    (linux kernel default text files)     #
#------env.sh                   (environment file for scripts)        #
#------cleanup.sh               (script to clean junk)                #
#------build.sh                 (script to build kernel)              #
#------defconfig.sh             (script to make defconfig)            #
#######################################################################

export txtbld=$(tput bold)
export txtrst=$(tput sgr0)
export red=$(tput setaf 1)
export bldred=${txtbld}$(tput setaf 1)
export cya=$(tput setaf 6)
export bldcya=${txtbld}$(tput setaf 6)
export grn=$(tput setaf 2)
export bldgrn=${txtbld}$(tput setaf 2)

echo "${bldcya}----- Initializing -----${txtrst}"
sleep 0.4;

export ARCH=arm;
export SUBARCH=arm;
export KERNELDIR=`readlink -f .`;
export CROSS_COMPILE=$KERNELDIR/KERNEL-CORE/toolchain/bin/arm-eabi-;
export RAMDISK=$KERNELDIR/KERNEL-CORE/ramdisk;
export RAMDISKTMP=$KERNELDIR/tmp/ramdisk;
export DEFCONFIG=kernel_defconfig;
export USER=`whoami`;
export TMPFILE=`mktemp -t`;
export NUMBEROFCPUS=`grep 'processor' /proc/cpuinfo | wc -l`;

CHECK()
{
	if [ ! -f ${CROSS_COMPILE}gcc ]; then
		echo "${bldred}----- ERROR: Cannot find GCC compiler -----${txtrst}";
		exit 1;
	fi
	if [ ! -f ${RAMDISK}/init ]; then
		echo "${bldred}----- ERROR: Cannot find ramdisk -----${txtrst}";
		exit 1;
	fi
	if [ ! -f $KERNELDIR/KERNEL-CORE/tools/mkbootfs ] || [ ! -f $KERNELDIR/KERNEL-CORE/tools/mkbootimg ]; then
		echo "${bldred}----- ERROR: Cannot find build tools -----${txtrst}";
		exit 1;
	fi
	if [ ! -e /usr/bin/parallel ]; then
		echo "----- ERROR: You must install 'parallel' to continue -----";
		sudo apt-get install parallel
	fi
	if [ ! -e /usr/bin/ccache ]; then
		echo "----- ERROR: You must install 'ccache' to continue -----";
		sudo apt-get install ccache
	fi
	if [ ! -e $KERNELDIR/KERNEL-READY/built ]; then
		mkdir $KERNELDIR/KERNEL-READY/built
	fi
}
sleep 0.4;

CONFIG()
{
	if [ -f $KERNELDIR/arch/arm/configs/$DEFCONFIG ]; then
		echo "${bldgrn}----- Defconfig was found -----${txtrst}";
	else
		echo "${bldcya}----- Making defconfig -----${txtrst}";
		if [ ! -e arch/arm/configs/hammerhead_defconfig ]; then
			echo "${bldred}----- ERROR: Hammerhead Defconfig wasn't found -----${txtrst}";
			exit -1;
		fi

		make hammerhead_defconfig;
		make menuconfig;
		rm -rf arch/arm/configs/*;
		mv .config arch/arm/configs/$DEFCONFIG;
	fi
}
sleep 0.4;

CLEAN()
{
	echo "${bldcya}----- Cleaning -----${txtrst}";
	make mrproper;
	make clean;
	rm -rf $RAMDISKTMP >> /dev/null;
	rm -f $KERNELDIR/arch/arm/boot/*.dtb >> /dev/null;
	rm -f $KERNELDIR/arch/arm/boot/*.cmd >> /dev/null;
	rm -f $KERNELDIR/arch/arm/boot/zImage-dtb >> /dev/null;
	rm -f $KERNELDIR/arch/arm/mach-msm/smd_rpc_sym.c >> /dev/null;
	rm -f $KERNELDIR/arch/arm/crypto/aesbs-core.S >> /dev/null;
	rm -f $KERNELDIR/r*.cpio >> /dev/null;
	rm -f $KERNELDIR/ramdisk.tzo >> /dev/null;
	rm -rf $KERNELDIR/include/generated >> /dev/null;
	rm -rf $KERNELDIR/arch/*/include/generated >> /dev/null;
	rm -f $KERNELDIR/zImage >> /dev/null;
	rm -f $KERNELDIR/KERNEL-READY/kernel/zImage >> /dev/null;
	rm -f $KERNELDIR/zImage-dtb >> /dev/null;
	rm -f $KERNELDIR/KERNEL-READY/kernel/boot.img >> /dev/null;
	rm -f $KERNELDIR/boot.img >> /dev/null;
	rm -f $KERNELDIR/dt.img >> /dev/null;
	rm -rf $KERNELDIR/KERNEL-READY/kernel/system/lib/modules >> /dev/null;
	rm -rf $KERNELDIR/KERNEL-READY/kernel/tmp_modules >> /dev/null;
	rm -rf $KERNELDIR/tmp >> /dev/null;
	find . -type f \( -iname \*.rej \
					-o -iname \*.orig \
					-o -iname \*.bkp \
					-o -iname \*.ko \
					-o -iname \*.c.BACKUP.[0-9]*.c \
					-o -iname \*.c.BASE.[0-9]*.c \
					-o -iname \*.c.LOCAL.[0-9]*.c \
					-o -iname \*.c.REMOTE.[0-9]*.c \
					-o -iname \*.org \) \
						| parallel rm -fv {};
	echo "${bldgrn}----- Cleaning was done -----${txtrst}";
}
sleep 0.4;

BUILD()
{
	echo "${bldcya}----- Generating Ramdisk -----${txtrst}";
	sleep 0.4;
	echo "0" > $TMPFILE;
	if [ -d $RAMDISKTMP ]; then
		rm -rf $RAMDISKTMP;
	fi;
	mkdir -p $RAMDISKTMP;
	cp -ax $RAMDISK/* $RAMDISKTMP;
	find $RAMDISKTMP -name EMPTY_DIRECTORY | parallel rm -rf {};

	./KERNEL-CORE/tools/mkbootfs $RAMDISKTMP | lzop > ramdisk.tzo
	echo "1" > $TMPFILE;
	echo "${bldgrn}----- Ramdisk Generation Completed Successfully -----${txtrst}";
	sleep 0.4;

	echo "${bldgrn}----- Build Initiating -----${txtrst}";
	sleep 0.4;
	cp $KERNELDIR/arch/arm/configs/$DEFCONFIG .config;
	make $DEFCONFIG;

	. $KERNELDIR/.config

	VERSION=`grep 'Quantum_v.*' $KERNELDIR/.config | sed 's/.*_.//g' | sed 's/".*//g'`
	echo "${bldgrn}----- Building -> Kernel v${VERSION} -----${txtrst}";
	sleep 0.4;

	while [ $(cat ${TMPFILE}) == 0 ]; do
		echo "${bldcya}----- Waiting for Ramdisk generation completion -----${txtrst}";
		sleep 2;
	done;

	echo "${bldgrn}----- Compiling kernel -----${txtrst}"
	sleep 0.4;

	make -j$NUMBEROFCPUS zImage-dtb

	if [ -e $KERNELDIR/arch/arm/boot/zImage-dtb ]; then
		echo "${bldgrn}----- Creating boot.img -----${txtrst}";
		sleep 0.4;
		cp $KERNELDIR/arch/arm/boot/zImage-dtb $KERNELDIR/zImage-dtb;
		./KERNEL-CORE/tools/mkbootimg --kernel zImage-dtb --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=hammerhead user_debug=31 msm_watchdog_v2.enable=1' --base 0x00000000 --pagesize 2048 --kernel_offset 0x00008000 --ramdisk_offset 0x02900000 --tags_offset 0x02700000 --ramdisk ramdisk.tzo --output boot.img

		cp $KERNELDIR/boot.img /$KERNELDIR/KERNEL-READY/kernel/
		cd $KERNELDIR/KERNEL-READY/kernel/
		zip -r Kernel_v${VERSION}.zip .
		if [ -f $KERNELDIR/KERNEL-READY/built/Quantum_v${VERSION}.zip ]; then
			echo "${bldcya}----- Already built kernel was found. Deleting -----";
			rm -rf $KERNELDIR/KERNEL-READY/built/Quantum_v${VERSION}.zip
			sleep 0.4;
		fi;
		mv Kernel_v* $KERNELDIR/KERNEL-READY/built/Quantum_v${VERSION}.zip;
		echo "${bldgrn}----- Kernel was successfully built -----${txtrst}";
		sleep 0.4;
		cd && cd $KERNELDIR
		CLEAN;
		echo "${bldgrn}----- Finished! -----${txtrst}";
	else
		echo "${bldred}----- ERROR: Kernel STUCK in BUILD! -----${txtrst}";
		CLEAN;
	fi;
}
