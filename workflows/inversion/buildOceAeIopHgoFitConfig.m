function fitConfig = buildOceAeIopHgoFitConfig(ae)
%BUILDOCEAEIOPHGOFITCONFIG Translate reviewed SI inputs to the AE IOP/HGO fit request.
% AE is the researcher-facing struct reviewed by the human workflow:
%   branchName      "atlasA0" (the only official AE IOP/HGO fitting curve).
%   executionProfile "Fast" | "Balanced" | "Robust" (cost only, not physics).
%   freeParams      subset of ["iop_Pa","mu_Pa","k1_Pa","k2"].
%   fixedPhysical   every remaining quantity below, no defaults are supplied.
%   initialGuess    one value per free parameter, canonical name and unit.
%   bounds          one [lower upper] pair per free parameter.
% Canonical names and units: radius_m (m), thickness_m (current full m),
% iop_Pa (Pa), mu_Pa, k1_Pa (Pa), k2 (dimensionless), density_kgpm3 (tissue,
% kg/m^3), fluidDensity_kgpm3 (kg/m^3), fluidBulkModulus_Pa (Pa).
% The native AE symbols R, thickness, IOP, mu, k1, k2, rho, rhoF and
% fluidBulkModulus are model-owned and appear only in the returned request.
% No forward solve is run; native fixed-mask, frequency-axis and anchor
% validation remain with aeBuildFitProblem at execution time. Thickness is
% always fixed: it is reviewed geometry, never a fitted or OCE-derived value.
assert(isstruct(ae)&&isscalar(ae)&&all(isfield(ae,["branchName","executionProfile", ...
    "freeParams","fixedPhysical","initialGuess","bounds"])), ...
    'lamb:study:AEConfiguration', ...
    'Supply one complete AE IOP/HGO researcher configuration; no defaults are inferred.');
branch=string(ae.branchName);
assert(isscalar(branch)&&branch=="atlasA0",'lamb:study:AEBranch', ...
    'AE IOP/HGO inversion fits only the official atlasA0 curve; S0 and diagnostic branches are rejected.');
profile=string(ae.executionProfile);
assert(isscalar(profile)&&any(profile==["Fast","Balanced","Robust"]), ...
    'lamb:study:AEConfiguration','executionProfile must be Fast, Balanced or Robust.');

canonical=["radius_m","thickness_m","iop_Pa","mu_Pa","k1_Pa","k2","density_kgpm3", ...
    "fluidDensity_kgpm3","fluidBulkModulus_Pa"];
native=["R","thickness","IOP","mu","k1","k2","rho","rhoF","fluidBulkModulus"];
free=string(ae.freeParams(:))';
assert(~isempty(free)&&numel(unique(free))==numel(free)&& ...
    all(ismember(free,["iop_Pa","mu_Pa","k1_Pa","k2"])), ...
    'lamb:study:AEConfiguration', ...
    'Free parameters must be distinct members of iop_Pa, mu_Pa, k1_Pa and k2.');
fixedNames=string(fieldnames(ae.fixedPhysical))';
assert(isequal(sort(fixedNames),sort(setdiff(canonical,free))), ...
    'lamb:study:AEConfiguration', ...
    'fixedPhysical must contain exactly the canonical SI names that are not free (no legacy native names).');
assert(isequal(sort(string(fieldnames(ae.initialGuess))'),sort(free))&& ...
    isequal(sort(string(fieldnames(ae.bounds))'),sort(free)), ...
    'lamb:study:AEConfiguration','Provide one initial guess and one bounds pair per free parameter.');

positive={'double'};attributes={'scalar','real','finite','positive'};
fixedParams=struct();
for name=fixedNames
    validateattributes(ae.fixedPhysical.(name),positive,attributes);
    fixedParams.(native(canonical==name))=ae.fixedPhysical.(name);
end
initialGuess=struct();bounds=struct();freeNative=strings(numel(free),1);
for k=1:numel(free)
    name=free(k);key=native(canonical==name);freeNative(k)=key;
    validateattributes(ae.initialGuess.(name),positive,attributes);
    validateattributes(ae.bounds.(name),positive,{'vector','numel',2,'real','finite','positive','increasing'});
    assert(ae.initialGuess.(name)>=ae.bounds.(name)(1)&&ae.initialGuess.(name)<=ae.bounds.(name)(2), ...
        'lamb:study:AEConfiguration','The %s initial guess must lie inside its bounds.',name);
    initialGuess.(key)=ae.initialGuess.(name);
    bounds.(key)=reshape(ae.bounds.(name),1,2);
end
fitConfig=struct('branchName',"atlasA0",'freeParams',freeNative, ...
    'fixedParams',fixedParams,'initialGuess',initialGuess,'bounds',bounds, ...
    'solverOptions',lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions(profile));
end
