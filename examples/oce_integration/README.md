# Demonstrating the maintained OCE observation API

This demonstration contains no observation mapping, schema decoder or fitting
dispatcher. The maintained [app interface](../../app/oce_integration/README.md)
owns preparation. Run Lamb `startup`, explicitly add the reviewed OCE `src` folder,
and supply reviewed metadata and selection:

```matlab
oceResult = oce.io.loadScientificResult(resultFile);
selection = struct('directionIndex', directionIndex, ...
    'estimator', "kf_ridge", 'curve', "smoothed", 'validMask', reviewedMask);
metadata = struct('conditionId', conditionId, 'repetitionId', repId, ...
    'loadingCondition', loadingCondition, 'sourceResultFile', string(resultFile), ...
    'metadataReference', metadataReference);
prepared = prepareOceFitObservations(oceResult, selection, metadata);
experimental = prepared.experimental;
```

Then make **one** of the following explicit canonical calls, using the selected
family's reviewed configuration and physical inputs. These are alternatives, not
a model comparison or a claim that all four families support the same experiment:

```matlab
rlFit = lamb.fitting.rayleigh_lamb.rlFitDispersionData(experimental, rlConfig);
mrlfeFit = lamb.fitting.mrlfe.mrlfeFitDispersionData(experimental, mrlfeConfig);
aeFit = lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData(experimental, aeConfig);
platePhysical = struct('density_kgpm3', measuredDensity_kgpm3, ...
    'thickness_m', prepared.measuredThickness_m);
plateFit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    experimental, platePhysical);
```

For the other three APIs, the consumer explicitly supplies measured thickness in
their `fixedParams.thickness` and density in `fixedParams.rho`, along with all other
required physical inputs; no family-specific parameter mapping occurs in preparation.
Do not infer modal purity, a uniaxial state, fluid loading or constitutive parameters
from OCE filenames. Do not trim excluded DC/nonfinite frequencies to bypass a family's
full-axis support restriction. Inspect its error/rejection and retain the prepared
request, original masks and provenance. See each fitting API's help and model contract.
