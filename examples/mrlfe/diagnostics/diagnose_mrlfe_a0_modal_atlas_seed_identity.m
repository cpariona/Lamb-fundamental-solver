% Re-score experimental mRLFE A0 modal-atlas families using RL A0 seed distance.
clear; clc; startup
fprintf('\n=== mRLFE A0 modal-atlas seed identity diagnostic ===\n');

params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 158e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 10;
params.fmax = 32e3;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
mat = rlComputeMaterial(params);
params.E = mat.E; params.K = mat.K; params.CL = mat.CL; params.CT = mat.CT; params.lambda = mat.lambda; params.nu = mat.nu;
geom = rlComputeGeometry(params);
f = rlBuildFrequencyVector(params).';
fprintf('Auto frequency points: %d | fmin %.6g Hz | fmax %.6g Hz\n', numel(f), min(f), max(f));

opt = rlDefaultOptions("Fast");
opt.computeA0 = true; opt.computeS0 = false;
opt.computeMRLFE = false; opt.computeMRLFERealK = true;
opt.computeMRLFEElasticRealK = true; opt.computeMRLFEViscoRealK = false; opt.computeMRLFEComplexK = false;
opt.mrlfeComputeA0Like = true; opt.mrlfeComputeS0Like = false;
opt.mrlfeParams = defaultMRLFEParams();
opt.mrlfeParams.fluidDensity = 1000;
opt.mrlfeParams.fluidSoundSpeed = 1500;
opt.mrlfeParams.etaS = 0; opt.mrlfeParams.etaL = 0; opt.mrlfeParams.useComplexLambda = false;

t = tic; rawRef = rlComputeFundamentalLambModes(params, opt); tref = toc(t);
refBranch = rawRef.models.mRLFERealK.branches.A0Like;
refCp = refBranch.Cp(:); refValid = branchValid(refBranch);
seed = rawRef.modes.A0; seedCp = seed.Cp(:);
fprintf('Maintained A0Like elastic: %.6g s | valid %d/%d\n', tref, nnz(refValid), numel(refValid));

atlasOpt = opt;
atlasOpt.mrlfeModalAtlasCpScanPoints = 1200;
atlasOpt.mrlfeModalAtlasTopNMinima = 24;
atlasOpt.mrlfeModalAtlasMaxLogCpJump = 0.075;
atlasOpt.mrlfeModalAtlasCpMinFactor = 0.20;
atlasOpt.mrlfeModalAtlasCpMaxFactor = 2.80;
atlasOpt.mrlfeModalAtlasCpMaxCeiling = 120;
atlasOpt.mrlfeModalAtlasMinBranchPoints = 8;
atlasOpt.mrlfeModalAtlasRefineMinima = true;
atlasOpt.mrlfeModalAtlasRequireLowStartRank = false;
atlasOpt.mrlfeModalAtlasRequireResidualValidity = false;

t = tic; atlasBranch = solveMRLFEBranchModalAtlas("A0Like", seed, mat, rmfield(geom,'halfThickness'), opt.mrlfeParams, atlasOpt); tatlas = toc(t);
Tmin = atlasBranch.modalAtlas.minimaTable;
fam = familyMetrics(Tmin, f, seedCp, refCp, refValid);
weights = [0; 0.25; 0.5; 1; 2; 4; 8; 12];
summary = table();
for iw = 1:numel(weights)
    w = weights(iw);
    scored = scoreFamilies(fam, w);
    sel = scored(1,:);
    [cp, valid, rank, fid] = reconstructFamily(Tmin, f, sel.BranchID);
    met = compareCp(f, refCp, refValid, cp, valid);
    row = table();
    row.SeedWeight = w;
    row.SelectedBranchID = sel.BranchID;
    row.ValidPoints = nnz(valid);
    row.OverlapPoints = met.OverlapPoints;
    row.Score = sel.Score;
    row.Coverage = sel.Coverage;
    row.MedianSeedLogDistance = sel.MedianSeedLogDistance;
    row.MedianRank = sel.MedianRank;
    row.RMSE_mps = met.RMSE;
    row.P95AbsError_mps = met.P95;
    row.MaxAbsError_mps = met.MaxAbs;
    row.FirstLargeError_Hz = met.FirstLarge;
    summary = [summary; row]; %#ok<AGROW>
    fprintf('w %.3g -> branch %g | valid %d | RMSE %.6g | P95 %.6g | max %.6g | first large %.6g Hz\n', ...
        w, sel.BranchID, nnz(valid), met.RMSE, met.P95, met.MaxAbs, met.FirstLarge);
end

fprintf('\nFamily metrics by seed distance\n');
bySeed = sortrows(fam, 'MedianSeedLogDistance');
disp(bySeed(1:min(12,height(bySeed)), {'BranchID','Coverage','NumPoints','StartRank','MedianRank','MedianSeedLogDistance','RMSE_ref','MaxAbs_ref'}));
fprintf('\nSeed-weight summary\n');
disp(summary);
assignin('base','MRLFEA0ModalAtlasSeedIdentitySummary',summary);
assignin('base','MRLFEA0ModalAtlasSeedIdentityFamilies',fam);
assignin('base','MRLFEA0ModalAtlasSeedIdentityAtlasBranch',atlasBranch);
assignin('base','MRLFEA0ModalAtlasSeedIdentityReference',rawRef);

function fam = familyMetrics(Tmin, f, seedCp, refCp, refValid)
ids = unique(Tmin.BranchID(isfinite(Tmin.BranchID)), 'stable'); rows = [];
for ii = 1:numel(ids)
    id = ids(ii); [cp, valid, rank, ~] = reconstructFamily(Tmin, f, id);
    smask = valid & isfinite(seedCp) & seedCp > 0 & cp > 0;
    sd = nan; if any(smask), sd = median(abs(log(cp(smask)./seedCp(smask))), 'omitnan'); end
    met = compareCp(f, refCp, refValid, cp, valid);
    r.BranchID = id; r.NumPoints = nnz(valid); r.Coverage = nnz(valid)/numel(f);
    r.StartRank = firstFinite(rank); r.MedianRank = median(rank(isfinite(rank)), 'omitnan');
    r.MedianSeedLogDistance = sd; r.RMSE_ref = met.RMSE; r.MaxAbs_ref = met.MaxAbs;
    rows = [rows; r]; %#ok<AGROW>
end
fam = struct2table(rows);
end

function scored = scoreFamilies(fam, w)
T = fam;
coverageCost = 1 - T.Coverage;
rankCost = normMetric(T.MedianRank);
startCost = normMetric(T.StartRank);
seedCost = normMetric(T.MedianSeedLogDistance);
T.Score = 2.0*coverageCost + 0.8*rankCost + 0.4*startCost + w*seedCost;
scored = sortrows(T, {'Score','MedianSeedLogDistance','MedianRank'});
end

function [cp, valid, rank, fid] = reconstructFamily(Tmin, f, id)
cp = nan(size(f)); rank = nan(size(f)); fid = nan(size(f));
rows = Tmin(Tmin.BranchID == id,:);
for ii = 1:height(rows)
    jj = rows.FrequencyIndex(ii);
    if jj >= 1 && jj <= numel(f)
        cp(jj) = rows.Cp_mps(ii); rank(jj) = rows.MinRank(ii); fid(jj) = id;
    end
end
valid = isfinite(cp) & cp > 0;
end

function met = compareCp(f, refCp, refValid, cp, valid)
mask = refValid(:) & valid(:) & isfinite(refCp(:)) & isfinite(cp(:));
err = cp(:) - refCp(:); ae = abs(err);
met.OverlapPoints = nnz(mask); met.RMSE = nan; met.P95 = nan; met.MaxAbs = nan; met.FirstLarge = nan;
if any(mask)
    met.RMSE = sqrt(mean(err(mask).^2, 'omitnan'));
    met.P95 = pct(ae(mask),95);
    met.MaxAbs = max(ae(mask),[],'omitnan');
    idx = find(mask & ae > 0.5,1,'first'); if ~isempty(idx), met.FirstLarge = f(idx); end
end
end

function valid = branchValid(branch)
cp = branch.Cp(:); valid = isfinite(cp) & cp > 0;
if isfield(branch,'validCp'), valid = valid & logical(branch.validCp(:)); elseif isfield(branch,'valid'), valid = valid & logical(branch.valid(:)); end
end
function y = normMetric(x)
x = x(:); m = isfinite(x); y = ones(size(x)); if ~any(m), return; end
mn = min(x(m)); mx = max(x(m)); if abs(mx-mn)<eps, y(m)=0; else, y(m)=(x(m)-mn)./(mx-mn); end
end
function v = pct(x,p)
x = sort(x(isfinite(x))); if isempty(x), v=nan; else, v=x(max(1,min(numel(x),ceil(p/100*numel(x))))); end
end
function v = firstFinite(x)
i = find(isfinite(x),1,'first'); if isempty(i), v=nan; else, v=x(i); end
end
