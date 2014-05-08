#!/bin/bash

#######################################################################################################################
# Parameters

DIRECTORY=""

#######################################################################################################################
# Helpers

function print_usage {
cat << EOF

 This program cleans documentation sources from Windows/DOS tempering.

 Usage: $1 [options]

 OPTIONS:
 -h                 Print this help and exit
 -d <directory>     Documentation directory to purge from carriage return.

EOF
}

while getopts "hd:" option
do
    case ${option} in
        h)
            print_usage $0
            exit 0
            ;;
        d)
            DIRECTORY=${OPTARG}
            ;;
        ?)
            print_usage $0
            exit 1
            ;;
    esac
done

[ -n "${DIRECTORY}" -a -d "${DIRECTORY}" ] || { print_usage $0; exit 1; }

find ${DIRECTORY} -iname "*.rst*"    -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.py"      -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.md"      -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.css"     -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.html"    -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.conf"    -exec fromdos '{}' \;
find ${DIRECTORY} -iname "*.js"      -exec fromdos '{}' \;
find ${DIRECTORY} -iname "makefile"  -exec fromdos '{}' \;

