# Acoustoelastic IOP/HGO release-readiness checklist

For the current Rayleigh-Lamb architecture and API reference, see [Rayleigh-Lamb solver overview](rayleigh_lamb_overview.md) and [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md).

## Purpose

This checklist records the minimum documentation, API, compatibility, and local-validation state expected before creating a post-migration Acoustoelastic IOP/HGO tag. It is documentation-only and does not change MATLAB source, tests, examples, diagnostics, sweeps, GUI code, archive/prototype files, startup behavior, or model implementation files.

## Required local validation before tagging

Run the following sequence locally in MATLAB from a clean `main` checkout before creating the tag:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

The tag should only be created after this sequence passes locally in MATLAB from a clean `main`.

## Documentation state

Before tagging, confirm these migration and naming documents exist and are up to date:

```text
docs/acoustoelastic_post_rename_architecture.md
docs/acoustoelastic_final_naming_snapshot.md
docs/maintained_entrypoints.md
docs/naming_transition.md
docs/internal_rename_migration_plan.md
```

## API state

Author-neutral Acoustoelastic IOP/HGO names are the maintained names for new code.

## Compatibility state

Legacy `Li2024` wrappers remain callable and are covered by path-level smoke checks.

## Deferred work not required for this tag

- numerical equivalence tests for legacy wrappers;
- formal deprecation policy;
- archive/prototype migration;
- Rayleigh-Lamb base package reorganization;
- public v1 API documentation.

## Suggested tag name

```text
v0.4.0-acoustoelastic-author-neutral-api
```
