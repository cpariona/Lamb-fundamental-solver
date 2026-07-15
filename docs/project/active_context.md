# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Audit base: `d35eb6c4449cb4f5dae7eaec88be74e153ce6aba`
Active branch: `audit/mrlfe-line-and-repository-density`

## Current development focus

The current phase is a diagnostic-only audit of the maintained mRLFE solver,
Main GUI, SweepTool, FitTool, repository composition, historical documents, and
diagnostics. It does not change production, tests, examples, numerical policy,
or existing active contracts.

The authoritative audit is:

```text
docs/repository/mrlfe_line_and_repository_density_audit.md
```

Machine-readable evidence is under:

```text
analysis/repository_audit/
```

## Decisive findings

- `mrlfeSolve` remains the only maintained public physical solver.
- `models/mrlfe/solvers/solveMRLFEBranch.m` has no executable caller, test
  reference, or explicit dynamic reference and is marked `delete` for phase 2.
- GUI, Sweep, and Fit request builders duplicate validation, aliases, physical
  mapping, policies, and error handling; one shared public-request core is the
  target.
- Main GUI, SweepTool, Fit compatibility logic, the RL compatibility host, and
  diagnostics depend on private raw solver structures; stable public/debug
  ownership is required before removing those shapes.
- Execution-profile metadata should merge surface-owned selection/default/grid
  facts with solver-owned preset/engine/quality/termination/fallback facts.
- Historical documentation and diagnostics have explicit retain/consolidate/
  archive/delete decisions; no item is deferred.

## Next implementation phase

Use the ordered reversible workstreams in the main audit report. Begin with the
verified dead solver deletion, then centralize request construction before
changing adapters or raw-result contracts. Correct and delete documentation
only after code boundaries and path-presence tests are updated.

## Constraints

- Preserve solver mathematics and numerical outputs.
- Preserve public request/result behavior and stable error identifiers.
- Keep existing GUI/Sweep/Fit wrapper entrypoints.
- Validate numerical and metadata parity across all three surfaces.
- Do not treat historical audits as current contracts.
