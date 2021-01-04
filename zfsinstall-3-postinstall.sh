#!/bin/bash

## After reboot ##
zpool set cachefile=/etc/zfs/zpool.cache vault
systemctl enable zfs.target

# To write the hostid file safely you need to use a small C program:
#include <stdio.h>
#include <errno.h>
#include <unistd.h>

# int main() {
#     int res;
#     res = sethostid(gethostid());
#     if (res != 0) {
#         switch (errno) {
#             case EACCES:
#             fprintf(stderr, "Error! No permission to write the"
#                          " file used to store the host ID.\n"
#                          "Are you root?\n");
#             break;
#             case EPERM:
#             fprintf(stderr, "Error! The calling process's effective"
#                             " user or group ID is not the same as"
#                             " its corresponding real ID.\n");
#             break;
#             default:
#             fprintf(stderr, "Unknown error.\n");
#         }
#         return 1;
#     }
#     return 0;
# }
# Copy it, save it as writehostid.c and compile it with gcc -o writehostid writehostid.c, finally execute it and regenerate the initramfs image:

nano writehostid.c
gcc -o writehostid writehostid.c

chmod +x writehostid
./writehostid
mkinitcpio -p linux
