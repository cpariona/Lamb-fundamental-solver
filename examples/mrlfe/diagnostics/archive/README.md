# Archived mRLFE diagnostics

This folder contains historical mRLFE diagnostic scripts that are preserved for traceability but are not part of the maintained diagnostic workflow.

These scripts were moved here after the mRLFE diagnostics inventory identified them as weakly referenced exploratory diagnostics. They should not be used as active validation evidence unless they are first re-audited.

Before restoring, deleting, or using one of these scripts as active evidence:

1. Search active docs, tests, and code references by exact script name.
2. Check whether the script reproduces an unresolved numerical issue not covered elsewhere.
3. Confirm that primary diagnostics and focused runners still cover the maintained behavior.
4. Run the relevant focused validation before merge.

Maintained diagnostics are listed in:

```text
examples/mrlfe/diagnostics/README.md
```
