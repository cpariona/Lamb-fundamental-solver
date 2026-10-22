function outcome = fitOceQhPrestressedPlate(assembly, physical, review, options)
%FITOCEQHPRESTRESSEDPLATE Coordinate a reviewed constant-thickness A0 request.
% ASSEMBLY comes from prepareOceQhFitObservations. PHYSICAL contains only
% density_kgpm3 and current full thickness_m (positive scalar SI values).
% REVIEW requires mode="A0", thicknessPolicy="explicit_constant_current_thickness",
% thicknessSource, thicknessJustification, densityReference and modelSupportReference. These
% nonempty references record the caller's physical review, not inferred physics.
% No mean thickness or load/DIC constraint is computed. OPTIONS is passed
% unchanged to aePlateFitDispersion; its native result/diagnostics are retained.
% If physical QH groups and exact selected-Hz groups differ, no fit is run:
% the current Plate API cannot express independent groups separately from Hz.
% A matching grouping does not itself prove identifiability or model support.
% Original OCT thicknesses, including NaNs, remain in assembly. The supplied
% scalar may come from an independent current physical measurement. Compact
% OCT availability/range diagnostics are descriptive and never affect acceptance.

if nargin < 4, options = struct(); end
validateattributes(physical, {'struct'}, {'scalar'});
if ~isempty(setxor(fieldnames(physical), {'density_kgpm3'; 'thickness_m'}))
    error('lamb:oceQh:InvalidPhysicalInputs', 'Plate requires only explicit current thickness and density.');
end
for name = ["density_kgpm3", "thickness_m"]
    validateattributes(physical.(name), {'double'}, {'scalar', 'real', 'finite', 'positive'});
end
if ~isequal(review.mode, "A0") || ...
        ~isequal(review.thicknessPolicy, "explicit_constant_current_thickness")
    error('lamb:oceQh:PhysicalReviewRequired', 'Explicit A0 and a reviewed constant-current-thickness policy are required.');
end
for name = ["thicknessSource", "thicknessJustification", "densityReference", "modelSupportReference"]
    value = string(review.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value)) == 0
        error('lamb:oceQh:PhysicalReviewRequired', 'Nonempty %s is required.', name);
    end
end
mask = assembly.experimental.validMask;
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
outcome = struct('status', "requires_independent_frequency_groups", ...
    'nativeResult', [], 'assembly', assembly, 'physical', physical, 'review', review, ...
    'independentPhysicalFrequencyCount', numel(unique(physicalHz)), ...
    'nativeGroupingCompatible', compatible, 'thicknessDiagnostics', thicknessDiagnostics);
if ~compatible
    return;
end
native = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    assembly.experimental, physical, options);
outcome.nativeResult = native;
outcome.status = "rejected";
if native.accepted, outcome.status = "accepted"; end
end
