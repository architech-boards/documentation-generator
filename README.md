documentation-generator
=======================

Command line:

- to generate a documentation not hachiko-tiny
./documentation-generator/generate-documentation.sh -t documentation-template/ -c hachiko-customization/ -o output/

- to generate a documentation for hachiko-tiny
./documentation-generator/generate-hachiko-tiny.sh -b hachiko-customization/ -c hachiko-tiny-customization/ -t documentation-template/ -m mergedir/ -o output/

MINI HOW-TO
===========

xxx-customization + documentation-template = xxx-documentation <- readthedocs uses this repository with the correct branch

For every official releases (1.1.0A, 1.0.1A,...) we create a tag in xxx-customization and documentation-template.
If there is a major update (1.0.1 to 1.1.0) we create a new branch in xxx-documentation
