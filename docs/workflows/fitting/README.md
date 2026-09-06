# Fitting documentation index

This folder-level index separates active fitting documentation from historical phase logs.

## Active fitting references

Use these documents for the current fitting architecture and validation workflow:

```text
docs/workflows/fitting/architecture.md
docs/workflows/fitting/validation_suite.md
docs/models/mrlfe/fitting_workflow.md
docs/models/rayleigh_lamb/fitting_workflow.md
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Current architecture

`docs/workflows/fitting/architecture.md` defines the model-independent fitting layer:

```text
experimental data contract
FitRequest / FitResult contracts
GUI adapter boundary
model-specific fitting adapters
```

Treat this document as the high-level architecture reference, not as a phase log.

## Current validation suite

`docs/workflows/fitting/validation_suite.md` describes the focused synthetic parameter-recovery suite:

```matlab
run_extended_integration_tests
```

This suite is separate from smoke tests and should be run after fitting-related changes.

## Model-specific fitting workflow references

```text
docs/models/mrlfe/fitting_workflow.md
docs/models/rayleigh_lamb/fitting_workflow.md
docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Historical phase logs

Older fitting phase status files remain available in Git history. They are not
active workflow documentation.
