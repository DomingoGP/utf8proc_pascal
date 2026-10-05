#!/bin/bash
echo "CHANGE PATH"

PATH=/C/lazarusTrunk/fpc/3.2.2/bin/i386-win32:$PATH:/C/Aplicaciones/Julia-1.10.9/bin
export PATH

make -f PascalMakefile.mak
#remove "," after the last element of every array
perl -pi -e 's/, \)/ \)/g' utf8proc_data.inc.new
perl -pi -0pe 's/,\n\)/\n\)/g' utf8proc_data.inc.new
#add license header
#and move to the parent directory without .new extension.
cat LICENSE_UNICODE.text utf8proc_data.inc.new > ../pascal/utf8proc_data.inc
#remove temporal file.
rm utf8proc_data.inc.new



make -f PascalMakefile.mak GraphemeBreakTest.txt
make -f PascalMakefile.mak NormalizationTest.txt

julia -e 'print(match(r"# Derived Property: Uppercase.*?# Total code points:"s, read("DerivedCoreProperties.txt", String)).match)' > Uppercase.txt
julia -e 'print(match(r"# Derived Property: Lowercase.*?# Total code points:"s, read("DerivedCoreProperties.txt", String)).match)' > Lowercase.txt

cp GraphemeBreakTest.txt ../pascal/tests/GraphemeBreakTest.txt
cp NormalizationTest.txt ../pascal/tests/NormalizationTest.txt
cp Uppercase.txt ../pascal/tests/Uppercase.txt
cp Lowercase.txt ../pascal/tests/Lowercase.txt
