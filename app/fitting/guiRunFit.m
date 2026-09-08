function fitOutput = guiRunFit(request)
%GUIRUNFIT Dispatch a normalized fitting request to a model-specific adapter.

modelFamily = lower(string(request.modelFamily));
switch modelFamily
    case {"rayleigh_lamb", "rayleighlamb", "rl"}
        fitOutput = rlGuiFitSolver(request);
    case {"mrlfe", "mrlfe_real_k", "mrlferealk"}
        fitOutput = mrlfeGuiFitSolver(request);
    case {"acoustoelastic_iop_hgo", "ae_iop_hgo", "ae"}
        fitOutput = aeGuiFitSolver(request);
    otherwise
        error('Unsupported GUI fit model family: %s', string(request.modelFamily));
end
end
