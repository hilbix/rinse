#!/bin/sh
#
#  Customise the distribution post-install.
#


prefix=$1

if [ ! -d "${prefix}" ]; then
  echo "Serious error - the named directory doesn't exist."
  exit
fi

arch=i386
if [ $ARCH = "amd64" ] ; then
    arch=x86_64
fi

#
#  2.  Copy the cached .RPM files into the yum directory, so that
#     yum doesn't need to download them again.
#
echo "  Setting up YUM cache"
mkdir -p ${prefix}/var/cache/yum/core/packages/

for i in ${prefix}/*.rpm ; do
    cp -p $i ${prefix}/var/cache/yum/core/packages/
done

cp -pu $cache_dir/$dist.$ARCH/* ${prefix}/var/cache/yum/core/packages/


#
#  3.  Ensure that Yum has a working configuration file.
#

# use the mirror URL which was specified in rinse.conf
# A correct mirror URL does not contain /Packages on the end
mirror=`dirname $mirror`

cat > ${prefix}/etc/yum.conf <<EOF
[main]
reposdir=/dev/null
logfile=/var/log/yum.log

[core]
name=core
baseurl=$mirror
EOF


#
#  4.  Run "yum install yum".
#

echo "  Bootstrapping yum"
chroot ${prefix} /usr/bin/yum -y install yum vim-minimal dhclient

# Can use regular repositories now
cat > ${prefix}/etc/yum.conf <<EOF
[main]
logfile=/var/log/yum.log
gpgcheck=1

# PUT YOUR REPOS HERE OR IN separate files named file.repo
# in /etc/yum.repos.d
EOF


#
#  5.  Clean up
#
chroot ${prefix} /usr/bin/yum clean all

umount ${prefix}/proc
umount ${prefix}/sys


#
#  6.  Remove the .rpm files from the prefix root.
#
rm -f ${prefix}/*.rpm ${prefix}/var/cache/yum/core/packages/*.rpm

find ${prefix} -name '*.rpmorig' -delete
find ${prefix} -name '*.rpmnew' -delete
