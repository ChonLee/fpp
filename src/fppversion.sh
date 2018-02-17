#!/bin/sh
#
# Copied from MythTV version.sh
#
# small shell script to generate version.cpp
# it expects one parameter
# first parameter is the root of the source directory

if test $# -ne 1; then
    echo "Usage: version.sh GIT_TREE_DIR"
    exit 1
fi

TESTFN=`mktemp $1/.test-write-XXXXXX` 2> /dev/null
if test x$TESTFN != x"" ; then
    rm -f $TESTFN
else
    echo "$0: Can not write to destination, skipping.."
    exit 0
fi

GITTREEDIR=$1
GITREPOPATH="exported"

cd ${GITTREEDIR}

git status > /dev/null 2>&1
SOURCE_VERSION=$(git describe --dirty || git describe || echo Unknown)
MAJOR_VERSION=$(echo ${SOURCE_VERSION} | cut -f1 -d\.)
MINOR_VERSION=$(echo ${SOURCE_VERSION} | cut -f1 -d- | cut -f2 -d\.)

if [ "x${MINOR_VERSION}" = "xx" ]
then
	MINOR_VERSION=0
fi

case "${SOURCE_VERSION}" in
    exported|Unknown)
        if ! grep -q Format $GITTREEDIR/EXPORTED_VERSION; then
            . $GITTREEDIR/EXPORTED_VERSION
            BRANCH=$(echo "${BRANCH}" | sed 's/ (\(.*, \)\{0,1\}\(.*\))/\2/')
        elif test -e $GITTREEDIR/VERSION ; then
            . $GITTREEDIR/VERSION
        fi
    ;;
    *)
        #SOURCE_VERSION=$(echo "${SOURCE_VERSION}" | cut -f1-3 -d'-')
        if [ -z "${BRANCH}" ]; then
            BRANCH=$(git branch --no-color | sed -e '/^[^\*]/d' -e 's/^\* //' -e 's/(no branch)/exported/')
        fi
    ;;
esac

cat > fppversion.c.new <<EOF
#include <stdio.h>

#include "log.h"

char *getFPPVersion(void) {
	return "${SOURCE_VERSION}";
}

char *getFPPMajorVersion(void) {
	return "${MAJOR_VERSION}";
}

char *getFPPMinorVersion(void) {
	return "${MINOR_VERSION}";
}

char *getFPPBranch(void) {
	return "${BRANCH}";
}

void printVersionInfo(void) {
	printf("=========================================\n");
	printf("FPP v%s\n", getFPPVersion());
	printf("Branch: %s\n", getFPPBranch());
	printf("=========================================\n");
}

EOF

# check if the version strings are changed and update version.pro if necessary
if ! cmp -s fppversion.c.new fppversion.c; then
   mv -f fppversion.c.new fppversion.c
fi
rm -f fppversion.c.new

