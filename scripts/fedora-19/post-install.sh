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
#  2.  Copy the cached .RPM files into the yum directory, so that
#     yum doesn't need to make them again.
#
echo "  Setting up YUM cache"
mkdir -p ${prefix}/var/cache/yum/core/packages/
mkdir -p ${prefix}/var/cache/yum/updates-released/packages/

for i in ${prefix}/*.rpm ; do
    cp $i ${prefix}/var/cache/yum/core/packages/
    cp $i ${prefix}/var/cache/yum/updates-released/packages/
done



#
#  3.  Ensure that Yum has a working configuration file.
#
arch=i386
if [ $ARCH = "amd64" ] ; then
    arch=x86_64
fi

# A correct mirror URL does not contain /Packages on the end
mirror=`dirname $mirror`

echo "  Creating initial yum.conf"
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

echo "  Priming the yum cache"
cp $cache_dir/$dist.$ARCH/* ${prefix}/var/cache/yum/core/packages/

echo "  Bootstrapping yum"
chroot ${prefix} /usr/bin/yum -y install yum vim-minimal dhclient

# Can use regular repositories now
echo "  Creating final yum.conf"
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
echo "  Cleaning up"
chroot ${prefix} /usr/bin/yum clean all

umount ${prefix}/proc
umount ${prefix}/sys


#
#  6.  Remove the .rpm files from the prefix root.
#
echo "  Final tidy..."
rm -f ${prefix}/*.rpm
find ${prefix} -name '*.rpmorig' -delete
find ${prefix} -name '*.rpmnew' -delete

