function results = rlComputeFundamentalLambModes(params, options)
%RLCOMPUTEFUNDAMENTALLAMBMODES Public Rayleigh-Lamb solver entrypoint.
%   RESULTS = RLCOMPUTEFUNDAMENTALLAMBMODES(PARAMS, OPTIONS) solves the
%   enabled fundamental A0/S0 branches of an isotropic elastic plate.
%   PARAMS uses SI units and full physical thickness; obtain defaults with
%   rlDefaultParams. OPTIONS controls branches and numerical effort; obtain
%   a Fast, Balanced, or Robust configuration with rlDefaultOptions.
%
%   Enabled result modes expose column vectors frequency_Hz,
%   phaseVelocity_mps, wavenumber_radpm, and validMask. Invalid phase speed
%   is NaN. The result also records material, geometry, quality, diagnostics,
%   execution evidence, and requested/effective configuration.

results = lamb.models.rayleigh_lamb.solvers.rlSolveFundamentalModes(params, options);
end
