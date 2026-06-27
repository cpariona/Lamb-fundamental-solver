% Test integrated ambiguity metadata and optional cut in solveMRLFEBranchModalAtlas.
clear; clc; startup
fprintf('\n=== Integrated mRLFE A0 modal-atlas cut diagnostic ===\n');

params = rlDefaultParams();
params.modelType = "ShearPoisson"; params.rho = 1070; params.mu = 158e3; params.nu = 0.4999;
params.thickness = 0.5e-3; params.fmin = 10; params.fmax = 32e3;
params.numFrequencyPoints = "auto"; params.frequencySpacing = "hybrid";
mat = rlComputeMaterial(params);
params.E = mat.E; params.K = mat.K; params.CL = mat.CL; params.CT = mat.CT; params.lambda = mat.lambda; params.nu = mat.nu;
geom = rlComputeGeometry(params); f = rlBuildFrequencyVector(params).';
fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(f), min(f), max(f));

opt = rlDefaultOptions("Fast");
opt.computeA0 = true; opt.computeS0 = false;
opt.computeMRLFE = false; opt.computeMRLFERealK = true; opt.computeMRLFEElasticRealK = true;
opt.computeMRLFEViscoRealK = false; opt.computeMRLFEComplexK = false;
opt.mrlfeComputeA0Like = true; opt.mrlfeComputeS0Like = false;
opt.mrlfeParams = defaultMRLFEParams(); opt.mrlfeParams.fluidDensity = 1000; opt.mrlfeParams.fluidSoundSpeed = 1500;
opt.mrlfeParams.etaS = 0; opt.mrlfeParams.etaL = 0; opt.mrlfeParams.useComplexLambda = false;

t = tic; rawRef = rlComputeFundamentalLambModes(params,opt); tref = toc(t);
ref = rawRef.models.mRLFERealK.branches.A0Like; refCp = ref.Cp(:); refValid = branchValid(ref);
seed = rawRef.modes.A0;
fprintf('Maintained A0Like elastic: %.6g s | valid %d/%d\n', tref, nnz(refValid), numel(refValid));

baseAtlas = opt; baseAtlas.mrlfeModalAtlasCpScanPoints = 1200; baseAtlas.mrlfeModalAtlasTopNMinima = 24;
baseAtlas.mrlfeModalAtlasMaxLogCpJump = 0.075; baseAtlas.mrlfeModalAtlasCpMinFactor = 0.20;
baseAtlas.mrlfeModalAtlasCpMaxFactor = 2.80; baseAtlas.mrlfeModalAtlasCpMaxCeiling = 120;
baseAtlas.mrlfeModalAtlasMinBranchPoints = 8; baseAtlas.mrlfeModalAtlasRefineMinima = true;
baseAtlas.mrlfeModalAtlasRequireLowStartRank = false; baseAtlas.mrlfeModalAtlasRequireResidualValidity = false;

cases = table();
cases.Label = ["continuous"; "cut_default"; "cut_ratio4_gap8"; "cut_ratio4_gap12"; "cut_ratio3_gap12"];
cases.ApplyCut = [false; true; true; true; true];
cases.Ratio = [4; 4; 4; 4; 3];
cases.Separation = [0.16; 0.16; 0.16; 0.16; 0.16];
cases.MaxGap = [6; 6; 8; 12; 12];
cases.Padding = [1; 1; 2; 2; 2];
cases.MinTriggers = [2; 2; 2; 2; 2];
summary = table();
for i = 1:height(cases)
    atlasOpt = baseAtlas;
    atlasOpt.mrlfeModalAtlasApplyAmbiguityCut = cases.ApplyCut(i);
    atlasOpt.mrlfeModalAtlasAmbiguityResidualRatio = cases.Ratio(i);
    atlasOpt.mrlfeModalAtlasAmbiguityMinCpSeparation = cases.Separation(i);
    atlasOpt.mrlfeModalAtlasAmbiguityMaxGapPoints = cases.MaxGap(i);
    atlasOpt.mrlfeModalAtlasAmbiguityPaddingPoints = cases.Padding(i);
    atlasOpt.mrlfeModalAtlasAmbiguityMinClusterTriggers = cases.MinTriggers(i);

    t = tic; b = solveMRLFEBranchModalAtlas("A0Like", seed, mat, rmfield(geom,'halfThickness'), opt.mrlfeParams, atlasOpt); tb = toc(t);
    valid = branchValid(b); cmp = compareCp(refCp, refValid, b.Cp(:), valid);
    row = table();
    row.Label = string(cases.Label(i)); row.Time_s = tb; row.ApplyCut = cases.ApplyCut(i);
    row.ValidPoints = nnz(valid); row.AmbiguityPoints = nnz(b.modalAmbiguityMask);
    row.NumClusters = height(b.modalAmbiguityClusters); row.RMSE_mps = cmp.RMSE; row.P95_mps = cmp.P95; row.MaxAbs_mps = cmp.MaxAbs;
    row.FirstAmbiguity_Hz = firstFreq(f,b.modalAmbiguityMask); row.LastAmbiguity_Hz = lastFreq(f,b.modalAmbiguityMask);
    summary = [summary; row]; %#ok<AGROW>
    fprintf('%s: %.6g s | valid %d | ambiguity %d | clusters %d | RMSE %.6g | P95 %.6g | max %.6g\n', ...
        row.Label, tb, nnz(valid), nnz(b.modalAmbiguityMask), height(b.modalAmbiguityClusters), cmp.RMSE, cmp.P95, cmp.MaxAbs);
end

fprintf('\nIntegrated cut summary\n'); disp(summary);
assignin('base','MRLFEA0ModalAtlasIntegratedCutSummary',summary);
assignin('base','MRLFEA0ModalAtlasIntegratedCutReference',rawRef);

function cmp = compareCp(refCp, refValid, cp, valid)
mask = refValid(:) & valid(:) & isfinite(refCp(:)) & isfinite(cp(:)); err = cp(:)-refCp(:); ae=abs(err);
cmp.RMSE=nan; cmp.P95=nan; cmp.MaxAbs=nan; if any(mask), cmp.RMSE=sqrt(mean(err(mask).^2,'omitnan')); cmp.P95=pct(ae(mask),95); cmp.MaxAbs=max(ae(mask),[],'omitnan'); end
end
function valid = branchValid(branch)
cp=branch.Cp(:); valid=isfinite(cp)&cp>0; if isfield(branch,'validCp'), valid=valid&logical(branch.validCp(:)); elseif isfield(branch,'valid'), valid=valid&logical(branch.valid(:)); end
end
function v=pct(x,p), x=sort(x(isfinite(x))); if isempty(x), v=nan; else, v=x(max(1,min(numel(x),ceil(p/100*numel(x))))); end, end
function v=firstFreq(f,m), i=find(m(:),1,'first'); if isempty(i), v=nan; else, v=f(i); end, end
function v=lastFreq(f,m), i=find(m(:),1,'last'); if isempty(i), v=nan; else, v=f(i); end, end
