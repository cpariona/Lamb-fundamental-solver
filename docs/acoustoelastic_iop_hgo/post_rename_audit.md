### Post-renaming audit status

This note records the repository state after the targeted identity-A0 plausibility implementation rename.

### Audit result

The latest `potential_structure_naming_issues.csv` audit reports:

```text
Over63Chars = 0
Over45Chars = 22
IsLegacyLongName = 26
MutatesOfficialCp = 5
```

### Interpretation

The previous MATLAB `namelengthmax` risk has been resolved.

The remaining long names are below MATLAB's usual `namelengthmax = 63`. They are considered legacy descriptive names rather than immediate compatibility problems.

The remaining `Over45Chars` entries are mostly:

- legacy descriptive diagnostics;
- legacy validation scripts already reachable through short wrappers;
- test files where descriptive naming is acceptable;
- solver/test files that are not user-facing commands.

### Naming decision

No additional broad renaming is recommended at this stage.

The maintained short-entrypoint layer should remain the user-facing interface. Legacy descriptive scripts may remain for compatibility and historical traceability.

### Current naming policy

For new work:

```text
Use short task-oriented entrypoints.
Use folder paths to carry model context.
Avoid new files with the prefix acoustoelastic_iop_hgo_...
Keep outputs under Results/ae_iop_hgo/<task>.
```

### Next cleanup target

Further cleanup should focus on documentation consistency and optional wrapper consolidation, not on mass renaming.

Any future renaming should be handled in a dedicated commit with:

1. `git grep` reference checks;
2. MATLAB path smoke test;
3. updated documentation;
4. no solver-policy changes.
