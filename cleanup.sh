#!/bin/bash

. ./env.sh ${1} || exit 1;
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

CLEAN;
