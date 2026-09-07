# Engineering conventions

## Ownership and dependency rules

Every responsibility has one canonical owner. Equivalent responsibilities use
equivalent placement and contracts, but symmetry never requires different
physical models to use equal numerical algorithms. Reuse an existing owner
before creating another, and extract by responsibility rather than line count.

Generic `shared`, `common`, or similar buckets are forbidden. Do not stack
`old`, `new`, `legacy`, `current`, `v2`, or forwarding implementations to retain
development chronology. Git history preserves retired strategies. Compatibility
aliases require explicit authorization, a real external contract, and a removal
condition.

Public APIs should expose complete scientific operations and remain small.
Internal equations, trackers, policies, result builders, and optimizer mechanics
stay internal unless they have an independent scientific use. Models calculate;
GUIs coordinate, translate, present, and persist. Studies and examples call
production APIs, while production never calls them.

## Scientific contracts

Configuration must visibly separate physical parameters, numerical options,
execution profiles, and UI state. Quality assesses an already selected official
curve; it does not reconnect, interpolate, replace, or select a branch.
Diagnostics expose interpretable evidence without becoming an alternate
production implementation.

Structural work preserves equations, constitutive laws, branch identity and
selection, tracking, numerical presets, stopping rules, fitting semantics,
result schemas, and quality thresholds. Baselines or tolerances must never be
changed to hide structural drift. Performance is part of solver behavior and is
validated with representative, non-machine-brittle evidence.

## Implementation practice

- Keep a clear abstraction level within each block and avoid forwarding chains.
- Separate science, interaction, presentation, and persistence.
- Match every MATLAB filename to its top-level function and keep names globally
  unambiguous.
- Use `rl*`, `mrlfe*`, and `ae*` for family internals; descriptive established
  AE scientific names may remain.
- Use SI units and unit-qualified public mRLFE request fields. Plate thickness
  means full physical thickness; half-thickness is internal state.
- Do not create speculative registries, managers, frameworks, or empty folders
  for visual symmetry.
- Investigation-only files begin with `% TEMPORARY_DIAGNOSTIC` and are removed
  or deliberately promoted before integration.

Tests protect architecture and science: owner locations, dependency direction,
public routes, schemas, numerical recovery, and absence of retired aliases.
Structural scans must assert that their source set is non-empty and compare
function references using parser-compatible semantic names.

Changes update callers, tests, paths, and documentation together. Inspect the
diff, generated artifacts, links, and all applicable validation tiers before
publishing a review branch.
