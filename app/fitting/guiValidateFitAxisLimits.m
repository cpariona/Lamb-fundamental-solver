function axisViewState = guiValidateFitAxisLimits(xLimits_kHz, yLimits_mps)
%GUIVALIDATEFITAXISLIMITS Validate manual FitTool axis limits.

xLimits_kHz = double(xLimits_kHz(:)).';
yLimits_mps = double(yLimits_mps(:)).';
if numel(xLimits_kHz) ~= 2 || numel(yLimits_mps) ~= 2
    error('guiValidateFitAxisLimits:InvalidSize', ...
        'Axis limits must be two-element [min max] vectors.');
end
if any(~isfinite(xLimits_kHz)) || any(~isfinite(yLimits_mps))
    error('guiValidateFitAxisLimits:NonFinite', ...
        'Manual axis limits must be finite.');
end
if xLimits_kHz(1) >= xLimits_kHz(2)
    error('guiValidateFitAxisLimits:InvalidXRange', ...
        'X min [kHz] must be smaller than X max [kHz].');
end
if yLimits_mps(1) >= yLimits_mps(2)
    error('guiValidateFitAxisLimits:InvalidYRange', ...
        'Y min [m/s] must be smaller than Y max [m/s].');
end

axisViewState = struct( ...
    'xMode', "manual", ...
    'yMode', "manual", ...
    'xLimits_kHz', xLimits_kHz, ...
    'yLimits_mps', yLimits_mps);
end
