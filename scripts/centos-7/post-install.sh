#!/bin/sh
#
#  post-install.sh
#  CentOS 7

prefix=$1

if [ ! -d "${prefix}" ]; then
  echo "Serious error - the named directory doesn't exist."
  exit
fi

# rpm's can now be removed
rm -f ${prefix}/*.rpm

touch ${prefix}/etc/mtab


# add command, that are normally executed in postinst or similar
mv $prefix/var/run/* $prefix/run
rmdir $prefix/var/run
ln -s /run $prefix/var/run
ln -s /run/lock $prefix/var/lock

chroot $prefix alternatives --install /usr/bin/ld ld   /usr/bin/ld.bfd 50
chroot $prefix alternatives --install /usr/bin/ld ld   /usr/bin/ld.gold 30
chroot $prefix alternatives --auto ld

chroot $prefix groupadd -g 22 -r -f utmp
chroot $prefix touch /var/log/wtmp /var/run/utmp /var/log/btmp
chroot $prefix chown root:utmp /var/log/wtmp /var/run/utmp /var/log/btmp
chroot $prefix chmod 664 /var/log/wtmp /var/run/utmp
chroot $prefix chmod 600 /var/log/btmp

chroot $prefix groupadd -g 35 -r -f utempter
chroot $prefix groupadd -g 21 -r -f slocate

install -m 600 /dev/null $prefix/var/log/tallylog

cd $prefix/var/log
for n in messages secure maillog spooler;do
	[ -f $n ] && continue
	umask 066 && touch $n
done
cd /
touch $prefix/var/log/lastlog
chown root:root $prefix/var/log/lastlog
chmod 0644 $prefix/var/log/lastlog

ln -fs /proc/mounts $prefix/etc/mtab


echo "  Bootstrapping yum"
chroot ${prefix} /usr/bin/yum -y install yum vim-minimal dhclient 2>/dev/null

echo "  cleaning up..."
chroot ${prefix} /usr/bin/yum clean all 
umount ${prefix}/proc
umount ${prefix}/sys

# Install modprobe
if [ -e "${prefix}/etc/modprobe.d/modprobe.conf.dist" ]; then
    cp  "${prefix}/etc/modprobe.d/modprobe.conf.dist" "${prefix}/etc/modprobe.conf"
fi

echo "  post-install.sh : done."
