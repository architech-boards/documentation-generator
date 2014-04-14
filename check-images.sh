#!/bin/bash

#######################################################################################################################
# Parameters

DOCUMENTATION_DIRECTORY=""
WORKING_DIRECTORY=`pwd`
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MISSING_IMAGES="no"
MISSING_REFERENCES="no"

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
 -i                 Look for missing images.
 -r                 Look for missing references.

EOF
}

#######################################################################################################################
# Options parsing

while getopts "hd:ir" option
do
    case ${option} in
        h)
            print_usage $0
            exit 0
            ;;
        d)
            DOCUMENTATION_DIRECTORY=${OPTARG}
            ;;
        i)
            MISSING_IMAGES="yes"
            ;;
        r)
            MISSING_REFERENCES="yes"
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

if [ "${MISSING_REFERENCES}" == "no" -a "${MISSING_IMAGES}" == "no" ]
then
    echo " ERROR: Please, enable option -r and/or option -i."
    exit 1
fi

cd ${DOCUMENTATION_DIRECTORY}
DOCUMENTATION_DIRECTORY=`pwd`

#######################################################################################################################
# Main

TMP_FILE=`mktemp`

if [ "${MISSING_IMAGES}" == "yes" ]
then
    # Looking for images used by sources but not found under the documentation directory
    find ${DOCUMENTATION_DIRECTORY} -iname "*.rst" -exec grep "^.. image::" '{}' \; | awk -F" " '{print $3}' | sort | uniq > ${TMP_FILE}
    while read CURRENT_IMAGE
    do
        if [ ! -f "${DOCUMENTATION_DIRECTORY}/source/${CURRENT_IMAGE}" ]
        then
            echo " MISSING IMAGE: source/${CURRENT_IMAGE}" 
        fi
    done < ${TMP_FILE}
fi

if [ "${MISSING_REFERENCES}" == "yes" ]
then
    # Looking for images that exists under the documentation directory but not used by sources
    cd ${DOCUMENTATION_DIRECTORY}/source
    ls _static/* > ${TMP_FILE}
    while read CURRENT_IMAGE
    do
        grep "${CURRENT_IMAGE}" ${DOCUMENTATION_DIRECTORY}/source/*.rst > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
            echo " MISSING REFERENCE: source/$CURRENT_IMAGE"
        fi
    done < ${TMP_FILE}
    cd ${WORKING_DIRECTORY}
fi

rm -f ${TMP_FILE}
