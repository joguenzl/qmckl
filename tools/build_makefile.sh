#!/bin/bash
#
# Creates all the dependencies from the org-mode files

if [[ -z ${srcdir} ]] ; then
   srcdir=.
fi


WD=$PWD

function make_src()
{

    cd ${srcdir}

    declare -A DEPS DEPS_ORG DEPS_TEST TESTS HTML TEXT DEPS_DOC

    C_FILES=
    F_FILES=
    FH_FUNC_FILES=
    FH_TYPE_FILES=
    H_FUNC_FILES=
    H_TYPE_FILES=
    H_PRIVATE_FUNC_FILES=
    H_PRIVATE_TYPE_FILES=
    C_TEST_FILES=
    F_TEST_FILES=
    TANGLED_FILES=

    for org in org/*.org ; do
        i=$(basename ${org%.org})
        tangled="org/${i}.tangled"
        exported="org/${i}.exported"
        c_test_x="tests/test_${i}"
        c_test_o="tests/test_${i}.\$(OBJEXT)"
        f_test_o="tests/test_${i}_f.\$(OBJEXT)"
        c_test="tests/test_${i}.c"
        f_test="tests/test_${i}_f.f90"
        html="share/doc/qmckl/html/${i}.html"
        text="share/doc/qmckl/text/${i}.txt"

        i="src/${i}"

        c="${i}.c"
        o="${i}.\$(OBJEXT)"
        h_func="${i}_func.h"
        h_type="${i}_type.h"
        h_private_func="${i}_private_func.h"
        h_private_type="${i}_private_type.h"
        f90="${i}_f.f90"
        fo="${i}_f.\$(OBJEXT)"
        fh_func="${i}_fh_func.f90"
        fh_type="${i}_fh_type.f90"

        ORG_FILES+="\$(srcdir)/$org "
        TANGLED_FILES+="$tangled "
        EXPORTED_FILES+="$exported "
        DEPS_ORG["\$(srcdir)/$org"]=$tangled
        DEPS_DOC["\$(srcdir)/$org"]=$exported
        TEXT["\$(srcdir)/$org"]=$text
        HTML["\$(srcdir)/$org"]=$html

        grep -q "(eval c)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$c]+=" $tangled"
            DEPS[$o]+=" $c \$(qmckl_h)"
            C_FILES+=" $c"
            C_O_FILES+=" $o"
        fi

        grep -q "(eval h_func)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$h_func]+=" $tangled"
            H_FUNC_FILES+=" $h_func"
        fi

        grep -q "(eval h_type)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$h_type]+=" $tangled"
            H_TYPE_FILES+=" $h_type"
        fi

        grep -q "(eval h_private_type)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$o]+=" $h_private_type"
            DEPS[$h_private_type]+=" $tangled"
            H_PRIVATE_TYPE_FILES+=" $h_private_type"
        fi

        grep -q "(eval h_private_func)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$o]+=" $h_private_func"
            DEPS[$h_private_func]+=" $tangled"
            H_PRIVATE_FUNC_FILES+=" $h_private_func"
        fi

        grep -q "(eval f)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$f90]+=" $tangled \$(src_qmckl_fo)"
            DEPS[$fo]+="$f90 \$(src_qmckl_fo)"
            F_FILES+=" $f90"
        fi

        grep -q "(eval fh_func)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$fh_func]+=" $tangled"
            FH_FUNC_FILES+=" $fh_func"
        fi

        grep -q "(eval fh_type)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS[$fh_type]+=" $tangled"
            FH_TYPE_FILES+=" $fh_type"
        fi

        grep -q "(eval c_test)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS_TEST["${c_test}"]=" ${tangled}"
            C_TEST_FILES+=" ${c_test}"
            TESTS["${c_test_x}"]+="${c_test} \$(qmckl_h)"
        fi

        grep -q "(eval f_test)" $org
        if [[ $? -eq 0 ]] ; then
            DEPS_TEST["${f_test}"]+=" ${tangled} \$(test_qmckl_fo)"
            F_TEST_FILES+=" ${f_test}"
            TESTS["${c_test_x}"]+=" ${f_test} \$(test_qmckl_fo)"
        fi
    done


    echo 
    echo "## Source files" 
    echo 
    echo "ORG_FILES=${ORG_FILES}" 
    echo "TANGLED_FILES=${TANGLED_FILES}" 
    echo "EXPORTED_FILES=${EXPORTED_FILES}" 
    echo "C_FILES=${C_FILES}" 
    echo "F_FILES=${F_FILES}" 
    echo "C_O_FILES=${C_O_FILES}" 
    echo "FH_FUNC_FILES=${FH_FUNC_FILES}" 
    echo "FH_TYPE_FILES=${FH_TYPE_FILES}" 
    echo "H_FUNC_FILES=${H_FUNC_FILES}" 
    echo "H_TYPE_FILES=${H_TYPE_FILES}" 
    echo "H_PRIVATE_FUNC_FILES=${H_PRIVATE_FUNC_FILES}" 
    echo "H_PRIVATE_TYPE_FILES=${H_PRIVATE_TYPE_FILES}" 
    echo "C_TEST_FILES=${C_TEST_FILES}" 
    echo "F_TEST_FILES=${F_TEST_FILES}" 
    echo "TESTS=${!TESTS[@]}" | sed "s|\$(srcdir)/||g"
    echo "HTML_FILES"=${HTML[@]}
    echo "TEXT_FILES"=${TEXT[@]} 
    echo 

    echo 

    echo "## Org-mode inherited dependencies" 
    echo 
    echo "if QMCKL_DEVEL"
    for f in ${!DEPS_ORG[@]} ; do
        echo ${DEPS_ORG[$f]}: $f
        echo "	\$(tangle_verbose)\$(srcdir)/tools/tangle.sh $f"
        echo ""
    done 
    echo "endif"
    echo 

    echo 
    echo "## Source dependencies" 
    echo 
    echo "if QMCKL_DEVEL"
    for f in ${!DEPS[@]} ; do
        x="${DEPS[$f]}" 
        if [[ "${x%.tangled}x" != ${x}x ]] ; then
           echo "${f}: ${DEPS[$f]}"
        fi
    done | sort 
    echo "endif"
    echo "${src_qmckl_fo}: ${src_qmckl_f}"
    for f in ${!DEPS[@]} ; do
        x="${DEPS[$f]}" 
        if [[ "${x%.tangled}x" == ${x}x ]] ; then
           echo "${f}: ${DEPS[$f]}"
        fi
    done | sort 

    echo 
    echo "## Test files" 
    echo 
    echo "\$(test_qmckl_fo): \$(test_qmckl_f)"
    echo "if QMCKL_DEVEL"
    for f in ${!DEPS_TEST[@]} ; do
        echo "${f}: ${DEPS_TEST[$f]}"
    done | sort 
    echo "endif"
    echo
    echo "check_PROGRAMS = \$(TESTS)" 
    for f in ${!TESTS[@]} ; do
        echo "tests_$(basename $f)_SOURCES = ${TESTS[$f]}" #| sed "s|\$(srcdir)/||"
        echo "tests_$(basename $f)_LDADD   = src/libqmckl.la"
        echo "tests_$(basename $f)_LDFLAGS = -no-install"
    done | sort 

    echo 
    echo "## Documentation" 
    echo 
    echo "if QMCKL_DEVEL"
    for f in ${ORG_FILES} ; do
        echo "${HTML[$f]}: ${DEPS_DOC[$f]}"
        echo "${TEXT[$f]}: ${DEPS_DOC[$f]}"
        echo ""
    done 
    for f in ${!DEPS_DOC[@]} ; do
        echo "${DEPS_DOC[$f]}: $f \$(htmlize_el)"
        echo "	\$(export_verbose)\$(srcdir)/tools/build_doc.sh $f"
        echo ""
    done 
    echo "endif"
}


OUTPUT=${WD}/generated.mk
make_src > ${OUTPUT}
