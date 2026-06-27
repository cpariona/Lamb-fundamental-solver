# Fitting documentation index

This folder-level index separates active fitting documentation from historical phase logs.

## Active fitting references

Use these documents for the current fitting architecture and validation workflow:

```text
docs/fitting_architecture.md
docs/fitting_validation_suite.md
docs/mrlfe/fitting_workflow.md
```

## Current architecture

`docs/fitting_architecture.md` defines the model-independent fitting layer:

```text
experimental data contract
FitRequest / FitResult contracts
GUI adapter boundary
model-specific fitting adapters
```

The implementation now exists. Treat the document as the high-level architecture reference, not as a phase log.

## Current validation suite

`docs/fitting_validation_suite.md` describes the focused synthetic parameter-recovery suite:

```matlab
run_fit_validation_tests
```

This suite is separate from smoke tests and should be run after fitting-related changes.

## mRLFE fitting workflow

`docs/mrlfe/fitting_workflow.md` is the active reference for mRLFE fitting routes:

```text
maintained/reference-based workflow
etaS elastic-reference forward cache
direct viscous atlas evaluator
```

## Historical phase logs

Older `docs/fitting_phase*_status.md` files are retained as implementation history. They should not be treated as active API documentation.

See:

```text
docs/archive/fitting_phase_logs.md
```
