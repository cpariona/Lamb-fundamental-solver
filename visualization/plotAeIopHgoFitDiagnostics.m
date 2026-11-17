function [fig, evidence] = plotAeIopHgoFitDiagnostics(result, provenance, varargin)
%PLOTAEIOPHGOFITDIAGNOSTICS Present a stored native AE IOP/HGO atlasA0 inversion.
%   RESULT is the unchanged aeFitDispersionData output. PROVENANCE requires
%   label, material, sourceReference and modelAssumptionsJustification; optional
%   repetitionId has one identity per original row and displayLabel/
%   displaySubtitle are text only. DisplayObservationMask restricts glyphs
%   only (Pulse graphic sampling); it never changes the native fixed mask.
%   No fitting, forward evaluation, OCE input or physical acceptance occurs.
%   Predictions are the stored official atlasA0 values at the original rows.
%   Rows without a finite prediction stay in the evidence and are not drawn
%   as model points. All original rows remain in evidence.observations and
%   FIG.UserData. A small residual or a converged optimizer is a numerical
%   result, not validation of the biomechanical model or its assumptions.
p = inputParser;
addParameter(p,'DisplayObservationMask',[],@(v) isempty(v)||islogical(v));
addParameter(p,'Visible','on',@(x) any(string(x)==["on","off"]));
parse(p,varargin{:});
provenance = normalizeInverseProvenance(provenance);
if string(result.modelFamily) ~= "acoustoelastic_iop_hgo" || ...
        string(result.branchName) ~= "atlasA0"
    error('lamb:visualization:UnsupportedResult', ...
        'Use a native AE IOP/HGO atlasA0 fit.');
end
for name = ["label","material","sourceReference","modelAssumptionsJustification"]
    value = string(provenance.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value))==0
        error('lamb:visualization:MissingProvenance', 'Nonempty %s is required.', name);
    end
end
f = result.frequency_Hz(:); observed = result.Cp_exp_mps(:);
predicted = result.Cp_fit_mps(:); selected = result.validMask(:); n = numel(f);
assert(numel(observed)==n && numel(predicted)==n && numel(selected)==n && ...
    any(selected) && isequal(selected,result.residualInfo.objectiveMask(:)), ...
    'lamb:visualization:ObservationAlignment', 'Preserve the native fixed-mask row alignment.');
repetition = repmat("",n,1);
if isfield(provenance,'repetitionId')
    repetition = string(provenance.repetitionId(:));
    if numel(repetition)~=n || any(ismissing(repetition) | strlength(repetition)==0)
        error('lamb:visualization:InvalidRepetition', 'Provide one repetition identity per row.');
    end
end
residual = nan(n,1);
residual(selected) = result.residualInfo.rawResiduals_mps(:);
displayRows = true(n,1);
if ~isempty(p.Results.DisplayObservationMask)
    validateattributes(p.Results.DisplayObservationMask,{'logical'},{'vector','numel',n});
    displayRows = p.Results.DisplayObservationMask(:);
end
withinView = isfinite(f) & f>0 & isfinite(observed);
shown = withinView & displayRows;
modelAvailable = isfinite(predicted);
observations = table((1:n)',repetition,f,observed,predicted,selected,modelAvailable, ...
    residual,displayRows,shown,'VariableNames',{'row','repetitionId','frequency_Hz', ...
    'observedCp_mps','predictedCp_mps','selected','modelAvailable', ...
    'residual_mps','sampledForDisplay','shownInDispersion'});
observations.shownInResiduals = shown & selected & isfinite(residual);
evidence = struct('observations',observations,'nativeParameters',result.allParams, ...
    'nativeMetrics',result.metrics,'provenance',provenance, ...
    'coverageAccepted',result.residualInfo.coverageAccepted, ...
    'displayObservationMask',displayRows, ...
    'displayedSelectedCount',nnz(shown & selected), ...
    'excludedNotShownCount',nnz(~selected & ~shown), ...
    'unavailablePredictionCount',nnz(~modelAvailable));
evidence.nativeFitConfiguration = struct('freeParams',result.freeParams, ...
    'lowerBounds',result.lowerBounds,'upperBounds',result.upperBounds, ...
    'fitOptions',result.problem.fitOptions,'solverOptions',result.problem.solverOptions, ...
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
        handles(k) = plot(dispersion,f(rows)/1e3,observed(rows), ...
            'LineStyle','none','Marker',markers{style},'MarkerSize',3.5, ...
            'Color',colors(style,:),'LineWidth',.5,'Tag','ae_selected');
        legendLabels(k) = label;
        plot(residualAxes,f(rows)/1e3,residual(rows),'LineStyle','none', ...
            'Marker',markers{style},'MarkerSize',3.5,'Color',colors(style,:), ...
            'LineWidth',.5,'Tag','ae_native_residual');
    end
    % One scalar current thickness: the stored atlasA0 curve is one function
    % of Hz, so only duplicate frequencies (repetitions) are collapsed here.
    modelRows = find(f>0 & modelAvailable);
    [modelHz,index] = unique(f(modelRows),'sorted');
    modelCp = predicted(modelRows(index));
    handles(numel(labels)+1) = plot(dispersion,modelHz/1e3,modelCp,'k--', ...
        'LineWidth',1.5,'Tag','ae_native_prediction');
    legendLabels(numel(labels)+1) = "Model (atlasA0)";
    if any(excluded)
        handles(end) = plot(dispersion,f(excluded)/1e3,observed(excluded), ...
            'x','Color',[.8 .12 .12],'MarkerSize',4,'LineWidth',.5, ...
            'LineStyle','none','Tag','ae_excluded');
        legendLabels(end) = "Excluded";
    end
    [limits,scaleEvidence] = resolveInversePhaseSpeedLimits( ...
        [observed(withinView);modelCp],'Mode',"complete");
    ylim(dispersion,limits);
    [residualLimits,residualScale] = resolveInversePhaseSpeedLimits(residual(selected), ...
        'Quantity',"speed_residual");
    outside = selected & isfinite(residual) & ...
        (residual<residualLimits(1) | residual>residualLimits(2));
    observations.residualOutsideView = outside;
    evidence.observations = observations;
    residualScale.originalRows = find(outside);
    evidence.residualClipping = residualScale;
    ylim(residualAxes,residualLimits);
    yline(residualAxes,0,'k--','HandleVisibility','off','LineWidth',.6);
    ylabel(dispersion,'Phase speed [m/s]'); ylabel(residualAxes,'Model - observation [m/s]');
    xlabel(dispersion,'Frequency [kHz]'); xlabel(residualAxes,'Frequency [kHz]');
    xlim(dispersion,[0 1.03*max(f(withinView))]/1e3);
    xlim(residualAxes,xlim(dispersion));
    outsideNote = strings(0,1);
    if residualScale.outsideCount>0
        outsideNote = string(sprintf('Data outside: %d; [%.3g, %.3g] m/s', ...
            residualScale.outsideCount,residualScale.minimumOutside,residualScale.maximumOutside));
    end
    title(dispersion,'A. Dispersion','FontWeight','normal','FontSize',9);
    title(residualAxes,["C. Residuals";string(sprintf('RMSE = %.3f m/s',result.metrics.RMSE));outsideNote], ...
        'FontWeight','normal','FontSize',9);
    dispersion.Tag='ae_dispersion'; summaryAxes.Tag='ae_fit_summary'; residualAxes.Tag='ae_residuals';
    title(summaryAxes,'B. Native fit','FontWeight','normal','FontSize',9);
    summary = {char(estimatedCaption(result));char(optimizerCaption(result)); ...
        sprintf('Fitted observations: %d / %d',nnz(selected),n)};
    positions = .90-.11*(0:numel(summary)-1);
    for k=1:numel(summary)
        text(summaryAxes,.02,positions(k),summary{k},'Units','normalized', ...
            'Interpreter','tex','FontName','Arial','FontSize',9, ...
            'VerticalAlignment','top','Tag','ae_native_fit_summary');
    end
    set([dispersion,summaryAxes,residualAxes],'FontName','Arial','FontSize',8, ...
        'LineWidth',.6,'Box','off','TickDir','out','XMinorGrid','off', ...
        'YMinorGrid','off','GridAlpha',.10);
    set([dispersion.Title,summaryAxes.Title,residualAxes.Title],'FontSize',9);
    grid(dispersion,'on'); grid(residualAxes,'on');
    present = isgraphics(handles);
    sharedLegend = legend(dispersion,handles(present),cellstr(legendLabels(present)), ...
        'Orientation','horizontal','Box','off','Interpreter','none', ...
        'FontName','Arial','FontSize',8,'NumColumns',nnz(present));
    sharedLegend.Layout.Tile='south';
    displayLabel = string(provenance.label)+" | AE IOP/HGO (atlasA0) inversion";
    if isfield(provenance,'displayLabel'), displayLabel=string(provenance.displayLabel); end
    subtitle = string(provenance.label);
    if isfield(provenance,'displaySubtitle'), subtitle=string(provenance.displaySubtitle); end
    title(layout,{char(displayLabel);char(subtitle)}, ...
        'Interpreter','tex','FontName','Arial','FontSize',9.5,'FontWeight','normal');
    notes = {char("Model assumption: "+string(provenance.modelAssumptionsJustification)), ...
        char(fixedCaption(result)), ...
        'Numerical fit only; it does not validate the biomechanical model or its assumptions.'};
    xlabel(layout,notes,'Interpreter','tex','FontName','Arial','FontSize',9,'FontWeight','normal');
    evidence.phaseSpeedScale = scaleEvidence;
    evidence.residualLimits_mps = residualLimits;
    fig.UserData = evidence;
catch exception
    close(fig); rethrow(exception);
end
end

function caption = estimatedCaption(result)
% Native symbols are model-owned; display units are SI (1 mmHg = 133.322 Pa as in AE defaults).
estimated = strings(numel(result.freeParams),1);
for k=1:numel(result.freeParams)
    name = string(result.freeParams(k)); value = result.bestParams.(name);
    switch name
        case "mu"
            estimated(k) = sprintf('\\mu = %.3f kPa',value/1e3);
        case "k1"
            estimated(k) = sprintf('k_{1} = %.3f kPa',value/1e3);
        case "k2"
            estimated(k) = sprintf('k_{2} = %.6g',value);
        case "IOP"
            estimated(k) = sprintf('IOP = %.6g Pa (%.2f mmHg)',value,value/133.322);
        otherwise
            estimated(k) = sprintf('%s = %.6g (SI)',name,value);
    end
end
caption = "Estimated "+join(estimated,"; ");
end

function caption = optimizerCaption(result)
caption = "Optimizer "+string(result.optimizer.name)+"; fixed-mask model coverage accepted: "+ ...
    string(logical(result.residualInfo.coverageAccepted));
end

function caption = fixedCaption(result)
p = result.allParams;
caption = sprintf(['R = %.4g mm; h = %.3f mm; \\rho = %.15g kg m^{-3}; ' ...
    '\\rho_{F} = %.15g kg m^{-3}; K_{F} = %.4g GPa'], ...
    p.R*1e3,p.thickness*1e3,p.rho,p.rhoF,p.fluidBulkModulus/1e9);
end
