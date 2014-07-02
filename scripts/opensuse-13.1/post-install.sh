#!/bin/sh
#
#  Customise the distribution post-install.
#

prefix=$1

if [ ! -d "${prefix}" ]; then
  echo "Serious error - the named directory doesn't exist."
  exit
fi


#
#  2.  Copy the cached .RPM files into the zypper directory, so that
#     zypper doesn't need to fetch them again.
#

mkdir -p ${prefix}/var/cache/zypp/packages/opensuse/suse/${ARCH}
cp -p ${cache_dir}/${dist}.${ARCH}/* ${prefix}/var/cache/zypp/packages/opensuse/suse/${ARCH}

#
#  3.  Ensure that zypper has a working configuration file.
#
arch=i386
if [ $ARCH = "amd64" ] ; then
    arch=x86_64
fi

[ -d "${prefix}/etc/zypp/repos.d" ] || mkdir -p ${prefix}/etc/zypp/repos.d
cat > ${prefix}/etc/zypp/repos.d/${dist}.repo <<EOF
[opensuse]
name=${dist}
baseurl=$(dirname ${mirror})
enabled=1
gpgcheck=1

EOF

if [ $ARCH = "i386" ] ; then
	echo "  Setting architecture to i686"
	sed -i 's/\(# \)\?arch = .*/arch = i686/' ${prefix}/etc/zypp/zypp.conf
fi


#
#  4.  Run "zypper install zypper".
#

echo "  Bootstrapping zypper"

# No /etc/passwd at this point
cat > ${prefix}/etc/passwd <<EOT
root:x:0:0:root:/root:/bin/bash
lp:x:4:7:Printing daemon:/var/spool/lpd:/bin/bash
mail:x:8:12:Mailer daemon:/var/spool/clientmqueue:/bin/false
news:x:9:13:News system:/etc/news:/bin/bash
uucp:x:10:14:Unix-to-Unix CoPy system:/etc/uucp:/bin/bash
man:x:13:62:Manual pages viewer:/var/cache/man:/bin/bash
nobody:x:65534:65533:nobody:/var/lib/nobody:/bin/bash
wwwrun:x:30:8:WWW daemon apache:/var/lib/wwwrun:/bin/false
EOT

cat > ${prefix}/etc/group <<EOT
root:x:0:
tty:x:5:
lp:x:7:
mail:x:12:
news:x:13:
uucp:x:14:
shadow:x:15:
dialout:x:16:
lock:x:54:
EOT

# Need key trusted to prevent warnings during package install
chroot ${prefix} /usr/bin/zypper -n --gpg-auto-import-keys refresh --force-download

# The base system
chroot ${prefix} /usr/bin/zypper -n --no-gpg-checks install aaa_base module-init-tools    2>&1
chroot ${prefix} /usr/bin/zypper -n --no-gpg-checks install zypper vim syslog-ng     2>&1
chroot ${prefix} /usr/bin/zypper -n --no-gpg-checks update              2>&1
chroot ${prefix} /usr/bin/zypper clean

#
#  5.  Clean up
#
umount ${prefix}/proc
umount ${prefix}/sys

#
#  6.  Remove the .rpm files from the prefix root.
#

rm -f  ${prefix}/*.rpm ${prefix}/var/cache/zypp/packages/opensuse/suse/${ARCH}

find ${prefix} -name '*.rpmorig' -delete
find ${prefix} -name '*.rpmnew' -delete
