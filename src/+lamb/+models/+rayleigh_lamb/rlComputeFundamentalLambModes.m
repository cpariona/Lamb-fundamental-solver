function results = rlComputeFundamentalLambModes(params, options)
%RLCOMPUTEFUNDAMENTALLAMBMODES Public Rayleigh-Lamb solver entrypoint.

results = lamb.models.rayleigh_lamb.solvers.rlSolveFundamentalModes(params, options);
end
