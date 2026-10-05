#!/bin/sh
# Download the Unicode data files used to generate utf8proc_data.c (see the
# Makefile in this directory) and the conformance test files used by `make check`.
set -e

UNICODE_VERSION=18.0.0
BASE=https://www.unicode.org/Public/$UNICODE_VERSION/ucd

for url in \
    $BASE/CaseFolding.txt \
    $BASE/CompositionExclusions.txt \
    $BASE/DerivedCoreProperties.txt \
    $BASE/EastAsianWidth.txt \
    $BASE/NormalizationTest.txt \
    $BASE/UnicodeData.txt \
    $BASE/auxiliary/GraphemeBreakProperty.txt \
    $BASE/auxiliary/GraphemeBreakTest.txt \
    $BASE/emoji/emoji-data.txt
do
    wget -O "$(basename "$url")" "$url"
done

# Uppercase.txt and Lowercase.txt are extracted from DerivedCoreProperties.txt
rm -f Uppercase.txt Lowercase.txt

#the makefile  don't work on my windows. Julia error.
#make Uppercase.txt Lowercase.txt
julia -e 'print(match(r"# Derived Property: Uppercase.*?# Total code points:"s, read("DerivedCoreProperties.txt", String)).match)' > Uppercase.txt
julia -e 'print(match(r"# Derived Property: Lowercase.*?# Total code points:"s, read("DerivedCoreProperties.txt", String)).match)' > Lowercase.txt

cp GraphemeBreakTest.txt ../pascal/tests/GraphemeBreakTest.txt
cp NormalizationTest.txt ../pascal/tests/NormalizationTest.txt
cp Uppercase.txt ../pascal/tests/Uppercase.txt
cp Lowercase.txt ../pascal/tests/Lowercase.txt
