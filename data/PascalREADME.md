##MAKEFILE ONLY TO GENERATE THE DATA FOR A NEW UNICODE VERSION.

First make the c version to download the UNICODE data files

- UnicodeData.txt
- CaseFolding.txt
- CompositonExclusions.txt
- DerivedCoreProperties.txt
- EastAsianWidth.txt
- emoji-data.txt
- GraphemBreakProperty.txt
 
On windows, use the git Bash shell.

and run `Pascal_build_data.sh`  or execute the following commands.

edit setpath.sh and put correct path for your system.
execute.

    $source setpath.sh
    $make -f PascalMakefile.mak

remove "," after the last element of every array, I don't know enought Julia to change the script :-(

    $ perl -pi -e 's/, \)/ \)/g' utf8proc_data.inc.new
    $ perl -pi -0pe 's/,\n\)/\n\)/g' utf8proc_data.inc.new

add license header
and move to the parent directory without .new extension.


    $cat LICENSE_UNICODE.text utf8proc_data.inc.new > ../pascal/utf8proc_data.inc

remove temporal file.


    $rm utf8proc_data.inc.new


----------
