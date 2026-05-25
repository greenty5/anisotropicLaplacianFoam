# anisotropicLaplacianFoam

`anisotropicLaplacianFoam` is an OpenFOAM v2512 solver for transient heat
conduction in stationary anisotropic solid materials. It solves solid
conduction only: there is no fluid velocity, pressure equation, advection,
radiation, or multi-region conjugate heat-transfer coupling.

The solver is intended as a compact OpenFOAM application for cases where the
thermal conductivity depends on direction, for example layered composites,
printed circuit board materials, or simplified orthotropic solid parts.

## Features

- Transient heat conduction in stationary solids.
- Symmetric tensor thermal conductivity field `kappa`.
- Volumetric heat capacity field `rhoCp`.
- Optional internal heat generation through standard OpenFOAM `fvOptions`.
- Derived output fields for temperature gradient and conductive heat flux.
- A runnable 2D composite plate tutorial in `tutorials/compositePlate2D`.

## Governing equation

The solved equation is:

```text
rhoCp * dT/dt = div(kappa & grad(T)) + Q
```

where:

- `T` is temperature.
- `rhoCp` is volumetric heat capacity.
- `kappa` is the anisotropic thermal conductivity tensor.
- `Q` is an optional volumetric heat source supplied through `fvOptions`.

The conductive heat flux uses the standard sign convention:

```text
q = -kappa & grad(T)
```

With this convention, heat flux points from high temperature toward low
temperature. The equation uses `div(kappa & grad(T))` on the right-hand side, so
positive internal heat generation `Q` raises the temperature.

## Repository layout

| Path | Purpose |
| --- | --- |
| `anisotropicLaplacianFoam.C` | Main solver, time loop, matrix assembly, and solve call |
| `createFields.H` | Reads `T`, `kappa`, `rhoCp`, and creates `fvOptions` |
| `write.H` | Writes `gradT` and `q` at output times |
| `Make/files` | OpenFOAM executable target |
| `Make/options` | OpenFOAM include paths and linked libraries |
| `tutorials/compositePlate2D` | Runnable example case |
| `tests` | Static consistency checks for solver, README, and tutorial files |
| `docs/anisotropicLaplacianFoam.tex` | Longer beginner-oriented theory and usage document |
| `docs/out/anisotropicLaplacianFoam.pdf` | Compiled PDF documentation, if generated locally |

## Required fields

Each case must provide these volume fields in the starting time directory,
normally `0/`.

| Field | Type | Dimensions | Meaning |
| --- | --- | --- | --- |
| `T` | `volScalarField` | `[0 0 0 1 0 0 0]` | Temperature |
| `kappa` | `volSymmTensorField` | `[1 1 -3 -1 0 0 0]` | Anisotropic thermal conductivity tensor |
| `rhoCp` | `volScalarField` | `[1 -1 -2 -1 0 0 0]` | Volumetric heat capacity |

OpenFOAM stores a symmetric tensor with six components:

```text
(xx xy xz yy yz zz)
```

Example `kappa` entry:

```text
dimensions      [1 1 -3 -1 0 0 0];
internalField   uniform (1.0 0 0 0.3 0 0.3);
```

This example represents the tensor:

```text
[ 1.0  0    0   ]
[ 0    0.3  0   ]
[ 0    0    0.3 ]
```

Example `rhoCp` entry:

```text
dimensions      [1 -1 -2 -1 0 0 0];
internalField   uniform 2.0e6;
```

For a 2D case, every field must use `type empty;` on the front/back patch.

## Output fields

At write times, the solver writes:

| Field | Type | Meaning |
| --- | --- | --- |
| `T` | `volScalarField` | Solved temperature field |
| `gradT` | `volVectorField` | Temperature gradient |
| `q` | `volVectorField` | Conductive heat flux, `q = -kappa & grad(T)` |

`q` is useful for checking both heat-flow magnitude and direction. In an
anisotropic material, heat flux does not necessarily point exactly normal to
temperature contours.

## Build

Source an OpenFOAM v2512 environment first. The exact command depends on your
installation. Then build from the repository root:

```sh
wmake
```

The executable target is:

```text
$(FOAM_USER_APPBIN)/anisotropicLaplacianFoam
```

You can check that OpenFOAM can find the solver with:

```sh
which anisotropicLaplacianFoam
```

## Tutorial quick start

The example case is in `tutorials/compositePlate2D`. It uses pristine field
files in `0.orig`; `./Allrun` restores `0` from `0.orig` automatically and runs
the full workflow.

```sh
cd tutorials/compositePlate2D
./Allrun
```

Manual tutorial commands:

```sh
cd tutorials/compositePlate2D
rm -rf 0 && cp -r 0.orig 0
blockMesh
topoSet
setFields
anisotropicLaplacianFoam
```

The expected output fields are:

- `T`
- `gradT`
- `q`

## Tutorial case

`tutorials/compositePlate2D` is a thin 2D composite plate:

- Size: `0.10 m x 0.05 m x 0.001 m`.
- Mesh: `100 x 50 x 1` cells.
- Left boundary: fixed temperature of `300 K`.
- Right boundary: fixed temperature of `330 K`.
- Top and bottom boundaries: `zeroGradient`, representing insulation.
- Front and back boundaries: `empty`, representing a 2D calculation.

The tutorial defines material regions with `topoSet`:

| Region | Purpose |
| --- | --- |
| `materialCore` | Rectangular core material region |
| `materialInsert` | Smaller anisotropic insert inside the core |
| `heatSource` | Cell zone used for internal heat generation |

Material properties are assigned with `setFields`:

| Region | `kappa` components `(xx xy xz yy yz zz)` | `rhoCp` |
| --- | --- | --- |
| Background | `(1.0 0 0 0.3 0 0.3)` | `2.0e6` |
| `materialCore` | `(8.0 0 0 0.8 0 0.8)` | `2.4e6` |
| `materialInsert` | `(0.4 0 0 3.0 0 0.4)` | `1.6e6` |

The tutorial applies internal heat generation through `fvOptions` using a
`scalarSemiImplicitSource` on the `cellZone` named `heatSource`.

## Post-processing

After running the tutorial, inspect the time directories in ParaView or another
OpenFOAM-capable post-processor.

Useful first checks:

- Plot `T` to inspect the temperature distribution.
- Plot `gradT` to find where temperature changes most rapidly.
- Plot `q` as vectors to inspect conductive heat-flow direction.
- Compare the flux direction in the background, core, and insert materials.

For quick command-line inspection, list generated time directories:

```sh
find . -maxdepth 1 -type d | sort
```

## Tests

The `tests` directory contains shell-based static checks. They do not replace a
real OpenFOAM compile/run, but they catch common repository consistency errors.

```sh
tests/check_solver_structure.sh
tests/check_readme.sh
tests/check_tutorial_case.sh
```

The checks verify that:

- the solver reads `kappa` and `rhoCp`;
- the equation uses `fvm::ddt(rhoCp, T)` and `fvm::laplacian(kappa, T)`;
- derived fields `gradT` and `q` are written;
- README commands and dimensions remain documented;
- the tutorial case contains the expected field files, dictionaries, cell
  zones, and 2D boundary settings.

## Troubleshooting

| Symptom | Likely cause | Check |
| --- | --- | --- |
| `anisotropicLaplacianFoam: command not found` | Solver not built or OpenFOAM environment not sourced | Source OpenFOAM v2512, run `wmake`, and check `which anisotropicLaplacianFoam` |
| Missing `kappa` or `rhoCp` | `0/` was not restored from `0.orig/` | Run `rm -rf 0 && cp -r 0.orig 0` in the tutorial case |
| Patch type error in the 2D case | A field is missing `empty` on `frontAndBack` | Check `0/T`, `0/kappa`, and `0/rhoCp` |
| No heat-source effect | `topoSet` was not run or `fvOptions` did not select `heatSource` | Run `topoSet` and inspect `constant/polyMesh/cellZones` |
| Unexpected flux direction | Sign convention is being interpreted incorrectly | Remember that `q = -kappa & grad(T)` |

## Detailed documentation

A longer beginner-oriented document is available as LaTeX source:

```text
docs/anisotropicLaplacianFoam.tex
```

If compiled, the PDF is placed at:

```text
docs/out/anisotropicLaplacianFoam.pdf
```

To rebuild the PDF:

```sh
mkdir -p docs/out
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs/out docs/anisotropicLaplacianFoam.tex
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=docs/out docs/anisotropicLaplacianFoam.tex
```
