#!/usr/bin/env sh
set -eu

case_dir="tutorials/compositePlate2D"

fail()
{
    printf '%s\n' "$1" >&2
    exit 1
}

test -d "$case_dir" || fail 'tutorials/compositePlate2D must exist'

for file in \
    "$case_dir/Allrun" \
    "$case_dir/Allclean" \
    "$case_dir/0.orig/T" \
    "$case_dir/0.orig/kappa" \
    "$case_dir/0.orig/rhoCp" \
    "$case_dir/constant/transportProperties" \
    "$case_dir/system/blockMeshDict" \
    "$case_dir/system/topoSetDict" \
    "$case_dir/system/setFieldsDict" \
    "$case_dir/system/fvOptions" \
    "$case_dir/system/fvSchemes" \
    "$case_dir/system/fvSolution" \
    "$case_dir/system/controlDict"
do
    test -f "$file" || fail "missing tutorial file: $file"
done

grep -q 'application[[:space:]]*anisotropicLaplacianFoam;' "$case_dir/system/controlDict" || fail 'controlDict must run anisotropicLaplacianFoam'
grep -q 'class[[:space:]]*volSymmTensorField;' "$case_dir/0.orig/kappa" || fail '0.orig/kappa must be a volSymmTensorField'
grep -q 'dimensions[[:space:]]*\[1 1 -3 -1 0 0 0\];' "$case_dir/0.orig/kappa" || fail 'kappa dimensions must be W/m/K'
grep -q 'class[[:space:]]*volScalarField;' "$case_dir/0.orig/rhoCp" || fail '0.orig/rhoCp must be a volScalarField'
grep -q 'dimensions[[:space:]]*\[1 -1 -2 -1 0 0 0\];' "$case_dir/0.orig/rhoCp" || fail 'rhoCp dimensions must be J/m3/K'
grep -q 'scalarSemiImplicitSource' "$case_dir/system/fvOptions" || fail 'fvOptions must define a scalarSemiImplicitSource heat source'
grep -q 'selectionMode[[:space:]]*cellZone;' "$case_dir/system/fvOptions" || fail 'heat source must select a cellZone'
grep -q 'heatSource' "$case_dir/system/topoSetDict" || fail 'topoSetDict must define heatSource'
grep -q 'materialCore' "$case_dir/system/topoSetDict" || fail 'topoSetDict must define materialCore'
grep -q 'materialInsert' "$case_dir/system/topoSetDict" || fail 'topoSetDict must define materialInsert'
grep -q 'setToCellZone' "$case_dir/system/topoSetDict" || fail 'topoSetDict must convert sets to zones'
grep -q 'kappa' "$case_dir/system/setFieldsDict" || fail 'setFieldsDict must assign kappa'
grep -q 'rhoCp' "$case_dir/system/setFieldsDict" || fail 'setFieldsDict must assign rhoCp'
grep -q 'frontAndBack' "$case_dir/0.orig/T" || fail 'T must define frontAndBack for 2D'
grep -q 'type[[:space:]]*empty;' "$case_dir/0.orig/T" || fail '2D frontAndBack patch must be empty'
