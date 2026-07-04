# ADR-002: Execution profile semantics

Status: Accepted
Date: 2026-07-04
Last reviewed: 2026-07-04

## Context

The repository exposes execution-profile controls across Main GUI, SweepTool,
and FitTool. Existing documentation distinguishes this surface control from
route policies, branch policies, optimizer controls, and physical parameters.

## Decision

`executionProfile` represents numerical effort and robustness.

Canonical values are:

- `Fast`
- `Balanced`
- `Robust`

`executionProfile` is distinct from:

- route policy;
- branch policy;
- optimizer settings;
- physical parameters.

`robustness` remains a compatibility alias.

Each model can have different effective support. Requested and effective
profiles must be reported explicitly where metadata is available.

mRLFE may map unsupported profiles to a validated configuration, including the
maintained fast atlas behavior.

## Consequences

- UI and adapter code should preserve requested and effective profile metadata.
- New code should prefer `executionProfile` over `robustness`.
- Route and branch policy changes require separate design and validation.
- mRLFE profile work should not be presented as implemented until designed and validated.

## Alternatives

- Treat profile names as optimizer presets.
- Treat profile names as branch or route policy selectors.
- Hide requested/effective differences in model metadata.

These alternatives are rejected because they make numerical behavior harder to
audit across models and surfaces.

## References

- `docs/architecture/execution_profiles_surface_integration.md`
- `docs/workflows/fitting/architecture.md`
- `docs/validation/execution_profile_end_to_end_validation.md`
- `docs/validation/mrlfe_execution_profile_benchmark.md`
