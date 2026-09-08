function test_mrlfe_production_core_contract()
%TEST_MRLFE_PRODUCTION_CORE_CONTRACT Validate production-core ownership and metadata.

fprintf('\nRunning mRLFE production core contract test...\n');
fprintf('---------------------------------------------\n');

request = localRequest("A0Like", 0.05, "fast", "physicalTail");
result = lamb.models.mrlfe.mrlfeSolve(request);
assert(result.execution.internalEngine == "viscoelastic_adaptive", ...
    'Effective engine name must be neutral for viscoelastic cases.');
assert(~contains(result.execution.internalEngine, "Fit") && ...
    ~contains(result.execution.internalEngine, "GUI") && ...
    ~contains(result.execution.internalEngine, "Unified"), ...
    'Effective engine must not expose historical route naming.');
assert(result.execution.requestedPreset == "fast", 'Requested preset metadata changed.');
assert(result.execution.effectivePreset == "fast", 'Effective preset metadata changed.');
assert(result.fallback.applied == false, 'Production core must not apply fallback.');

elastic = lamb.models.mrlfe.mrlfeSolve(localRequest("S0Like", 0, "fast", "none"));
assert(elastic.execution.internalEngine == "elastic_adaptive", ...
    'Effective engine name must be neutral for zero-viscosity cases.');

assertTrackerLifecycle();

fprintf('mRLFE production core contract test passed.\n');
end

function assertTrackerLifecycle()
trackerPath = which('lamb.models.mrlfe.tracking.mrlfeTrackBranchAdaptive');
code = executableMatlabText(fileread(trackerPath));
flat = regexprep(code, '\s+', ' ');

assert(~isempty(regexp(flat, ...
    'needsRescue\s*=\s*tracker\.rescueCpScanPoints\s*>\s*tracker\.cpScanPoints\s*&&\s*\(~best\.valid\s*\|\|\s*best\.type\s*==\s*"valleyFallback"\)', 'once')), ...
    'Dense rescue must remain limited to invalid or valley-fallback coarse candidates.');

selectionPosition = regexp(code, '\<chooseBestCandidate\s*\(', 'once');
selectedRefinementPosition = regexp(code, ...
    'lamb\.models\.mrlfe\.tracking\.mrlfeRefineSelectedCandidate\s*\(', 'once');
assert(isscalar(selectionPosition) && isscalar(selectedRefinementPosition) && ...
    selectedRefinementPosition > selectionPosition, ...
    'mRLFE must select a discrete candidate before refining only that candidate.');
assert(~isempty(regexp(flat, ...
    'if\s+~tracker\.refineCandidates\s+best\s*=\s*lamb\.models\.mrlfe\.tracking\.mrlfeRefineSelectedCandidate\s*\(', 'once')), ...
    'The maintained non-refine-all route must call the selected-candidate refiner.');

assert(~isempty(regexp(flat, ...
    'tracker\.edgeGuardPoints\s*=\s*getOption\(options,\s*''trackerEdgeGuardPoints'',\s*4\)', 'once')), ...
    'The tracker must consume the protected edge-guard configuration.');
assert(~isempty(regexp(flat, ...
    'firstAllowed\s*=\s*1\s*\+\s*tracker\.edgeGuardPoints', 'once')) && ...
    ~isempty(regexp(flat, ...
    'lastAllowed\s*=\s*numel\(residual\)\s*-\s*tracker\.edgeGuardPoints', 'once')), ...
    'Candidate discovery must apply the edge guard at both scan boundaries.');
end

function text = executableMatlabText(text)
text = regexprep(text, '%\{[\s\S]*?%\}', ' ');
text = regexprep(text, '%[^\r\n]*', ' ');
text = regexprep(text, '\.\.\.[^\r\n]*', ' ');
end

function request = localRequest(branch, etaS, preset, terminationPolicy)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', string(preset));
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', string(terminationPolicy));
request.fallback = struct('policy', "none");
end
