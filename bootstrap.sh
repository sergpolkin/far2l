#! /bin/sh

if [ $# -eq 0 ]; then
    exit 1
fi

upstream=$1
scripts=${upstream}/far2l/bootstrap/scripts
dest=$2

mkdir -p ${dest}

# farlang.templ
cat ${scripts}/farlang.templ.m4 | perl -I${scripts} ${scripts}/far2l_m4.pl 2 5 3-beta Linux\ x86_64 > ${dest}/farlang.templ

# lang.inc
perl -I${scripts} ${scripts}/farlng.pl ${dest}/farlang.templ ${dest}

# farversion.inc
perl -I${scripts} ${scripts}/farver.pl ${dest}/farversion.inc Linux\ x86_64 2 5 3-beta

# help eng
perl -I${scripts} ${scripts}/mkhlf.pl ${scripts}/FarEng.hlf.m4 | perl ${scripts}/far2l_m4.pl 2 5 3-beta Linux\ x86_64 > ${dest}/FarEng.hlf

# help rus
perl -I${scripts} ${scripts}/mkhlf.pl ${scripts}/FarRus.hlf.m4 | perl ${scripts}/far2l_m4.pl 2 5 3-beta Linux\ x86_64 > ${dest}/FarRus.hlf

# help hun
perl -I${scripts} ${scripts}/mkhlf.pl ${scripts}/FarHun.hlf.m4 | perl ${scripts}/far2l_m4.pl 2 5 3-beta Linux\ x86_64 > ${dest}/FarHun.hlf

# help ukr
perl -I${scripts} ${scripts}/mkhlf.pl ${scripts}/FarUkr.hlf.m4 | perl ${scripts}/far2l_m4.pl 2 5 3-beta Linux\ x86_64 > ${dest}/FarUkr.hlf
