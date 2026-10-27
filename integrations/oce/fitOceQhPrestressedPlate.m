function outcome = fitOceQhPrestressedPlate(assembly, physical, review, options)
%FITOCEQHPRESTRESSEDPLATE Coordinate a reviewed scalar or row-thickness A0 request.
% ASSEMBLY comes from prepareOceQhFitObservations. PHYSICAL contains only
% density_kgpm3 and current full thickness_m (positive scalar SI values).
% REVIEW requires modelBranch="A0", thicknessPolicy either
% "explicit_constant_current_thickness" or "oce_directional_per_acquisition",
% thicknessSource, thicknessJustification, densitySource and modelAssumptionsJustification. These
% nonempty references record the caller's physical review, not inferred physics.
% No mean thickness or load/DIC constraint is computed. If the recorded
% per-observation thickness exists, the native solver uses it in each q_i.
% OPTIONS is passed
% unchanged to aePlateFitDispersion; its native result/diagnostics are retained.
% If physical QH groups and exact selected-Hz groups differ, explicit physical
% group IDs qualify coverage in Plate without changing any observed Hz or Cp.
% Compatible partitions retain the historical native call and diagnostics.
% Group identity does not itself prove identifiability or model support.
% Original OCT thicknesses, including excluded NaNs, remain in assembly.
% The scalar reference may come from an independently reviewed measurement. Compact
% OCT availability/range diagnostics are descriptive and never affect acceptance.

if nargin < 4, options = struct(); end
validateattributes(physical, {'struct'}, {'scalar'});
if ~isempty(setxor(fieldnames(physical), {'density_kgpm3'; 'thickness_m'}))
    error('lamb:oceQh:InvalidPhysicalInputs', 'Plate requires only explicit current thickness and density.');
end
for name = ["density_kgpm3", "thickness_m"]
    validateattributes(physical.(name), {'double'}, {'scalar', 'real', 'finite', 'positive'});
end
if ~isequal(review.modelBranch,"A0") || ...
        ~any(string(review.thicknessPolicy)== ...
            ["explicit_constant_current_thickness","oce_directional_per_acquisition"])
    error('lamb:oceQh:PhysicalReviewRequired', ...
        'Explicit A0 and a supported reviewed current-thickness policy are required.');
end
for name = ["thicknessSource", "thicknessJustification", "densitySource", "modelAssumptionsJustification"]
    value = string(review.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value)) == 0
        error('lamb:oceQh:PhysicalReviewRequired', 'Nonempty %s is required.', name);
    end
end
mask = assembly.experimental.validMask;
if review.thicknessPolicy=="oce_directional_per_acquisition"
    assert(isfield(assembly.experimental,'observationThickness_m') && ...
        isequaln(assembly.experimental.observationThickness_m(:), ...
        assembly.measuredThickness_m(:)), ...
        'lamb:oceQh:ThicknessAlignment', ...
        'QH observation thickness must exactly match the direction-selected OCE measurements.');
end
if ~any(mask)
    error('lamb:oceQh:EmptySelection', 'At least one reviewed observation is required.');
end
measured = assembly.measuredThickness_m(mask);
finite = measured(isfinite(measured));
minimum = NaN; maximum = NaN;
if ~isempty(finite), minimum = min(finite); maximum = max(finite); end
thicknessDiagnostics = struct('selectedObservationCount', nnz(mask), ...
    'finiteOctThicknessCount', numel(finite), 'unavailableOctThicknessCount', nnz(~isfinite(measured)), ...
    'minimumOctThickness_m', minimum, 'maximumOctThickness_m', maximum, ...
    'rangeOctThickness_m', maximum-minimum);
physicalHz = assembly.physicalFrequency_Hz(mask);
selectedHz = assembly.experimental.frequency_Hz(mask);
% This is an exact partition-compatibility check, not a new SVD diagnostic.
samePhysicalGroup = physicalHz == physicalHz';
sameSelectedGroup = selectedHz == selectedHz';
compatible = isequal(samePhysicalGroup, sameSelectedGroup);
outcome = struct('status', "rejected", ...
    'nativeResult', [], 'assembly', assembly, 'physical', physical, 'review', review, ...
    'independentPhysicalFrequencyCount', numel(unique(physicalHz)), ...
    'nativeGroupingCompatible', compatible, 'thicknessDiagnostics', thicknessDiagnostics);
experimental = assembly.experimental;
if ~compatible
    [~, ~, experimental.independentFrequencyGroupId] = unique(assembly.physicalFrequency_Hz);
end
native = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    experimental, physical, options);
outcome.nativeResult = native;
outcome.status = "rejected";
if native.accepted, outcome.status = "accepted"; end
end
