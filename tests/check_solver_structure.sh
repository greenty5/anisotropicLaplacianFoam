#!/usr/bin/env sh
set -eu

fail()
{
    printf '%s\n' "$1" >&2
    exit 1
}

grep -q 'volSymmTensorField[[:space:]]*kappa' createFields.H || fail 'createFields.H must define volSymmTensorField kappa'
grep -q '"kappa"' createFields.H || fail 'createFields.H must read field named kappa'
grep -q 'volScalarField[[:space:]]*rhoCp' createFields.H || fail 'createFields.H must define volScalarField rhoCp'
grep -q '"rhoCp"' createFields.H || fail 'createFields.H must read field named rhoCp'

grep -q 'fvm::ddt(rhoCp, T)' anisotropicLaplacianFoam.C || fail 'main equation must use fvm::ddt(rhoCp, T)'
grep -q 'fvm::laplacian(kappa, T)' anisotropicLaplacianFoam.C || fail 'main equation must use fvm::laplacian(kappa, T)'

grep -q 'volVectorField[[:space:]]*gradT' write.H || fail 'write.H must write gradT'
grep -q '"gradT"' write.H || fail 'write.H must name the gradient output gradT'
grep -q 'volVectorField[[:space:]]*q' write.H || fail 'write.H must write q'
grep -q '"q"' write.H || fail 'write.H must name the heat flux output q'
grep -q '(-kappa & gradT)' write.H || fail 'write.H must define q = -kappa & gradT'

if grep -q 'DDT' anisotropicLaplacianFoam.C createFields.H write.H; then
    fail 'solver files must not reference the old DDT diffusivity field'
fi
