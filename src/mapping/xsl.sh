#!/bin/bash

JAVA="java"
READLINK="readlink"

export LANG=en_US.UTF-8

# Do not assume the script is invoked from the directory it is located in; get
# the directory the script is located in
thisDir="$(dirname "$(${READLINK} -f "$0")")"

# Get Saxon
if [ ! -f ${thisDir}/tlasaxon.jar ]; then
    wget -O tlasaxon.jar https://github.com/TLA-FLAT/SaxonUtils/releases/download/2.0-RC5/tlasaxon.jar
fi
JAR=${thisDir}/tlasaxon.jar

${JAVA} -jar ${JAR} $*
ERR="$?"

exit $ERR