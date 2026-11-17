function [fig, evidence] = plotMrlfeFitDiagnostics(result, provenance, varargin)
%PLOTMRLFEFITDIAGNOSTICS Present a stored native mRLFE A0Like/S0Like inversion.
%   RESULT is the unchanged mrlfeFitDispersionData output. PROVENANCE requires
%   label, material, sourceReference and modelAssumptionsJustification. Optional
%   repetitionId identifies every original row; displayLabel/displaySubtitle
%   are text only. DisplayObservationMask is one logical glyph filter per
%   original row; it never changes the fitted mask.
%   No OCE I/O, fitting, forward evaluation or physical acceptance is
%   performed. The layout follows the RL diagnostic (A. dispersion, B. native
%   fit, C. native raw residuals in m/s) with the mRLFE branch, fluid loading
%   and viscosity reported from the stored native parameters. The reported
%   model line is the stored requested-curve prediction on the strictly
%   ascending native axis; unavailable predictions remain gaps. The native
%   forward cache and solver options are not copied into the figure data.
%   All rows remain in evidence.observations and FIG.UserData.
p = inputParser;
addParameter(p,'DisplayObservationMask',[],@(v) isempty(v)||islogical(v));
addParameter(p,'Visible','on',@(x) any(string(x)==["on","off"]));
parse(p,varargin{:});
provenance = normalizeInverseProvenance(provenance);
if string(result.modelFamily) ~= "mrlfe" || ...
        ~any(string(result.branchName)==["A0Like","S0Like"])
    error('lamb:visualization:UnsupportedResult','Use a native mRLFE A0Like/S0Like fit.');
end
for name = ["label","material","sourceReference","modelAssumptionsJustification"]
    value = string(provenance.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value))==0
        error('lamb:visualization:MissingProvenance','Nonempty %s is required.',name);
    end
end
f = result.frequency_Hz(:); observed = result.Cp_exp_mps(:);
predicted = result.Cp_fit_mps(:); selected = result.validMask(:); n = numel(f);
assert(numel(observed)==n && numel(predicted)==n && numel(selected)==n && ...
    any(selected) && isequal(selected,result.residualInfo.objectiveMask(:)), ...
    'lamb:visualization:ObservationAlignment','Preserve the native fixed-mask row alignment.');
repetition = repmat("",n,1);
if isfield(provenance,'repetitionId')
    repetition = string(provenance.repetitionId(:));
    if numel(repetition)~=n || any(ismissing(repetition) | strlength(repetition)==0)
        error('lamb:visualization:InvalidRepetition','Provide one repetition identity per row.');
    end
end
residual = nan(n,1);
residual(selected) = result.residualInfo.rawResiduals_mps(:);
maximumFrequency = max(f(selected));
withinView = isfinite(f) & f>=0 & isfinite(observed);
displayRows = true(n,1);
if ~isempty(p.Results.DisplayObservationMask)
    validateattributes(p.Results.DisplayObservationMask,{'logical'},{'vector','numel',n});
    displayRows = p.Results.DisplayObservationMask(:);
end
shown = withinView & displayRows;
modelAvailable = isfinite(predicted);
observations = table((1:n)',repetition,f,observed,predicted,selected,modelAvailable, ...
    residual,displayRows,shown,shown & selected & isfinite(residual), ...
    'VariableNames',{'row','repetitionId','frequency_Hz','observedCp_mps', ...
    'predictedCp_mps','selected','modelAvailable','residual_mps', ...
    'sampledForDisplay','shownInDispersion','shownInResiduals'});
evidence = struct('observations',observations,'nativeParameters',result.allParams, ...
    'nativeMetrics',result.metrics,'provenance',provenance, ...
    'displayObservationMask',displayRows,'displayedSelectedCount',nnz(shown & selected), ...
    'unavailablePredictionCount',nnz(~modelAvailable));
evidence.nativeFitConfiguration = struct('branchName',string(result.branchName), ...
    'freeParams',result.freeParams,'lowerBounds',result.lowerBounds, ...
    'upperBounds',result.upperBounds,'fitOptions',result.problem.fitOptions, ...
    'optimizer',result.optimizer,'identifiability',result.identifiability);
fig = figure('Color','w','Units','centimeters','Position',[2 2 17.8 18.5], ...
    'Visible',p.Results.Visible,'Name',char(provenance.label),'UserData',evidence);
try
    layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','loose');
    dispersion = nexttile(layout,1,[1 2]); hold(dispersion,'on');
    summaryAxes = nexttile(layout,3); axis(summaryAxes,'off');
    residualAxes = nexttile(layout,4); hold(residualAxes,'on');
    labels = unique(repetition(selected),'stable');
    colors = [.16 .40 .68;.75 .37 .06;.48 .30 .64]; markers = {'o','s','d'};
    excluded = shown & ~selected;
    handles = gobjects(numel(labels)+1+any(excluded),1);
    legendLabels = strings(size(handles));
    for k=1:numel(labels)
        rows = selected & shown & repetition==labels(k); style = mod(k-1,3)+1;
        if ~any(rows), continue; end
        label = "Rep. "+labels(k);
        if labels(k)=="", label="Selected observations"; end
        handles(k) = plot(dispersion,f(rows)/1e3,observed(rows),'LineStyle','none', ...
            'Marker',markers{style},'MarkerSize',3.5,'Color',colors(style,:), ...
            'LineWidth',.5,'Tag','mrlfe_selected');
        legendLabels(k) = label;
        plot(residualAxes,f(rows)/1e3,residual(rows),'LineStyle','none', ...
            'Marker',markers{style},'MarkerSize',3.5,'Color',colors(style,:), ...
            'LineWidth',.5,'Tag','mrlfe_native_residual');
    end
    % The native axis is positive, finite and strictly ascending; no sorting.
    handles(numel(labels)+1) = plot(dispersion,f(modelAvailable)/1e3, ...
        predicted(modelAvailable),'k--','LineWidth',1.5,'Tag','mrlfe_native_prediction');
    legendLabels(numel(labels)+1) = "Model";
    if any(excluded)
        handles(end) = plot(dispersion,f(excluded)/1e3,observed(excluded),'x', ...
            'Color',[.8 .12 .12],'MarkerSize',4,'LineWidth',.5,'LineStyle','none', ...
            'Tag','mrlfe_excluded');
        legendLabels(end) = "Excluded";
    end
    [limits,scaleEvidence] = resolveInversePhaseSpeedLimits( ...
        [observed(withinView);predicted(modelAvailable)],'Mode',"complete");
    ylim(dispersion,limits);
    [residualLimits,residualScale] = resolveInversePhaseSpeedLimits(residual(selected), ...
        'Quantity',"speed_residual");
    ylim(residualAxes,residualLimits);
    yline(residualAxes,0,'k--','HandleVisibility','off','LineWidth',.6);
    ylabel(dispersion,'Phase speed [m/s]'); ylabel(residualAxes,'Model - observation [m/s]');
    xlabel(dispersion,'Frequency [kHz]'); xlabel(residualAxes,'Frequency [kHz]');
    xlim(dispersion,[0 1.03*max([maximumFrequency;f(withinView)])]/1e3);
    xlim(residualAxes,xlim(dispersion));
    outside = selected & isfinite(residual) & ...
        (residual<residualLimits(1) | residual>residualLimits(2));
    observations.residualOutsideView = outside;
    evidence.observations = observations;
    residualNote = strings(0,1);
    if residualScale.outsideCount>0
        residualNote = string(sprintf('Data outside: %d; [%.3g, %.3g] m/s', ...
            residualScale.outsideCount,residualScale.minimumOutside,residualScale.maximumOutside));
    end
    title(dispersion,'A. Dispersion','FontWeight','normal','FontSize',9);
    title(residualAxes,["C. Residuals";string(sprintf('RMSE = %.3f m/s',result.metrics.RMSE)); ...
        residualNote],'FontWeight','normal','FontSize',9);
    dispersion.Tag='mrlfe_dispersion'; summaryAxes.Tag='mrlfe_fit_summary';
    residualAxes.Tag='mrlfe_residuals';
    [estimatedCaption,physicalCaption] = parameterCaption(result);
    title(summaryAxes,'B. Native fit','FontWeight','normal','FontSize',9);
    method = "Unweighted phase-speed fit";
    if result.problem.fitOptions.useStandardErrorWeights
        method = "Standard-error weighted fit";
    end
    summary = {char(estimatedCaption);char(method); ...
        sprintf('Fitted observations: %d / %d',nnz(selected),n)};
    positions = .90-.11*(0:numel(summary)-1);
    for k=1:numel(summary)
        text(summaryAxes,.02,positions(k),summary{k},'Units','normalized', ...
            'Interpreter','tex','FontName','Arial','FontSize',9, ...
            'VerticalAlignment','top','Tag','mrlfe_native_fit_summary');
    end
    set([dispersion,summaryAxes,residualAxes],'FontName','Arial','FontSize',8, ...
        'LineWidth',.6,'Box','off','TickDir','out','XMinorGrid','off', ...
        'YMinorGrid','off','GridAlpha',.10);
    grid(dispersion,'on'); grid(residualAxes,'on');
    present = isgraphics(handles);
    sharedLegend = legend(dispersion,handles(present),cellstr(legendLabels(present)), ...
        'Orientation','horizontal','Box','off','Interpreter','none', ...
        'FontName','Arial','FontSize',8,'NumColumns',nnz(present));
    sharedLegend.Layout.Tile='south';
    branch = replace(string(result.branchName),["A0Like","S0Like"],["A_{0}-like","S_{0}-like"]);
    displayLabel = string(provenance.label)+" | mRLFE ("+branch+") inversion";
    if isfield(provenance,'displayLabel'), displayLabel=string(provenance.displayLabel); end
    subtitle = string(provenance.label);
    if isfield(provenance,'displaySubtitle'), subtitle=string(provenance.displaySubtitle); end
    title(layout,{char(displayLabel);char(subtitle)},'Interpreter','tex', ...
        'FontName','Arial','FontSize',9.5,'FontWeight','normal');
    notes = {char("Model assumption: "+string(provenance.modelAssumptionsJustification)), ...
        char(physicalCaption)};
    xlabel(layout,notes,'Interpreter','tex','FontName','Arial','FontSize',9,'FontWeight','normal');
    evidence.phaseSpeedScale = scaleEvidence;
    evidence.residualClipping = residualScale;
    evidence.residualLimits_mps = residualLimits;
    fig.UserData = evidence;
catch exception
    close(fig); rethrow(exception);
end
end

function [estimatedCaption,physicalCaption] = parameterCaption(result)
estimated = strings(numel(result.freeParams),1);
for k=1:numel(result.freeParams)
    name = string(result.freeParams(k)); value = result.bestParams.(name);
    switch name
        case "mu"
            estimated(k) = sprintf('\\mu = %.3f kPa',value/1e3);
        case "etaS"
            estimated(k) = sprintf('\\eta_{S} = %.6g Pa s',value);
        case "rho"
            estimated(k) = sprintf('\\rho = %.15g kg m^{-3}',value);
        case "nu"
            estimated(k) = sprintf('\\nu = %.6g',value);
        otherwise
            estimated(k) = sprintf('%s = %.6g (SI)',name,value);
    end
end
estimatedCaption = "Estimated "+join(estimated,"; ");
p = result.allParams;
physicalCaption = string(sprintf( ...
    '\\rho = %.15g kg m^{-3}; current thickness h = %.3f mm; \\nu = %.6g; \\eta_{S} = %.6g Pa s', ...
    p.rho,p.thickness*1e3,p.nu,p.etaS));
if isfield(p,'fluidDensity_kgm3') && isfield(p,'fluidSoundSpeed_mps')
    physicalCaption = physicalCaption + string(sprintf( ...
        '; fluid \\rho_{f} = %.15g kg m^{-3}, c_{f} = %.6g m s^{-1}', ...
        p.fluidDensity_kgm3,p.fluidSoundSpeed_mps));
end
end
