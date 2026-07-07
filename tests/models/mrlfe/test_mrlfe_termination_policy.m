clear; clc;
startup

fprintf('\nRunning mRLFE termination policy test...\n');
fprintf('---------------------------------------\n');

physicalTail = mrlfeSolve(localRequest("A0Like", 0.05, "physicalTail"));
none = mrlfeSolve(localRequest("A0Like", 0.05, "none"));
s0PhysicalTail = mrlfeSolve(localRequest("S0Like", 0.05, "physicalTail"));

assert(isfield(physicalTail.diagnostics.rawInternalResult.branchSolve, 'physicalCorridor'), ...
    'A0 physicalTail should evaluate the physical-tail policy.');
assert(~isfield(none.diagnostics.rawInternalResult.branchSolve, 'physicalCorridor'), ...
    'A0 none policy must not apply the physical-tail policy.');
assert(~isfield(s0PhysicalTail.diagnostics.rawInternalResult.branchSolve, 'physicalCorridor'), ...
    'S0 must not apply A0 physical-tail policy.');
assert(none.termination.policy == "none", 'Termination metadata should preserve requested none policy.');
assert(none.fallback.applied == false, 'Termination policy must not apply fallback.');

fprintf('mRLFE termination policy test passed.\n');

function request = localRequest(branch, etaS, terminationPolicy)
request = struct();
request.branch = string(branch);
request.frequency_Hz = linspace(1000, 6000, 10).';
request.material = struct('mu_Pa', 75e3, 'etaS_Pas', etaS, 'rho_kgm3', 1000, 'nu', 0.4999);
request.geometry = struct('thickness_m', 0.5e-3);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', string(terminationPolicy));
request.fallback = struct('policy', "none");
end
