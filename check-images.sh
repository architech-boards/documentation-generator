#!/bin/bash

#######################################################################################################################
# Parameters

DOCUMENTATION_DIRECTORY=""
WORKING_DIRECTORY=`pwd`
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#######################################################################################################################
# Helpers

function print_usage {
cat << EOF

 This is an utility used to check the correctness of the documentation
 images. 

 Usage: $1 [options]

 OPTIONS:
 -h                 Print this help and exit
 -d <directory>     The directory where the documentation is located.

EOF
}

#######################################################################################################################
# Options parsing

while getopts "hd:" option
do
    case ${option} in
        h)
            print_usage $0
            exit 0
            ;;
        d)
            DOCUMENTATION_DIRECTORY=${OPTARG}
            ;;
        ?)
            print_usage $0
            exit 1
            ;;
    esac
done

#######################################################################################################################
# Input parameters check

[ -n "${DOCUMENTATION_DIRECTORY}" -a -d "${DOCUMENTATION_DIRECTORY}" ] || { print_usage $0; exit 1; }

cd ${DOCUMENTATION_DIRECTORY}
DOCUMENTATION_DIRECTORY=`pwd`

#######################################################################################################################
# Main

TMP_FILE=`mktemp`

# Looking for images used by sources but not found under the documentation directory
find ${DOCUMENTATION_DIRECTORY} -iname "*.rst" -exec grep "^.. image::" '{}' \; | awk -F" " '{print $3}' | sort | uniq > ${TMP_FILE}
while read CURRENT_IMAGE
do
    if [ ! -f "${DOCUMENTATION_DIRECTORY}/source/${CURRENT_IMAGE}" ]
    then
        echo " WARNING: Image ${CURRENT_IMAGE} missing from the documentation." 
    fi
done < ${TMP_FILE}

# Looking for images that exists under the documentation directory but not used by sources
cd ${DOCUMENTATION_DIRECTORY}/source
ls _static/* > ${TMP_FILE}
while read CURRENT_IMAGE
do
    grep "${CURRENT_IMAGE}" ${DOCUMENTATION_DIRECTORY}/source/*.rst > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo " WARNING: $CURRENT_IMAGE not referenced by sources."
    fi
done < ${TMP_FILE}
cd ${WORKING_DIRECTORY}

rm -f ${TMP_FILE}
