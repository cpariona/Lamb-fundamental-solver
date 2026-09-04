# AE IOP/HGO numerical algorithm

The public solver separates the internal atlas tracking grid from the requested
output grid. The only official production branch is atlasA0.

## Final numerical pipeline

The maintained atlas workflow is now:

```text
1. Evaluate log10(sigma_min(M)) on the discrete atlas frequency-velocity grid.
2. Detect local candidate minima strictly on cGrid.
3. Link the discrete candidates into branches.
4. Select the maintained A0 branch with the atlasA0 policy.
5. Use bounded fminbnd to refine only the explicit points of the selected branch by minimizing the true
   SVD objective in log(Cp) between neighboring cGrid samples.
6. Assign the refined branch to the requested output frequencies and interpolate
   only across gaps allowed by the existing policy.
```

Candidate discovery, branch metrics, branch linking, and branch selection remain
based on the discrete atlas. Continuous minimization cannot alter candidate
ranking or branch identity because it occurs only after A0 selection.

The refinement implementation is owned by:

```text
models/acoustoelastic_iop_hgo/tracking/aeRefineSelectedAtlasBranch.m
```

and is invoked from:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m
```

## Configuration contract

The final continuous-refinement stage is controlled by:

```text
refineLocalMinima
selectedBranchRefinementTolLogCp
selectedBranchRefinementMaxFunEvals
selectedBranchRefinementMaxIter
```

`refineLocalMinima=false` disables continuous refinement and preserves a fully
discrete official branch on `cGrid`. The candidate table remains discrete in
both configurations.


## Limitations

Residual-only branch linking can be ambiguous at low stiffness/high IOP,
near degeneracy, and near crossings. Diagnostic modal-family candidates do
not replace official output. Do not repair scientific truncation with plot
smoothing. Numerical controls and fallback validity must remain explicit.

The historical golden investigation and independent objective/convergence
evidence are recorded in `docs/validation/ae_atlasA0_baseline.md`.
