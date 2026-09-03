# Repository simplification

The maintained repository favors one implementation, one name, and one owner
per responsibility. Production model code lives under `models/`; reusable
workflow code under `analysis/`; application translation and presentation
under `app/`; executable teaching and diagnostic compositions under
`examples/`; validation under `tests/`.

Phase 6 reduces the validation surface to six flat runners and removes wrapper
dispatch, focused runner aliases, generated ownership inventories, redundant
examples, and completed diagnostic investigations. Git history preserves those
materials when forensic context is needed.

Repository hygiene verifies the physical layout, dependency direction,
documentation links, canonical naming, tracked artifacts, and unique test
ownership. Scientific algorithms, baselines, and tolerances are outside a
structural cleanup unless explicitly authorized.
