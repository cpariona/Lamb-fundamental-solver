function result = mrlfeSolve(request)
%MRLFESOLVE Solve a real-k mRLFE branch through the public request contract.
%   REQUEST contains branch, frequency_Hz, material, geometry, fluid,
%   numerics, selection, termination, and fallback. Public physical fields
%   use SI units: mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m,
%   density_kgm3, and soundSpeed_mps. frequency_Hz must be positive and
%   strictly ascending.
%
%   RESULT exposes branch, frequency_Hz, phaseVelocity_mps,
%   wavenumber_radpm, validMask, quality, termination, fallback, execution,
%   diagnostics, and requested/effective configuration. Invalid phase speed
%   is NaN. The maintained route selects A0Like/S0Like through adaptive
%   tracking and does not substitute a fallback curve.

configuration = lamb.models.mrlfe.configuration.mrlfeResolveConfiguration(request);
problem = lamb.models.mrlfe.core.mrlfeBuildProblem(configuration);

timerStart = tic;
rawResult = lamb.models.mrlfe.solvers.mrlfeSolveBranch(problem, configuration);
elapsedSeconds = toc(timerStart);

result = lamb.models.mrlfe.results.mrlfeBuildResult(configuration, rawResult, elapsedSeconds);
end
