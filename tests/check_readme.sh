#!/usr/bin/env sh
set -eu

fail()
{
    printf '%s\n' "$1" >&2
    exit 1
}

check_tutorial_command_sequence()
{
    awk '
        !in_block && $0 ~ /^```(bash|sh)[[:space:]]*$/ { in_block = 1; state = 0; next }
        in_block && $0 ~ /^```[[:space:]]*$/ { in_block = 0; state = 0; next }
        in_block && state == 0 && $0 ~ /^[[:space:]]*blockMesh[[:space:]]*$/ { state = 1; next }
        in_block && state == 1 && $0 ~ /^[[:space:]]*topoSet[[:space:]]*$/ { state = 2; next }
        in_block && state == 2 && $0 ~ /^[[:space:]]*setFields[[:space:]]*$/ { state = 3; next }
        in_block && state == 3 && $0 ~ /^[[:space:]]*anisotropicLaplacianFoam[[:space:]]*$/ { found = 1; next }
        END { exit(found ? 0 : 1) }
    ' README.md || fail 'README must document tutorial run commands in order inside a fenced shell block'
}

grep -qi 'OpenFOAM v2512' README.md || fail 'README must state OpenFOAM v2512'
grep -Fq 'rhoCp * dT/dt = div(kappa & grad(T)) + Q' README.md || fail 'README must include the governing equation'
grep -Fq 'kappa' README.md || fail 'README must document kappa'
grep -Fq '[1 1 -3 -1 0 0 0]' README.md || fail 'README must document kappa dimensions'
grep -Fq 'rhoCp' README.md || fail 'README must document rhoCp'
grep -Fq '[1 -1 -2 -1 0 0 0]' README.md || fail 'README must document rhoCp dimensions'
grep -Fq 'wmake' README.md || fail 'README must document build command'
grep -Fq 'tutorials/compositePlate2D' README.md || fail 'README must document tutorial path'
grep -Fq 'blockMesh' README.md || fail 'README must document blockMesh'
grep -Fq 'topoSet' README.md || fail 'README must document topoSet'
grep -Fq 'setFields' README.md || fail 'README must document setFields'
check_tutorial_command_sequence
grep -Fq 'gradT' README.md || fail 'README must document gradT output'
grep -Fq 'q = -kappa & grad(T)' README.md || fail 'README must document q output'

if grep -qi 'anisotoropic' README.md; then
    fail 'README must not contain the typo anisotoropic'
fi
