Tweaking initrd
===============

All the boot methods have an initrd image somewhere about the place.
In order to make the dashslashdash system work, a few small files need
be added to that to provide the hooks that we hand the rest of the
process on.  This is how you do that.  For details of where you find
the initrd image, look in the relevant HOWTO-<boot_medium>.txt


Once you have a decompressed copy of your initrd (see the relevant
HOWTO-*.txt) loop mount the image:

  mount -o loop /tmp/initrd-2.6 /mnt
or
  mount -o loop /tmp/initrd-2.4 /mnt

and copy on the dashslashdash_0.1_all.udeb:

  wget -N http://hands.com/d-i/udebs/dashslashdash_0.5_all.udeb -O /mnt/tmp/dashslashdash_0.5_all.udeb

In the case of CDs, we also need to pre-unpack netinst-preseed, otherwise
the dashslashdash preseed.sh gets overwritten, so also copy that into place:

  cp d-i-CD/new/pool/main/p/preseed/network-preseed_1.01_all.udeb /mnt/tmp/

then chroot into the initrd:

  chroot /mnt /bin/sh

then unpack the udeb, and discard the udeb itself, and exit the chroot:

  udpkg --unpack /tmp/dashslashdash_0.5_all.udeb
  rm /tmp/dashslashdash_0.5_all.udeb

  udpkg --unpack /tmp/network-preseed_1.01_all.udeb      [for CD initrds]
  rm /tmp/network-preseed_1.01_all.udeb                  [for CD initrds]
  exit

You might want to edit the /mnt/dashslashdash.sh preseed file so that
it defults to your local server rather than http://hands.com, that way
you can audit the files and be sure that I don't subsequently change
them. (Paranoia is your friend).

Then unmount the image:

  umount /mnt

and return to the compression step in the relevant HOWTO-*.txt.

