#!/bin/bash

MERGE_DIRECTORY=""
OUTPUT_DIRECTORY=""
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HACHIKO_DIRECTORY=""
TEMPLATE_DIRECTORY=""
HACHIKO_TINY_DIRECTORY=""
STAGE_MODIFICATIONS="no"

#######################################################################################################################
# Helpers

function print_usage {
cat << EOF

 This script uses the documentation of the Hachiko board to generate the
 one necessary for Hachiko tiny.
 It cleans the merge directory, it copies Hachiko documentation there and
 it overwrites the content of the merge directory with Hachiko tiny
 documentation.
 After that, generate-documentation.sh gets called to generate the final
 result within the output directory.

 Usage: $1 [OPTIONS]

 OPTIONS:
 -h                 Print this help and exit
 -b <directory>     Hachiko documentation directory
 -c <directory>     Hachiko tiny documentation directory
 -t <directory>     Documentation template directory
 -m <directory>     Directory where to merge the documentation
 -o <directory>     Output directory
 -s                 Stage modifications for commit. Not mandatory

EOF
}

#######################################################################################################################
# Options parsing

while getopts "hb:c:t:m:o:s" option
do
    case ${option} in
        h)
            print_usage $0
            exit 0
            ;;
        b)
            HACHIKO_DIRECTORY=${OPTARG}
            ;;
        c)
            HACHIKO_TINY_DIRECTORY=${OPTARG}
            ;;
        t)
            TEMPLATE_DIRECTORY=${OPTARG}
            ;;
        m)
            MERGE_DIRECTORY=${OPTARG}
            ;;
        o)
            OUTPUT_DIRECTORY=${OPTARG}
            ;;
        s)
            STAGE_MODIFICATIONS="yes"
            ;;
        ?)
            print_usage $0
            exit 1
            ;;
    esac
done

[ -n "${MERGE_DIRECTORY}"  ]        || { echo "ERROR: Give me the merge directory."; print_usage $0; exit 1; }
[ -n "${OUTPUT_DIRECTORY}"  ]       || { echo "ERROR: Give me the output directory."; print_usage $0; exit 1; }
[ -n "${TEMPLATE_DIRECTORY}"  ]     || { echo "ERROR: Give me the documentation template directory."; print_usage $0; exit 1; }
[ -n "${HACHIKO_DIRECTORY}"  ]      || { echo "ERROR: Give me the Hachiko documentation directory."; print_usage $0; exit 1; }
[ -n "${HACHIKO_TINY_DIRECTORY}"  ] || { echo "ERROR: Give me the Hachiko tiny documentation directory."; print_usage $0; exit 1; }

if [ "${STAGE_MODIFICATIONS}" == "yes" ]
then
    STAGE_MODIFICATIONS="-s"
else
    STAGE_MODIFICATIONS=""
fi

rm -rf   ${MERGE_DIRECTORY}
mkdir -p ${MERGE_DIRECTORY}

cp -r  ${HACHIKO_DIRECTORY}/*       ${MERGE_DIRECTORY}/
cp -r  ${HACHIKO_TINY_DIRECTORY}/*  ${MERGE_DIRECTORY}/
rm -rf ${MERGE_DIRECTORY}/.git

${SCRIPT_DIRECTORY}/generate-documentation.sh -t ${TEMPLATE_DIRECTORY} -c ${MERGE_DIRECTORY} -o ${OUTPUT_DIRECTORY} ${STAGE_MODIFICATIONS}
