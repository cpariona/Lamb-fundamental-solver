function nativeConfig = translateOceMrlfeConfig(config)
%TRANSLATEOCEMRLFECONFIG Translate reviewed canonical SI mRLFE inputs to native names.
% CONFIG is the researcher-facing request: branchName ("A0Like"|"S0Like"),
% freeParams, fixedParams, initialGuess and bounds, using only
%   mu_Pa, etaS_Pas, density_kgpm3, thickness_m, poisson_ratio,
%   fluidDensity_kgpm3, fluidSoundSpeed_mps.
% Optional solverOptions and fitOptions are forwarded unchanged. Every
% physical value is supplied explicitly, either fixed or as a free parameter
% with a finite initial guess and bounds. No native default (rho, mu, nu,
% thickness, fluid properties, viscosity) is used to fill a missing input,
% and no legacy native name is accepted alongside the canonical one. The
% thickness is one reviewed scalar and cannot be fitted; fluid properties are
% fixed. Model-specific validity (for example the supported Poisson range)
% remains owned by lamb.fitting.mrlfe.mrlfeBuildFitProblem.
canonical = ["mu_Pa","etaS_Pas","density_kgpm3","thickness_m","poisson_ratio", ...
    "fluidDensity_kgpm3","fluidSoundSpeed_mps"];
native = ["mu","etaS","rho","thickness","nu","fluidDensity_kgm3","fluidSoundSpeed_mps"];
mayBeFree = ["mu_Pa","etaS_Pas","density_kgpm3","poisson_ratio"];
assert(isstruct(config)&&isscalar(config)&&all(isfield(config, ...
    {'branchName','freeParams','fixedParams','initialGuess','bounds'})), ...
    'lamb:study:MrlfeConfig', ...
    'mRLFE needs branchName, freeParams, fixedParams, initialGuess and bounds.');
branch = string(config.branchName);
assert(isscalar(branch)&&any(branch==["A0Like","S0Like"]), ...
    'lamb:study:ModelReview','Review A0Like/S0Like before mRLFE inversion.');
free = string(config.freeParams(:));
assert(~isempty(free)&&numel(unique(free))==numel(free)&&all(ismember(free,mayBeFree)), ...
    'lamb:study:MrlfeConfig', ...
    ['freeParams must be distinct entries of: %s. Thickness is one reviewed ' ...
    'scalar and fluid properties are fixed; neither can be fitted.'],strjoin(mayBeFree,", "));
for group = ["fixedParams","initialGuess","bounds"]
    assert(isstruct(config.(group))&&isscalar(config.(group)), ...
        'lamb:study:MrlfeConfig','%s must be a scalar struct.',group);
    names = string(fieldnames(config.(group)));
    assert(all(ismember(names,canonical)),'lamb:study:AmbiguousPhysicalInput', ...
        'Use only canonical SI names in %s: %s.',group,strjoin(canonical,", "));
end
fixedNames = string(fieldnames(config.fixedParams));
assert(isempty(intersect(fixedNames,free)),'lamb:study:AmbiguousPhysicalInput', ...
    'A parameter cannot be both fixed and free.');
assert(isempty(setxor(string(fieldnames(config.initialGuess)),free))&& ...
    isempty(setxor(string(fieldnames(config.bounds)),free)), ...
    'lamb:study:MrlfeConfig', ...
    'Supply an initial guess and bounds for exactly the free parameters.');
[~,position] = ismember(free,canonical);
nativeConfig = struct('branchName',branch,'freeParams',reshape(native(position),[],1), ...
    'fixedParams',struct(),'initialGuess',struct(),'bounds',struct());
for k = 1:numel(canonical)
    name = canonical(k);target = char(native(k));
    if any(free==name)
        guess = config.initialGuess.(name);
        limits = config.bounds.(name);
        validateattributes(guess,{'double'},{'scalar','real','finite'});
        validateattributes(limits,{'double'},{'vector','numel',2,'real','finite','increasing'});
        assert(guess>=limits(1)&&guess<=limits(2),'lamb:study:MrlfeConfig', ...
            'The %s initial guess must lie inside its reviewed bounds.',name);
        nativeConfig.initialGuess.(target) = guess;
        nativeConfig.bounds.(target) = limits(:).';
    else
        assert(any(fixedNames==name),'lamb:study:PhysicalInput', ...
            '%s must be supplied explicitly as a fixed value or a free parameter.',name);
        value = config.fixedParams.(name);
        validateattributes(value,{'double'},{'scalar','real','finite'});
        if name=="etaS_Pas"
            assert(value>=0,'lamb:study:PhysicalInput','etaS_Pas must be nonnegative.');
        elseif name~="poisson_ratio"
            assert(value>0,'lamb:study:PhysicalInput','%s must be positive.',name);
        end
        nativeConfig.fixedParams.(target) = value;
    end
end
for name = ["solverOptions","fitOptions"]
    if isfield(config,name),nativeConfig.(name) = config.(name);end
end
end
