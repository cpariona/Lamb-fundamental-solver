function sweepOutput = guiRunSweep(request)
%GUIRUNSWEEP Dispatch a normalized GUI sweep request to a model adapter.
%
% This function is the stable GUI-facing sweep entrypoint. Model-specific
% details belong in app/adapters/guiRun<Model>Sweep functions.

modelFamily = lower(string(request.modelFamily));

switch modelFamily
    case "mrlfe"
        sweepOutput = guiRunMRLFESweep(request);
    case {"rayleigh_lamb", "rayleighlamb", "rl"}
        sweepOutput = guiRunRLSweep(request);
    case {"ae_iop_hgo", "ae_iop", "acoustoelastic_iop_hgo", "acoustoelasticiophgo"}
        sweepOutput = guiRunAcoustoelasticIOPHGOSweep(request);
    otherwise
        error('Unsupported GUI sweep model family: %s', string(request.modelFamily));
end
end
