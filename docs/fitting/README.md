# Fitting documentation index

This folder-level index separates active fitting documentation from historical phase logs.

## Active fitting references

Use these documents for the current fitting architecture and validation workflow:

```text
docs/fitting/architecture.md
docs/fitting/validation_suite.md
docs/mrlfe/fitting_workflow.md
docs/rayleigh_lamb/fitting_workflow.md
docs/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Current architecture

`docs/fitting/architecture.md` defines the model-independent fitting layer:

```text
experimental data contract
FitRequest / FitResult contracts
GUI adapter boundary
model-specific fitting adapters
```

Treat this document as the high-level architecture reference, not as a phase log.

## Current validation suite

`docs/fitting/validation_suite.md` describes the focused synthetic parameter-recovery suite:

```matlab
run_fit_validation_tests
```

This suite is separate from smoke tests and should be run after fitting-related changes.

## Model-specific fitting workflow references

```text
docs/mrlfe/fitting_workflow.md
docs/rayleigh_lamb/fitting_workflow.md
docs/acoustoelastic_iop_hgo/active/fitting_workflow.md
```

## Historical phase logs

Older fitting phase status files are retained as implementation history. They should not be treated as active workflow documentation.

See:

```text
docs/archive/fitting_phase_logs.md
docs/archive/fitting_phases/
```
