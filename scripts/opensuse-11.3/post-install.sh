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
echo "  Setting up zypper cache"

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
baseurl=$(dirname $(dirname ${mirror}))
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

# Need key trusted to prevent warnings during package install
chroot ${prefix} /usr/bin/zypper -n --gpg-auto-import-keys refresh --force-download
chroot ${prefix} /usr/bin/zypper -n --no-gpg-checks install zypper vim syslog-ng 2>/dev/null
chroot ${prefix} /usr/bin/zypper -n --no-gpg-checks update              2>/dev/null
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
