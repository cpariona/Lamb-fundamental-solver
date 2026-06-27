### Complex-C continuation exploratory archive

This document preserves the purpose and conclusion of the exploratory complex-C continuation example used during acoustoelastic IOP/HGO solver development.

### Scope

Archived exploratory group E3:

```text
run_acoustoelastic_iop_hgo_A0_complexC.m
```

This script was an example-level diagnostic. It was not a maintained public workflow.

The underlying complex-C solver capability remains available in the model/API layer:

```matlab
solveAcoustoelasticComplexCDispersion
```

### Why this diagnostic existed

The real-Cp branch tracking problem can become ambiguous because the residual landscape contains competing minima and branch families. The complex-C diagnostic tested an alternative route:

```text
real-Cp singular-vector tracker
  -> seed branch
  -> complex c = cr + i*ci continuation
  -> det(M) = 0 diagnostic
```

The script compared:

```text
real-Cp seed branch
complex-C real part
complex-C imaginary component
```

and reported diagnostic quantities such as:

```text
seed valid Cp points
complex valid Cp points
complex CpReal range
minimum abs(det(M))
median |Im(c)/Re(c)|
```

### Preserved conclusion

The complex-C route is useful as a possible future diagnostic or solver direction, but the example script itself is not part of the maintained public workflow.

Preserved decision:

```text
Archive the long example script.
Keep the model-level complex-C solver function and public API documentation.
Do not promote complex-C continuation to official atlasA0 output.
```

### Relation to official solver policy

The official production policy remains:

```text
atlasA0 = conservative official output
```

Complex-C continuation does not replace:

```matlab
result.Cp
result.validCp
```

and should not be promoted automatically into production output without a separate validation phase.

### Retained implementation capability

Retained model/API function:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticComplexCDispersion.m
```

Related public/API docs:

```text
docs/acoustoelastic_iop_hgo/active/public_api.md
```

Future work, if complex-C is revisited, should happen through the model/API layer and dedicated tests or diagnostics, not by restoring the archived long example script.

### Why the executable example can be archived

The example can be archived because:

```text
1. It is not a maintained public workflow.
2. It is not required by smoke tests.
3. It is not the source of the retained solver implementation.
4. Its purpose and conclusions are preserved here.
5. The actual complex-C solver remains available in the model layer.
```

### Required validation after archival

After removing the executable E3 script, run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

No numerical behavior in maintained workflows should change.
