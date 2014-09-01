documentation-generator
=======================

To generate the documentation launch the script "generate-documentation.sh" and/or "generate-hachiko-tiny.sh". The script uses:
- documentation-template: repository with common part of documentation between all the boards
- nomeboard-costumization: repository with specific documentation of a board

The output of the generator script is saved in another repository. It is used by readthedocs.

How to launch the script:

- to generate a documentation not hachiko-tiny
./documentation-generator/generate-documentation.sh -t documentation-template/ -c hachiko-customization/ -o output/

- to generate a documentation for hachiko-tiny
./documentation-generator/generate-hachiko-tiny.sh -b hachiko-customization/ -c hachiko-tiny-customization/ -t documentation-template/ -m mergedir/ -o output/

To compile the output and generate the website for test purpose, use these commmands:

$ cd output
$ make html
$ firefox output/build/html/index.html

nomeboard-documentation
-----------------------
Repository with the official documentation, a branch is created for every release of the virtual machine (if necessary).7
This repository is used by readthedocs to public the documentation.
es. v1.0.0, v1.0.1, v1.1.0

nomeboard-customization
-----------------------
Repository with specific documentation for the board. Every time is published the documentation on readthedocs, a tag is created with the number of the version.
es. v1.1.0B:

$ git tag -a v1.1.0B -m 'v1.1.0B'
$ git push origin v1.1.0B

For every minor modify to the documentation, we will increase the letter. v1.1.0B, v1.1.0C,...

documentation-template
----------------------
Repository with the common part of the documentation between all the boards. A tag is created with the number of the version when is published the documentation on readthedocs.
Res. v1.1.0B:

$ git tag -a v1.1.0B -m 'v1.1.0B'
$ git push origin v1.1.0B

For every minor modify to the documentation, we will increase the letter. v1.1.0B, v1.1.0C,...
