function guiApplyFitAxisView(ax, axisViewState)
%GUIAPPLYFITAXISVIEW Apply persistent FitTool axis-view state.

if nargin < 2 || isempty(axisViewState) || ~isstruct(axisViewState) || ~isgraphics(ax, 'axes')
    return;
end

if isfield(axisViewState, 'xMode') && string(axisViewState.xMode) == "manual" && ...
        isfield(axisViewState, 'xLimits_kHz') && numel(axisViewState.xLimits_kHz) == 2
    xlim(ax, axisViewState.xLimits_kHz);
else
    xlim(ax, 'auto');
end

if isfield(axisViewState, 'yMode') && string(axisViewState.yMode) == "manual" && ...
        isfield(axisViewState, 'yLimits_mps') && numel(axisViewState.yLimits_mps) == 2
    ylim(ax, axisViewState.yLimits_mps);
else
    ylim(ax, 'auto');
end
end
