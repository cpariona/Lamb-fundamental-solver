# Fitting phase logs archive

This document classifies the `docs/fitting_phase*_status.md` files as historical implementation logs.

They are retained for traceability, but they are not the active source of truth for the current fitting API, GUI behavior, or mRLFE direct-atlas route.

## Active replacements

Use these active documents instead:

```text
docs/workflows/fitting/README.md
docs/workflows/fitting/architecture.md
docs/workflows/fitting/validation_suite.md
docs/models/mrlfe/fitting_workflow.md
docs/repository/maintained_entrypoints.md
```

## Historical phase logs

```text
docs/archive/fitting_phases/fitting_phase1_status.md
docs/archive/fitting_phases/fitting_phase2_status.md
docs/archive/fitting_phases/fitting_phase3_status.md
docs/archive/fitting_phases/fitting_phase4_status.md
docs/archive/fitting_phases/fitting_phase5_status.md
docs/archive/fitting_phases/fitting_phase6_status.md
docs/archive/fitting_phases/fitting_phase7_status.md
docs/archive/fitting_phases/fitting_phase8_status.md
docs/archive/fitting_phases/fitting_phase9_status.md
docs/archive/fitting_phases/fitting_phase10_status.md
docs/archive/fitting_phases/fitting_phase11_status.md
```

## Cleanup policy

During cleanup, do not use the phase logs as maintained entrypoints. They may be moved physically into an archive folder in a later documentation-only commit if all internal references are updated.

The current cleanup keeps them in place to avoid breaking existing links while making their status explicit.
