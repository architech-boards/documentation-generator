#!/bin/bash

#######################################################################################################################
# Parameters

WORKING_DIRECTORY=`pwd`
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_DIRECTORY=""
CUSTOMIZATIONS_DIRECTORY=""
OUTPUT_DIRECTORY=""
CSS_DIRECTORY="${SCRIPT_DIRECTORY}/css"
JS_DIRECTORY="${SCRIPT_DIRECTORY}/js"
MAIN_CSS="source/_themes/architech/static/architech.css"
JS_OUTPUT="source/_static/"

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
    local CURRENT_EXCLUDE
    local EXCLUDE_LIST
    local OPTIONS
    EXCLUDE_LIST="build *.manifest *.keys .git* *.append *.prepend *.rst.tmp"

    SOURCE=$1
    DESTINATION=$2

    OPTIONS=""
    for CURRENT_EXCLUDE in ${EXCLUDE_LIST}
    do
        OPTIONS="${OPTIONS} --exclude ${CURRENT_EXCLUDE}"
    done
    rsync -a ${SOURCE}/* ${DESTINATION}/ ${OPTIONS}
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

    MATCHING_FILES=`find ${DIRECTORY} \( -iname "*.rst" -o -iname "*.py" \) -exec grep -l "${TEMPLATE}" '{}' \;`
    for MATCHING_FILE in ${MATCHING_FILES}
    do
        sed -i "s|${TEMPLATE}|${VALUE}|g" ${MATCHING_FILE}
    done
}

function get_string_filled_with_char {
    local CHARACTER
    local CHARACTER_SIZE
    local SIZE
    local STRING
    SIZE=$1
    CHARACTER=$2
    CHARACTER_SIZE=${#CHARACTER}
    SIZE=$(( $SIZE * $CHARACTER_SIZE  ))
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
    
    CHARACTERS_LIST="= - ^ \* # \""
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
        echo "  ${CURRENT_TEMPLATE}"
        REPLACE_WITH=`grep ${CURRENT_TEMPLATE} ${KEYS_DIRECTORY}/to_replace.keys | awk -F";" '{print $2}'`
        find_and_replace_in_place_recursive ${FINAL_DIRECTORY} "${CURRENT_TEMPLATE}" "${REPLACE_WITH}"
        fill_title_bars                     ${FINAL_DIRECTORY} "${CURRENT_TEMPLATE}" "${REPLACE_WITH}"
    done < ${MANIFEST_DIRECTORY}/to_replace.manifest
}

function customize_main_css {
    local CURRENT_CSS
    local CSS_STASH
    local CSS_MAIN
    CSS_STASH=$1
    CSS_MAIN=$2
    for CURRENT_CSS in `ls ${CSS_STASH}/*`
    do
        echo "/************************************ `basename $CURRENT_CSS` ************************************/" >> ${CSS_MAIN}
        cat ${CURRENT_CSS} >> ${CSS_MAIN}
    done
}

function include_all_js {
    local CURRENT_JS
    local JS_STASH
    local DESTINATION
    JS_STASH=$1
    DESTINATION=$2
    for CURRENT_JS in `ls ${JS_STASH}/*`
    do
        cp ${CURRENT_JS} ${DESTINATION}
    done
}

function replace_code_snippets {
    local DESTINATION
    local CURRENT_DIRECTIVE
    local CURRENT_FILE
    local DIRECTIVES_LIST
    local REPLACER
    local DIFFERENTIATOR
    local FILES_LIST

    DESTINATION=$1
    REPLACER=$2
    COUNTER=1
    
    DIRECTIVES_LIST="host board"
    declare -A TITLES
    TITLES["host"]="Host"
    TITLES["board"]="Board"
    for CURRENT_DIRECTIVE in ${DIRECTIVES_LIST}
    do
        FILES_LIST=`mktemp`
        find ${DESTINATION} -iname "*.rst" -exec grep -l "^.. ${CURRENT_DIRECTIVE}::" '{}' \; > ${FILES_LIST}
        if [ $? -ne 0 ]
        then
            echo " ERROR: Something went wrong while accessing directory \"${DESTINATION}\". Aborting."
            exit 1
        fi
        while read CURRENT_FILE
        do
            DIFFERENTIATOR=`basename ${CURRENT_FILE} | sed "s| |_|g" | sed "s|-|_|g" | sed "s|\.|_|g"`"-${CURRENT_DIRECTIVE}-${COUNTER}"
            ${REPLACER} -f "${CURRENT_FILE}" -a "${CURRENT_DIRECTIVE}" -t "${TITLES[${CURRENT_DIRECTIVE}]}" -u "${DIFFERENTIATOR}" -d 0 > ${CURRENT_FILE}.tmp
            if [ $? -eq 0 ]
            then
                mv ${CURRENT_FILE}.tmp ${CURRENT_FILE}
            else
                echo " WARNING: Something went wrong while replacing code snippets inside file:"
                echo "          \"${CURRENT_FILE}\""
            fi
            COUNTER=$(( $COUNTER + 1 ))
        done < ${FILES_LIST}
        rm -f ${FILES_LIST}

    done
}

function customize_html {
    local CSS_STASH
    local CSS_MAIN
    local JS_STASH
    local JS_DESTINATION
    local DESTINATION
    local REPLACER

    CSS_STASH=$1
    CSS_MAIN=$2
    JS_STASH=$3
    JS_DESTINATION=$4
    DESTINATION=$5
    REPLACER=$6

    customize_main_css ${CSS_STASH} ${CSS_MAIN}
    include_all_js ${JS_STASH} ${JS_DESTINATION}
    replace_code_snippets ${DESTINATION} ${REPLACER}
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

cd ${WORKING_DIRECTORY}
cd ${TEMPLATE_DIRECTORY}
TEMPLATE_DIRECTORY=`pwd`

cd ${WORKING_DIRECTORY}
cd ${CUSTOMIZATIONS_DIRECTORY}
CUSTOMIZATIONS_DIRECTORY=`pwd`

cd ${WORKING_DIRECTORY}
cd ${OUTPUT_DIRECTORY}
OUTPUT_DIRECTORY=`pwd`

MAIN_CSS=${OUTPUT_DIRECTORY}/${MAIN_CSS}
JS_OUTPUT=${OUTPUT_DIRECTORY}/${JS_OUTPUT}

cd ${SCRIPT_DIRECTORY}/html_replacer
echo " Compiling the html replacer..."
make > /dev/null 2>&1
[ $? -eq 0 ] || { echo " ERROR: Impossible to compile the html replacer. Aborting."; exit 1; }
cd ${WORKING_DIRECTORY}

#######################################################################################################################
# Main

echo " Cleaning output directory..."
clean_git_directory ${OUTPUT_DIRECTORY}

echo " Copying template..."
copy_git_directory  ${TEMPLATE_DIRECTORY}       ${OUTPUT_DIRECTORY}
rm -f ${OUTPUT_DIRECTORY}/README

echo " Copying customizations..."
copy_git_directory  ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

echo " Appending..."
do_append           ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

echo " Prepending..."
do_prepend          ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

echo " Replacing keys..."
replace_manifest_with_keys ${TEMPLATE_DIRECTORY} ${CUSTOMIZATIONS_DIRECTORY} ${OUTPUT_DIRECTORY}

echo " Integrating HTML customizations..."
customize_html ${CSS_DIRECTORY} ${MAIN_CSS} ${JS_DIRECTORY} ${JS_OUTPUT} ${OUTPUT_DIRECTORY} ${SCRIPT_DIRECTORY}/html_replacer/replacer

echo " Done!"

exit 0
