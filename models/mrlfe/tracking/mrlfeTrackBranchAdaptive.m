function branch = mrlfeTrackBranchAdaptive(problem, seed, configuration, mrlfeParams, options)
%MRLFETRACKBRANCHADAPTIVE Track a production mRLFE branch adaptively.

branch = solveMRLFEBranchAdaptiveAtlas(configuration.branch, seed, ...
    problem.material, problem.geometry, mrlfeParams, options);
end
