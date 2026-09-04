function summary = diagnose_mrlfe_selected_refinement(varargin)
%DIAGNOSE_MRLFE_SELECTED_REFINEMENT Compare selected-only and refine-all refinement.
%
% On this development branch, trackerRefineCandidates=false means candidates
% are selected on the discrete Cp scan and only the selected local minimum is
% continuously refined. trackerRefineCandidates=true retains the previous
% refine-all behavior for comparison.

parser = inputParser;
parser.addParameter('Repeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

summary = diagnose_mrlfe_refinement_quantization( ...
    'Repeats', opt.Repeats, 'WriteCsv', false);
summary.Policy(summary.Policy == "discrete") = "selectedOnly";

fprintf('\nSelected-only production interpretation\n');
fprintf('=======================================\n');
disp(summary(:, {'Case','Policy','MedianSeconds','RuntimeRatioVsDiscrete', ...
    'ValidFraction','HighFrequencyMaxRelativeSecondDiff', ...
    'MaxAbsCpDifferenceBetweenPolicies_mps','CandidateTypeMismatchCount', ...
    'ValidMaskMismatchCount'}));

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'selected_refinement');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'selected_refinement_summary.csv'));
    fprintf('Saved Results/mrlfe/diagnostics/selected_refinement/selected_refinement_summary.csv\n');
end
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('mrlfe:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end
