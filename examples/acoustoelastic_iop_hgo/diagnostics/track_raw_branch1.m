clear; clc; close all;
launchFolder = pwd;
startup

%TRACK_RAW_BRANCH1 Short AE IOP/HGO raw branch-1 tracking diagnostic entrypoint.
%
% Diagnostic only. Extracts the corrected raw-matrix branch-1 candidate from
% the low-frequency modal-atlas outputs and writes:
%   Results/ae_iop_hgo/raw_branch1
%
% This does not promote raw_branch1 and does not modify result.Cp or
% result.validCp.

rawBranch = aeExtractRawBranch1Candidate(launchFolder);

fprintf('\nCandidate summary\n');
disp(rawBranch.candidateSummary);

fprintf('\nTracker comparison summary\n');
disp(rawBranch.comparisonSummary);

fprintf('\nData files written to:\n%s\n', rawBranch.outputFolder);

assignin('base', 'AcoustoelasticIOPHGORawBranchCandidateSummary', rawBranch.candidateSummary);
assignin('base', 'AcoustoelasticIOPHGORawBranchCandidateCurve', rawBranch.candidateCurve);
assignin('base', 'AcoustoelasticIOPHGORawBranchTrackerComparison', rawBranch.trackerComparison);
assignin('base', 'AcoustoelasticIOPHGORawBranchTrackerComparisonSummary', rawBranch.comparisonSummary);
