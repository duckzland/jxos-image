#!/bin/bash

umount /mnt/boot # if you mounted this or any other separate partitions
umount /mnt/{proc,sys,dev}
