#!/bin/sh
# Prepare source tree for release build

if [ ! -r configure.ac ]; then
	echo Must be run from root of source tree\!
	exit 1
fi

OS=`uname -s`
case "$OS" in
	AIX)
		SED="/opt/freeware/bin/sed"
		;;
	SunOS)
		SED="gsed"
		;;
	*)
		SED="sed"
		;;

esac

set -e

### Code
cd build
./updatetag.pl
cd ..
cp build/netxms-build-tag.properties src/java-common/netxms-base/src/main/resources/ 

VERSION=`cat build/netxms-build-tag.properties | grep NETXMS_VERSION= | cut -d = -f 2`
BASE_VERSION=`cat build/netxms-build-tag.properties | grep NETXMS_BASE_VERSION= | cut -d = -f 2`
QUALIFIER=`cat build/netxms-build-tag.properties | grep NETXMS_VERSION_QUALIFIER= | cut -d = -f 2`

./build/update_plugin_versions.py . $BASE_VERSION $QUALIFIER

cat src/java/netxms-eclipse/Core/plugin.xml | $SED -r "s,^(.*;Version) [0-9.]+(&#x0A.*)\$,\\1 $VERSION\\2," > ./plugin.xml
mv ./plugin.xml src/java/netxms-eclipse/Core/plugin.xml

cat src/java/netxms-eclipse/Product/nxmc.product | $SED -r "s,^Version [0-9.]+\$,Version $VERSION," > nxmc.product
mv ./nxmc.product src/java/netxms-eclipse/Product/nxmc.product

$SED -i -e "s/^AC_INIT.*/AC_INIT([NetXMS], [$VERSION], [bugs@netxms.org])/g" configure.ac

if [ -x ./private/branding/build/prepare_release_build_hook.sh ]; then
	./private/branding/build/prepare_release_build_hook.sh
fi

if [ "x$NO_RECONF" = "x" ]; then
   ./reconf
fi
