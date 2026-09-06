# Refactor policy

A structural task changes only the responsibilities explicitly authorized by
its request. Existing scientific behavior, units, branch policy, numerical
defaults, and result meaning remain protected unless a separate scientific
change is authorized.

## Process

1. Verify branch, working tree, scope, and current contracts.
2. Search existing owners before adding a new function.
3. Make the smallest coherent change that corrects a real inconsistency.
4. Update callers, paths, tests, and documentation together.
5. Execute appropriate tiers and inspect the diff.
6. Record evidence and leave a reviewable commit sequence.

No speculative frameworks, managers, registries, or forwarding aliases.
Extraction is by responsibility, not line count. Model-specific adapters are
appropriate when they make request translation explicit.

## Scientific changes

Characterize old and new behavior independently. A golden update requires a
causal explanation, exact deltas, and scientific tests beyond the golden.
Commit a scientific baseline update separately, retain its tolerance unless
independently justified, and rerun all six validation tiers afterwards.

## Diagnostics and compatibility

Investigation-only MATLAB files begin with `% TEMPORARY_DIAGNOSTIC` and are
removed before integration or deliberately promoted to a maintained purpose.
Persisted-data compatibility requires an explicit owner, scope, reason, and
removal condition; it is not a reason to duplicate scientific routes.

## Git and closeout

Do not overwrite unrelated user changes. Do not merge or push without task
authorization. Before closeout inspect status, diff, naming/dependencies,
documentation links, generated artifacts, and the actual six-tier outcomes.
Report failures and unresolved scientific evidence without normalizing them
away. Completed campaign plans belong in Git history.
