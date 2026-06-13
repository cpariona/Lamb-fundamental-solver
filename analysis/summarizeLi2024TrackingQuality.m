function summaryTable = summarizeLi2024TrackingQuality(varargin)
%SUMMARIZELI2024TRACKINGQUALITY Compatibility wrapper for Acoustoelastic IOP/HGO tracking summaries.
%
% summaryTable = summarizeLi2024TrackingQuality(results, labels, ...) calls
% summarizeAcoustoelasticIOPHGOTrackingQuality with the same inputs.

summaryTable = summarizeAcoustoelasticIOPHGOTrackingQuality(varargin{:});
end
