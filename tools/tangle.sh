#!/bin/bash
#
# This script tangles all the org-mode files in the src directory of QMCkl.
# It needs to be run from in the src directory.  It uses the config_tangle.el
# Emacs configuration file, which contains information required to compute the
# current file names using for example ~(eval c)~ to get the name of the
# produced C file. The org-mode file is not tangled if the last modification
# date of the org file is older than one of the tangled files.
# The =missing= script is used to check if emacs is present on the system.

if [[ -z ${srcdir} ]] ; then
  echo "Error: srcdir environment variable is not defined"
  exit 1
fi

if [[ -z ${top_builddir} ]] ; then
   echo "Error: top_builddir environment variable is not defined"
   exit 1
fi

EXTENSIONS="_f.F90 _fh_func.F90 _fh_type.F90 .c _func.h _type.h _private_type.h _private_func.h"

function tangle()
{
    local backup_dir=$(mktemp -d)
    local org_file=$1
    local c_file=${org_file%.org}.c
    local f_file=${org_file%.org}.F90

    if [[ ${org_file} -ot ${c_file} ]] ; then
        return
    elif [[ ${org_file} -ot ${f_file} ]] ; then
        return
    fi

    local prefix=${top_builddir}/src/$(basename ${org_file})
    prefix=${prefix%.org}
    for ext in $EXTENSIONS ; do
      if [[ -f ${prefix}${ext} ]] ; then
         mv ${prefix}${ext} ${backup_dir}
      fi
    done

    ${srcdir}/tools/missing \
        emacs --no-init-file --no-site-lisp --quick --batch ${org_file} \
         --load=${srcdir}/tools/config_tangle.el \
        -f org-babel-tangle
    
    for ext in $EXTENSIONS ; do
      local new_file=${prefix}${ext}
      local old_file=${backup_dir}/$(basename ${new_file})
      diff $new_file $old_file &> /dev/null
      if [[ $? -eq 0 ]] ; then
         echo "${old_file} unchanged" 
         mv $old_file $new_file
      else
         echo "${old_file}   changed" 
      fi
    done
    rm -rf ${backup_dir}
}

for i in $@
do
    tangled=${i%.org}.tangled
    tangled=${top_builddir}/src/$(basename $tangled)
    NOW=$(date +"%m%d%H%M.%S")
    tangle ${i} &> $tangled 
    rc=$?
    # Make log file older than the tangled files
    touch -t ${NOW} $tangled
    # Fail if tangling failed
    if [[ $rc -ne 0 ]] ; then
       cat $tangled
       rm $tangled
       exit $rc
    fi
done
