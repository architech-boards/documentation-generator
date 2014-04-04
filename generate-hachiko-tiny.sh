#!/bin/bash

HACHIKO_DIRECTORY=""
HACHIKO_TINY_DIRECTORY=""

#######################################################################################################################
# Helpers

function print_usage {
cat << EOF

 This uses the documentation of the Hachiko to generate the
 one necessary for Hachiko tiny.

 Usage: $1 [options]

 OPTIONS:
 -h                 Print this help and exit
 -o <directory>     Hachiko documentation directory
 -t <directory>     Hachiko tiny documentation directory

EOF
}

function clean_hachiko_tiny_directory {
    local TO_CLEAN

    TO_CLEAN=$1
    rm -f  ${TO_CLEAN}/source/*.rst
}

#######################################################################################################################
# Options parsing

while getopts "ht:c:o:" option
do
    case ${option} in
        h)
            print_usage $0
            exit 0
            ;;
        o)
            HACHIKO_DIRECTORY=${OPTARG}
            ;;
        t)
            HACHIKO_TINY_DIRECTORY=${OPTARG}
            ;;
        ?)
            print_usage $0
            exit 1
            ;;
    esac
done

[ -n "${HACHIKO_DIRECTORY}"  ]      || { echo "ERROR: Give me the Hachiko documentation directory."; print_usage $0; exit 1; }
[ -n "${HACHIKO_TINY_DIRECTORY}"  ] || { echo "ERROR: Give me the Hachiko tiny documentation directory."; print_usage $0; exit 1; }

clean_hachiko_tiny_directory    ${HACHIKO_TINY_DIRECTORY}

cp ${HACHIKO_DIRECTORY}/source/*.rst ${HACHIKO_TINY_DIRECTORY}/source
