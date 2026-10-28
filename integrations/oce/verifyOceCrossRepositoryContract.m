function report = verifyOceCrossRepositoryContract(oceRoot)
%VERIFYOCECROSSREPOSITORYCONTRACT Check OCE-generated MAT against Lamb's adapter.
% This opt-in MATLAB test requires both local source checkouts; it does not
% run in Lamb's standalone regression gate or write experimental data.
% OCE owns the result builder, validator, persistence, and schema semantics.
arguments
    oceRoot (1,1) string
end

oceRoot = string(char(java.io.File(char(oceRoot)).getCanonicalPath()));
if ~isfolder(fullfile(oceRoot, "src", "+oce")) || ...
        ~isfile(fullfile(oceRoot, "tests", "helpers", ...
        "create_dispersion_analysis_fixture.m"))
    error("lamb:oceCrossRepo:MissingOce", ...
        "Provide a local OCE_Workflow checkout with source and maintained fixtures.");
end

previousPath = path;
pathCleanup = onCleanup(@() path(previousPath)); %#ok<NASGU>
lambRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(lambRoot, "integrations", "oce"), "-end");
addpath(fullfile(oceRoot, "src"), "-end");
addpath(fullfile(oceRoot, "tests", "helpers"), "-end");
for dependency = ["MIMT", "fireice"]
    folder = fullfile(oceRoot, "third_party", dependency);
    if isfolder(folder), addpath(folder, "-end"); end
end

% Produce each source result using the actual maintained OCE runtime path.
fixture = create_dispersion_analysis_fixture();
root = string(tempname);
mkdir(root);
tempCleanup = onCleanup(@() rmdir(root, "s")); %#ok<NASGU>
modes = ["QH"; "Pulse"];
resultPaths = strings(numel(modes), 1);
selectedCounts = zeros(numel(modes), 1);

for index = 1:numel(modes)
    options = fixture.DispersionAnalysisOptions;
    if modes(index) == "Pulse"
        editable = fixture.config_for_run.DispersionAnalysisOptions;
        editable.target_frequency.source = "not_available";
        options = oce.config.resolveDispersionAnalysisOptions( ...
            editable, fixture.FilterOptions);
    end
    analysis = oce.dispersion.analyzeWindows( ...
        fixture.window_result, fixture.DistBorder, options);
    config = fixture.config_for_run;
    config.DispersionAnalysisOptions = options;
    result = oce.results.buildScientificResult( ...
        fixture.processing_inputs, config, fixture.window_result, analysis);
    folder = fullfile(root, modes(index));
    mkdir(folder);
    resultPath = oce.io.saveScientificResult(folder, result);
    loaded = oce.io.loadScientificResult(resultPath);
    assert(isequaln(loaded, result), ...
        "lamb:oceCrossRepo:RoundTrip", "OCE save/load changed the source result.");

    kf = loaded.dispersion.estimators.kf_ridge;
    original = kf.directions(1);
    frequency = double(kf.frequency_axis_hz(:));
    speed = double(original.phase_speed_curve.smoothed_phase_speed_m_per_s(:));
    valid = logical(original.ridge.valid_mask(:));
    mask = valid & isfinite(frequency) & frequency > 0 & ...
        isfinite(speed) & speed > 0;
    assert(any(mask), "lamb:oceCrossRepo:NoValidData", ...
        "The maintained OCE fixture produced no eligible k-f observations.");

    selection = struct("directionIndex", 1, "estimator", "kf_ridge", ...
        "curve", "smoothed", "validMask", mask);
    metadata = struct("conditionId", "synthetic_cross_repository", ...
        "repetitionId", 1, ...
        "loadingCondition", struct("type", "synthetic"), ...
        "sourceResultFile", string(resultPath), ...
        "metadataReference", "generated_OCE_fixture");
    prepared = prepareOceFitObservations(loaded, selection, metadata);

    assert(isequaln(prepared.experimental.frequency_Hz, frequency) && ...
        isequaln(prepared.experimental.Cp_mps, speed) && ...
        isequal(prepared.experimental.validMask, mask), ...
        "lamb:oceCrossRepo:ValueDrift", ...
        "The Lamb adapter changed frequency, speed, order or the reviewed mask.");
    assert(isequaln(prepared.measuredThickness_m, ...
        double(loaded.borders.directional_mean_thickness_mm(1)) * 1e-3), ...
        "lamb:oceCrossRepo:ThicknessDrift", ...
        "Current directional full thickness was not converted mm to m.");
    assert(isequaln(prepared.experimental.source.estimatorEvidence.originalMasks.valid_mask(:), ...
        original.ridge.valid_mask(:)), ...
        "lamb:oceCrossRepo:SourceMaskDrift", ...
        "The producer ridge mask was not preserved as source evidence.");
    assert(prepared.experimental.source.processingRunId == loaded.processing_run_id && ...
        prepared.experimental.directionId == "scan_axis_1:left", ...
        "lamb:oceCrossRepo:IdentityDrift", ...
        "The source provenance or signed direction changed.");

    resultPaths(index) = string(resultPath);
    selectedCounts(index) = nnz(mask);
end
report = struct("status", "passed", "source", "OCE maintained builder + MAT I/O", ...
    "consumer", "Lamb maintained OCE adapter", "modes", modes, ...
    "selectedCounts", selectedCounts, "resultPaths", resultPaths, ...
    "note", "Synthetic data only; does not validate experimental inversion.");
end
