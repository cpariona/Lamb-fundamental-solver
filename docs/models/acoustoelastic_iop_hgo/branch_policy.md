# AE IOP/HGO branch policy

`atlasA0` is the only supported production policy. It builds the internal
frequency grid, constructs and links modal-atlas candidates, selects the A0
branch, applies the documented fallback policy, evaluates quality, and builds
the canonical result.

Direct real-Cp, complex-C, and identity-oriented algorithms are diagnostic
internals. They may inspect candidate behavior but must not silently become a
production fallback, alter official arrays, or normalize away a scientific
difference.

The maintained diagnostics focus on atlas truncation, branch families, grid
start sensitivity, modal-atlas structure, and sweep reliability. Completed
raw-branch and identity-score investigations are retained only in Git history.
