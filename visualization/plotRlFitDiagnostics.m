function [fig, evidence] = plotRlFitDiagnostics(result, provenance, varargin)
%PLOTRLFITDIAGNOSTICS Present a stored native Rayleigh-Lamb A0/S0 inversion.
%   RESULT is the unchanged rlFitDispersionData output. PROVENANCE requires
%   label, material, sourceReference and modelSupportReference. Optional
%   repetitionId identifies every original row; displayLabel/displaySubtitle
%   are text only. DisplayFrequency_Hz uses the same exact stored-bin glyph
%   filter as Plate; the caller supplies reviewed original frequencies.
%   No OCE I/O, fitting, forward evaluation or physical acceptance is performed.
%   Dispersion and residuals share the fitted frequency domain. The middle
%   panel summarizes the native inverse; it is not a Plate regression.
%   All rows remain in evidence.observations and FIG.UserData.
%   Residuals are native raw m/s residuals, even for weighted fits. Only model
%   predictions are sorted/deduplicated for the line; observations stay separate.
%   ResidualLimits accepts an automatic/shared m/s range resolved by
%   resolveInversePhaseSpeedLimits with Quantity="speed_residual". Full-fit
%   clipping counts/extrema follow the metric in the title. Compact blue edge
%   indicators retain original row identities independently of graphic sampling.
p = inputParser;
addParameter(p,'DisplayFrequency_Hz',[],@(x) isnumeric(x)&&isreal(x)&& ...
    (isempty(x)||(isvector(x)&&all(isfinite(x))&&all(x>0))));
addParameter(p,'ResidualLimits',[],@isnumeric);
addParameter(p, 'Visible', 'on', @(x) any(string(x)==["on","off"]));
parse(p, varargin{:});
if string(result.modelFamily) ~= "rayleigh_lamb" || ...
        ~any(string(result.branchName)==["A0","S0"])
    error('lamb:visualization:UnsupportedResult', 'Use a native Rayleigh-Lamb A0/S0 fit.');
end
for name = ["label","material","sourceReference","modelSupportReference"]
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
maximumFrequency = max(f(selected));
inDomain = isfinite(f) & f>=0 & f<=maximumFrequency;
withinView = inDomain & isfinite(observed);
displayRows = true(n,1);
if ~isempty(p.Results.DisplayFrequency_Hz)
    % Same Plate contract: exact original Hz only, never nearest-valid repair.
    displayRows = ismember(f,p.Results.DisplayFrequency_Hz);
end
shown = withinView & displayRows;
modelAvailable = isfinite(predicted);
observations = table((1:n)',repetition,f,observed,predicted,selected,modelAvailable, ...
    residual,displayRows,shown,'VariableNames',{'row','repetitionId','frequency_Hz', ...
    'observedCp_mps','predictedCp_mps','selected','modelAvailable', ...
    'residual_mps','sampledForDisplay','shownInDispersion'});
observations.shownInResiduals = shown & selected & isfinite(residual);
evidence = struct('observations',observations,'nativeParameters',result.allParams, ...
    'nativeMetrics',result.metrics,'nativeDiagnostics',result.modelEvaluation.diagnostics, ...
    'provenance',provenance,'frequencyDomain_Hz',[0 maximumFrequency], ...
    'displayFrequency_Hz',p.Results.DisplayFrequency_Hz, ...
    'displayedSelectedCount',nnz(shown & selected), ...
    'excludedOutsideDomainCount',nnz(~selected & ~withinView), ...
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
            'Color',colors(style,:),'LineWidth',.5,'Tag','rl_selected');
        legendLabels(k) = label;
        plot(residualAxes,f(rows)/1e3,residual(rows),'LineStyle','none', ...
            'Marker',markers{style},'MarkerSize',3.5,'Color',colors(style,:), ...
            'LineWidth',.5,'Tag','rl_native_residual');
    end
    % A model line uses only existing native predictions, with NaN gaps intact.
    modelRows = find(inDomain & f>0);
    if isfield(result.problem.experimental,'observationThickness_m')
        % Include all native group predictions in the shared display scale.
        modelCp = predicted(modelRows);
        % With varying thickness, Cp is not one function of frequency.
        % Plot each exact thickness group separately, never connect unlike h.
        h = result.problem.experimental.observationThickness_m(:);
        groups = unique(h(modelRows),'stable');
        for j=1:numel(groups)
            rows = modelRows(h(modelRows)==groups(j));
            [modelHz,index] = unique(f(rows),'sorted');
            marker = 'none';
            if numel(modelHz)==1, marker='.'; end
            lineHandle = plot(dispersion,modelHz/1e3,predicted(rows(index)),'k--', ...
                'Marker',marker,'LineWidth',1.5,'Tag','rl_native_prediction');
            if j==1
                handles(numel(labels)+1) = lineHandle;
            else
                lineHandle.HandleVisibility = 'off';
            end
        end
    else
        [modelHz,index] = unique(f(modelRows),'sorted');
        modelCp = predicted(modelRows(index));
        handles(numel(labels)+1) = plot(dispersion,modelHz/1e3,modelCp,'k--', ...
            'LineWidth',1.5,'Tag','rl_native_prediction');
    end
    legendLabels(numel(labels)+1) = "Model";
    if any(excluded)
        handles(end) = plot(dispersion,f(excluded)/1e3,observed(excluded), ...
            'x','Color',[.8 .12 .12],'MarkerSize',4,'LineWidth',.5, ...
            'LineStyle','none','Tag','rl_excluded');
        legendLabels(end) = "Excluded";
    end
    [limits,scaleEvidence] = resolveInversePhaseSpeedLimits( ...
        [observed(withinView);modelCp],'Mode',"complete");
    ylim(dispersion,limits);
    % Same display-limit owner/policy as Plate, with native RL residual units.
    [residualLimits,residualScale] = resolveInversePhaseSpeedLimits(residual(selected), ...
        'Quantity',"speed_residual",'Limits',p.Results.ResidualLimits);
    outside = selected & isfinite(residual) & ...
        (residual<residualLimits(1) | residual>residualLimits(2));
    observations.residualOutsideView = outside;
    evidence.observations = observations;
    residualScale.originalRows = find(outside);
    evidence.residualClipping = residualScale;
    evidence.completeResidualLimits_mps = resolveInversePhaseSpeedLimits( ...
        residual(selected),'Quantity',"speed_residual");
    ylim(residualAxes,residualLimits);
    yline(residualAxes,0,'k--','HandleVisibility','off','LineWidth',.6);
    ylabel(dispersion,'Phase speed [m/s]'); ylabel(residualAxes,'Model - observation [m/s]');
    xlabel(dispersion,'Frequency [kHz]'); xlabel(residualAxes,'Frequency [kHz]');
    xlim(dispersion,[0 1.03*maximumFrequency]/1e3);
    xlim(residualAxes,xlim(dispersion));
    outsideNote=strings(0,1);
    if residualScale.outsideCount>0
        if residualScale.minimumOutside==residualScale.maximumOutside
            outsideNote=string(sprintf('Data outside: %d; %.4g m/s', ...
                residualScale.outsideCount,residualScale.minimumOutside));
        else
            outsideNote=string(sprintf('Data outside: %d; [%.3g, %.3g] m/s', ...
                residualScale.outsideCount,residualScale.minimumOutside,residualScale.maximumOutside));
        end
        % One extreme per boundary summarizes the full native population.
        % These indicators are not additional sampled observation glyphs.
        for side=[-1 1]
            rows=find(outside & side*residual>side*residualLimits((side+3)/2));
            if isempty(rows),continue;end
            [~,extreme]=max(side*residual(rows));glyphRow=rows(extreme);
            marker='^';if side<0,marker='v';end
            glyph=plot(residualAxes,f(glyphRow)/1e3,residualLimits((side+3)/2),marker, ...
                'Color',colors(1,:),'MarkerFaceColor',colors(1,:), ...
                'MarkerSize',5,'LineStyle','none','Clipping','off', ...
                'HandleVisibility','off','Tag','rl_offscale_residual');
            glyph.UserData=struct('originalIndices',rows,'displayedIndices',glyphRow, ...
                'originalXData',f(rows)/1e3,'originalYData',residual(rows),'unit',"m/s");
        end
    end
    title(dispersion,'A. Dispersion','FontWeight','normal','FontSize',9);
    title(residualAxes,["C. Residuals";string(sprintf('RMSE = %.3f m/s',result.metrics.RMSE));outsideNote], ...
        'FontWeight','normal','FontSize',9);
    dispersion.Tag='rl_dispersion'; summaryAxes.Tag='rl_fit_summary'; residualAxes.Tag='rl_residuals';
    [estimatedCaption,physicalCaption] = parameterCaption(result);
    title(summaryAxes,'B. Native fit','FontWeight','normal','FontSize',9);
    method = "Unweighted phase-speed fit";
    if result.problem.fitOptions.useStandardErrorWeights
        method = "Standard-error weighted fit";
    end
    summary = {char(estimatedCaption);char(method); ...
        sprintf('Fitted observations: %d / %d',nnz(selected),n)};
    muIndex=find(string(result.freeParams)=="mu",1);
    if ~isempty(muIndex)
        bounds=string(sprintf('Search bounds: \\mu \\in [%.6g, %.6g] kPa', ...
            result.lowerBounds(muIndex)/1e3,result.upperBounds(muIndex)/1e3));
        summary=[summary(1);{char(bounds)};summary(2:end)];
    end
    positions = .90-.11*(0:numel(summary)-1);
    for k=1:numel(summary)
        text(summaryAxes,.02,positions(k),summary{k},'Units','normalized', ...
            'Interpreter','tex','FontName','Arial','FontSize',9, ...
            'VerticalAlignment','top','Tag','rl_native_fit_summary');
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
    branch = replace(string(result.branchName),["A0","S0"],["A_{0}","S_{0}"]);
    displayLabel = string(provenance.label)+" | Rayleigh-Lamb ("+branch+") inversion";
    if isfield(provenance,'displayLabel'), displayLabel=string(provenance.displayLabel); end
    subtitle = string(provenance.label);
    if isfield(provenance,'displaySubtitle'), subtitle=string(provenance.displaySubtitle); end
    title(layout,{char(displayLabel);char(subtitle)}, ...
        'Interpreter','tex','FontName','Arial','FontSize',9.5,'FontWeight','normal');
    notes = {char("Physical support: "+string(provenance.modelSupportReference)), ...
        char(physicalCaption)};
    xlabel(layout,notes,'Interpreter','tex','FontName','Arial','FontSize',9,'FontWeight','normal');
    evidence.phaseSpeedScale = scaleEvidence;
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
        case {"mu","lambda"}
            estimated(k) = sprintf('\\%s = %.3f kPa',name,value/1e3);
        case "thickness"
            estimated(k) = sprintf('h = %.3f mm',value*1e3);
        case "rho"
            estimated(k) = sprintf('\\rho = %.15g kg m^{-3}',value);
        case "nu"
            estimated(k) = sprintf('\\nu = %.6g',value);
        otherwise
            estimated(k) = sprintf('%s = %.6g (SI)',name,value);
    end
end
estimatedCaption = "Estimated "+join(estimated,"; ");
if isfield(result.problem.experimental,'observationThickness_m')
    h = result.problem.experimental.observationThickness_m(result.validMask);
    physicalCaption = sprintf( ...
        '\\rho = %.15g kg m^{-3}; directional h = %.3f - %.3f mm (per observation); \\nu = %.6g', ...
        result.allParams.rho,min(h)*1e3,max(h)*1e3,result.modelEvaluation.material.nu);
else
    physicalCaption = sprintf( ...
        '\\rho = %.15g kg m^{-3}; current thickness h = %.3f mm; \\nu = %.6g', ...
        result.allParams.rho,result.allParams.thickness*1e3,result.modelEvaluation.material.nu);
end
end
