% Inspect modal-atlas candidates near the A0-like 23 kHz mismatch band.
clear; clc; startup
fprintf('\n=== mRLFE A0 modal-atlas candidates near 23 kHz ===\n');

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
seed = rawRef.modes.A0; seedCp = seed.Cp(:);
fprintf('Maintained A0Like elastic: %.6g s | valid %d/%d\n', tref, nnz(refValid), numel(refValid));

atlasOpt = opt; atlasOpt.mrlfeModalAtlasCpScanPoints = 1200; atlasOpt.mrlfeModalAtlasTopNMinima = 24;
atlasOpt.mrlfeModalAtlasMaxLogCpJump = 0.075; atlasOpt.mrlfeModalAtlasCpMinFactor = 0.20;
atlasOpt.mrlfeModalAtlasCpMaxFactor = 2.80; atlasOpt.mrlfeModalAtlasCpMaxCeiling = 120;
atlasOpt.mrlfeModalAtlasMinBranchPoints = 8; atlasOpt.mrlfeModalAtlasRefineMinima = true;
atlasOpt.mrlfeModalAtlasRequireLowStartRank = false; atlasOpt.mrlfeModalAtlasRequireResidualValidity = false;

t = tic; atlas = solveMRLFEBranchModalAtlas("A0Like", seed, mat, rmfield(geom,'halfThickness'), opt.mrlfeParams, atlasOpt); tatlas = toc(t);
fprintf('Atlas: %.6g s | selected family %g | valid %d/%d\n', tatlas, atlas.modalAtlas.selectedFamily.BranchID, nnz(branchValid(atlas)), numel(f));

T = atlas.modalAtlas.minimaTable;
maskBand = T.Frequency_Hz >= 22.5e3 & T.Frequency_Hz <= 24.2e3;
Tb = T(maskBand,:);
if isempty(Tb)
    error('No atlas candidates found in requested band.');
end
Tb.RefCp_mps = refCp(Tb.FrequencyIndex);
Tb.AbsToRef_mps = abs(Tb.Cp_mps - Tb.RefCp_mps);
Tb.SeedCp_mps = seedCp(Tb.FrequencyIndex);
Tb.AbsToSeed_mps = abs(Tb.Cp_mps - Tb.SeedCp_mps);
Tb.SelectedFamily = Tb.BranchID == atlas.modalAtlas.selectedFamily.BranchID;

freqList = unique(Tb.Frequency_Hz, 'stable');
reportRows = table();
for ii = 1:numel(freqList)
    Tf = sortrows(Tb(Tb.Frequency_Hz == freqList(ii),:), 'AbsToRef_mps');
    keep = Tf(1:min(6,height(Tf)), :);
    reportRows = [reportRows; keep]; %#ok<AGROW>
end

fprintf('\nCandidates closest to maintained reference in 22.5-24.2 kHz band\n');
disp(reportRows(:, {'Frequency_Hz','RefCp_mps','Cp_mps','AbsToRef_mps','Objective','MinRank','BranchID','SelectedFamily','SeedCp_mps','AbsToSeed_mps'}));

fprintf('\nSelected-family candidates in same band\n');
Ts = sortrows(Tb(Tb.SelectedFamily,:), {'Frequency_Hz','MinRank'});
disp(Ts(:, {'Frequency_Hz','RefCp_mps','Cp_mps','AbsToRef_mps','Objective','MinRank','BranchID','SeedCp_mps'}));

assignin('base','MRLFEA0ModalAtlasCandidates23kHz',Tb);
assignin('base','MRLFEA0ModalAtlasCandidates23kHzReport',reportRows);
assignin('base','MRLFEA0ModalAtlasCandidates23kHzAtlas',atlas);
assignin('base','MRLFEA0ModalAtlasCandidates23kHzReference',rawRef);

fprintf('\nInterpretation guide:\n');
fprintf('  - If candidates near RefCp exist but are not selected, fix local linking/repair.\n');
fprintf('  - If no candidates near RefCp exist, widen Cp window or refine candidate extraction.\n');
fprintf('  - If selected family changes branch ID or rank near 23 kHz, add branch-split/continuity repair.\n');

function valid = branchValid(branch)
cp = branch.Cp(:); valid = isfinite(cp) & cp > 0;
if isfield(branch,'validCp'), valid = valid & logical(branch.validCp(:)); elseif isfield(branch,'valid'), valid = valid & logical(branch.valid(:)); end
end
