#!/bin/bash

#######################################################################################################################
# Parameters

TEMPLATE_DIRECTORY=""
CUSTOMIZATIONS_DIRECTORY=""
OUTPUT_DIRECTORY=""

#######################################################################################################################
# Helpers

function print_usage {
cat << EOF

 This program takes a documentation template and customizations
 as inputs and produces a merged documentation as output.

 Usage: $1 [options]

 OPTIONS:
 -h                 Print this help and exit
 -t <directory>     Documentation template directory
 -c <directory>     Documentation customizations directory
 -o <directory>     Where to place the output.

EOF
}

function clean_git_directory {
    local TO_CLEAN
    local TO_DELETE
    local TO_DELETE_LIST

    TO_CLEAN=$1
    TO_DELETE_LIST=`ls -a ${TO_CLEAN} | grep -v "^.$" | grep -v "^..$" | grep -v "^.git"`
    for TO_DELETE in ${TO_DELETE_LIST}
    do
        rm -rf ${TO_CLEAN}/${TO_DELETE}
    done
}

function copy_git_directory {
    local SOURCE
    local DESTINATION

    SOURCE=$1
    DESTINATION=$2

    rsync -a ${SOURCE} ${DESTINATION} --exclude build --exclude *.manifest --exclude *.keys --exclude .git* --exclude *.append --exclude *.prepend
}

function do_append {
    local SOURCE
    local DESTINATION
    local TO_APPEND_LIST
    local TO_APPEND

    SOURCE=$1
    DESTINATION=$2
    TO_APPEND_LIST=`cd ${SOURCE} && find . -iname "*.append"`
    for TO_APPEND in ${TO_APPEND_LIST}
    do
        TO_APPEND=${TO_APPEND:0:${#TO_APPEND}-7}
        cat ${SOURCE}/${TO_APPEND}.append >> ${DESTINATION}/${TO_APPEND}
    done
}

function do_prepend {
    local SOURCE
    local DESTINATION
    local TO_PREPEND_LIST
    local TO_PREPEND

    SOURCE=$1
    DESTINATION=$2
    TO_PREPEND_LIST=`cd ${SOURCE} && find . -iname "*.prepend"`
    for TO_PREPEND in ${TO_PREPEND_LIST}
    do
        TO_PREPEND=${TO_PREPEND:0:${#TO_PREPEND}-8}
        mv ${DESTINATION}/${TO_PREPEND} ${DESTINATION}/${TO_PREPEND}.prepend.tmp
        cp ${SOURCE}/${TO_PREPEND}.prepend ${DESTINATION}/${TO_PREPEND}
        cat ${DESTINATION}/${TO_PREPEND}.prepend.tmp >> ${DESTINATION}/${TO_PREPEND}
        rm ${DESTINATION}/${TO_PREPEND}.prepend.tmp
    done
}

function find_and_replace_in_place_recursive {
    local DIRECTORY
    local TEMPLATE
    local VALUE
    local MATCHING_FILE
    local MATCHING_FILES

    DIRECTORY=$1
    TEMPLATE=$2
    VALUE=$3

    MATCHING_FILES=`find ${DIRECTORY} -iname "*.rst" -exec grep -l "${TEMPLATE}" '{}' \;`
    for MATCHING_FILE in ${MATCHING_FILES}
    do
        sed -i "s|${TEMPLATE}|${VALUE}|g" ${MATCHING_FILE}
    done
}

function get_string_filled_with_char {
    local CHARACTER
    local SIZE
    local STRING
    SIZE=$1
    CHARACTER=$2
    STRING=""
    while [[ ${#STRING} -lt ${SIZE} ]]
    do
        STRING=${CHARACTER}${STRING}
    done
    echo ${STRING}
}

function fill_title_bars {
    local DIRECTORY
    local TEMPLATE
    local TEMPLATE_SIZE
    local VALUE
    local VALUE_SIZE
    local CHARACTERS_LIST
    local REPLACE_WITH
    local CURRENT_TEMPLATE
    local CHARACTER

    DIRECTORY=$1
    TEMPLATE=$2
    VALUE=$3
    TEMPLATE_SIZE=${#TEMPLATE}
    TEMPLATE=${TEMPLATE:1:${TEMPLATE_SIZE}-2}
    VALUE_SIZE=${#VALUE}
    
    CHARACTERS_LIST="= - ^"
    for CHARACTER in ${CHARACTERS_LIST}
    do
        REPLACE_WITH=$(get_string_filled_with_char ${VALUE_SIZE} ${CHARACTER})
        CURRENT_TEMPLATE="@${TEMPLATE}-size:${CHARACTER}@"
        find_and_replace_in_place_recursive ${DIRECTORY} ${CURRENT_TEMPLATE} ${REPLACE_WITH}
    done
}

function replace_manifest_with_keys {
    local MANIFEST_DIRECTORY
    local KEYS_DIRECTORY
    local FINAL_DIRECTORY
    local REPLACE_WITH
    local CURRENT_TEMPLATE

    MANIFEST_DIRECTORY=$1
    KEYS_DIRECTORY=$2
    FINAL_DIRECTORY=$3
    while read CURRENT_TEMPLATE 
    do
        REPLACE_WITH=`grep ${CURRENT_TEMPLATE} ${KEYS_DIRECTORY}/to_replace.keys | awk -F";" '{print $2}'`
        echo "Replacing $CURRENT_TEMPLATE with $REPLACE_WITH"
        find_and_replace_in_place_recursive ${FINAL_DIRECTORY} "${CURRENT_TEMPLATE}" "${REPLACE_WITH}"
        fill_title_bars                     ${FINAL_DIRECTORY} "${CURRENT_TEMPLATE}" "${REPLACE_WITH}"
    done < ${MANIFEST_DIRECTORY}/to_replace.manifest
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
        t)
            TEMPLATE_DIRECTORY=${OPTARG}
            ;;
        c)
            CUSTOMIZATIONS_DIRECTORY=${OPTARG}
            ;;
        o)
            OUTPUT_DIRECTORY=${OPTARG}
            ;;
        ?)
            print_usage $0
            exit 1
            ;;
    esac
done

#######################################################################################################################
# Input parameters check

[ -n "${TEMPLATE_DIRECTORY}"       -a -d "${TEMPLATE_DIRECTORY}" ]       || { print_usage $0; exit 1; }
[ -n "${CUSTOMIZATIONS_DIRECTORY}" -a -d "${CUSTOMIZATIONS_DIRECTORY}" ] || { print_usage $0; exit 1; }
[ -n "${OUTPUT_DIRECTORY}"         -a -d "${OUTPUT_DIRECTORY}" ]         || { print_usage $0; exit 1; }


#######################################################################################################################
# Main

clean_git_directory ${OUTPUT_DIRECTORY}

copy_git_directory  ${TEMPLATE_DIRECTORY}       ${OUTPUT_DIRECTORY}
copy_git_directory  ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}
do_append           ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}
do_prepend          ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

replace_manifest_with_keys ${TEMPLATE_DIRECTORY} ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

exit 0
