#!/bin/bash
mount -t ext3 /dev/sda1 /mnt
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
