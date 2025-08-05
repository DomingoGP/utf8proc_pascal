#!/bin/bash

PATH=/C/lazarusTrunk/fpc/3.2.2/bin/i386-win32:$PATH:/C/Aplicaciones/Julia-1.10.9/bin
export PATH

wget https://www.unicode.org/Public/17.0.0/ucd/NormalizationTest.txt
wget https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakTest.txt
julia -e 'print(match(r"# Derived Property: Uppercase.*?# Total code points:"s, read("../data/DerivedCoreProperties.txt", String)).match)' > Uppercase.txt
julia -e 'print(match(r"# Derived Property: Lowercase.*?# Total code points:"s, read("../data/DerivedCoreProperties.txt", String)).match)' > Lowercase.txt
