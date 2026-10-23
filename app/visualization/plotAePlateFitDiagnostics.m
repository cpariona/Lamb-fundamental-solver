function [fig, evidence] = plotAePlateFitDiagnostics(result, provenance, varargin)
%PLOTAEPLATEFITDIAGNOSTICS Present an unchanged native Plate A0 inverse result.
%   RESULT is aePlateFitDispersion output, including rejected candidates.
%   PROVENANCE requires label, material, sourceReference, modelSupportReference.
%   Optional repetitionId is one text/numeric value per original observation;
%   sourceMasks has original logical valid_mask/interpolated_mask/extrapolated_mask.
%   These masks are evidence only and never replace result.validMask.
%   DisplayMode is complete or robust. PhaseSpeedLimits supplies shared m/s
%   limits. Visible is on/off. All original rows remain in FIG.UserData.
%   Excluded positive finite observations receive display-only etaSquared from
%   the canonical master curve. Native etaSquared/residuals are never replaced.
%   A supported candidate uses the canonical forward solver, even if rejected
%   by numerical coverage. Unsupported coefficients never produce a curve.
p = inputParser;
addParameter(p,'DisplayMode',"complete",@(x) any(string(x)==["complete","robust"]));
addParameter(p,'PhaseSpeedLimits',[],@isnumeric);
addParameter(p,'Visible','on',@(x) any(string(x)==["on","off"]));
parse(p,varargin{:});
if result.model~="acoustoelastic_prestressed_plate"
    error('lamb:visualization:UnsupportedResult','Use the native prestressed-plate result.');
end
for name=["label","material","sourceReference","modelSupportReference"]
    value=string(provenance.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value))==0
        error('lamb:visualization:MissingProvenance','Nonempty %s is required.',name);
    end
end
f=result.experimental.frequency_Hz(:); cp=result.experimental.Cp_mps(:);
included=result.validMask(:); n=numel(f);
ridgeInvalid=false(n,1); interpolated=false(n,1); extrapolated=false(n,1);
hasRidge=false;
if isfield(provenance,'sourceMasks')
    masks=provenance.sourceMasks;
    for name=["valid_mask","interpolated_mask","extrapolated_mask"]
        if isfield(masks,name)
            validateattributes(masks.(name),{'logical'},{'vector','numel',n});
        end
    end
    if isfield(masks,'valid_mask'), ridgeInvalid=~masks.valid_mask(:); hasRidge=true; end
    if isfield(masks,'interpolated_mask'), interpolated=masks.interpolated_mask(:); end
    if isfield(masks,'extrapolated_mask'), extrapolated=masks.extrapolated_mask(:); end
end
repetition=repmat("unspecified",n,1);
if isfield(provenance,'repetitionId')
    repetition=string(provenance.repetitionId(:));
    if numel(repetition)~=n || any(ismissing(repetition) | strlength(repetition)==0)
        error('lamb:visualization:InvalidRepetition','Provide one repetition identity per row.');
    end
end
finite=isfinite(f)&isfinite(cp);
positive=finite&f>0&cp>0;
etaDisplay=result.etaSquared(:);
excludedForEta=~included&positive;
q=(pi*result.physical.thickness_m)*(f(excludedForEta)./cp(excludedForEta));
indices=find(excludedForEta); indices=indices(isfinite(q)&q>0); q=q(isfinite(q)&q>0);
if ~isempty(q)
    curve=lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
    etaDisplay(indices)=curve.etaSquared;
end
forward=struct('frequency_Hz',zeros(0,1),'phaseVelocity_mps',zeros(0,1));
forwardStatus="unsupported candidate: no forward prediction";
if result.diagnostics.physicalCandidate
    physical=result.physical;
    physical.alpha_Pa=result.alpha_Pa; physical.gamma_Pa=result.gamma_Pa;
    frequencies=linspace(min(f(included)),max(f(included)),128)';
    forward=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(frequencies,physical);
    forwardStatus="supported candidate (numerical acceptance is reported separately)";
end
scaleValues=cp;
if isempty(p.Results.PhaseSpeedLimits) && string(p.Results.DisplayMode)=="complete"
    scaleValues=[cp;forward.phaseVelocity_mps];
end
[limits,displayEvidence]=resolveInversePhaseSpeedLimits(scaleValues, ...
    'Mode',p.Results.DisplayMode,'Limits',p.Results.PhaseSpeedLimits);
[~,observedClipping]=resolveInversePhaseSpeedLimits(cp,'Limits',limits);
[~,predictionClipping]=resolveInversePhaseSpeedLimits(forward.phaseVelocity_mps,'Limits',limits);
status="REJECTED"; if result.accepted, status="ACCEPTED"; end
reasons="none";
if ~isempty(result.reasons), reasons=join(string(result.reasons),', '); end
y=result.physical.density_kgpm3*cp.^2;
evidence=struct('nativeAccepted',result.accepted,'nativeReasons',result.reasons, ...
    'nativeDiagnostics',result.diagnostics, ...
    'provenance',provenance,'display',displayEvidence,'observedClipping',observedClipping, ...
    'predictionClipping',predictionClipping,'forwardStatus',forwardStatus,'forwardCurve',forward, ...
    'ridgeEvidenceAvailable',hasRidge,'nonvisibleCoordinateCount',nnz(~finite), ...
    'unsupportedFiniteCount',nnz(finite&~positive),'excludedCount',nnz(~included), ...
    'observations',table((1:n)',f,cp,included,repetition,result.etaSquared(:),etaDisplay, ...
        result.regressionResidual_Pa(:),ridgeInvalid,interpolated,extrapolated, ...
        'VariableNames',{'row','frequency_Hz','Cp_mps','included','repetitionId', ...
        'nativeEtaSquared','displayEtaSquared','nativeResidual_Pa','ridgeInvalid','interpolated','extrapolated'}));
fig=figure('Color','w','Position',[50 50 1400 950],'Visible',p.Results.Visible, ...
    'Name',char(string(provenance.label)),'UserData',evidence);
try
    layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
    ax=nexttile(layout,1,[1 2]); hold(ax,'on'); grid(ax,'on');
    plot(ax,f(~included&finite)/1e3,cp(~included&finite),'.','Color',[.65 .65 .65], ...
        'DisplayName','Excluded by fixed mask','Tag','excluded_observations');
    labels=unique(repetition(included),'stable'); colors=lines(numel(labels));
    for k=1:numel(labels)
        rows=included&finite&repetition==labels(k);
        plot(ax,f(rows)/1e3,cp(rows),'o','Color',colors(k,:),'MarkerSize',4, ...
            'DisplayName',char("Included; repetition "+labels(k)),'Tag','included_observations');
    end
    overlay(ax,f/1e3,cp,finite&ridgeInvalid,'x',[.25 .25 .25],'Original ridge invalid');
    overlay(ax,f/1e3,cp,finite&interpolated,'s',[.8 .45 0],'Original interpolated');
    overlay(ax,f/1e3,cp,finite&extrapolated,'^',[.6 .2 .6],'Original extrapolated');
    overlay(ax,f/1e3,cp,finite&~positive,'+',[.2 .2 .2],'Finite outside positive Hz/Cp support');
    if ~isempty(forward.frequency_Hz)
        plot(ax,forward.frequency_Hz/1e3,forward.phaseVelocity_mps,'k-','LineWidth',1.5, ...
            'DisplayName',char("Supported candidate A0; native "+status),'Tag','plate_forward');
    end
    ylim(ax,limits); xlabel(ax,'Observed frequency [kHz]'); ylabel(ax,'Phase speed [m/s]');
    ridgeCaption="unavailable";
    if hasRidge, ridgeCaption=string(nnz(ridgeInvalid)); end
    interpolationCaption="unavailable";extrapolationCaption="unavailable";
    if isfield(provenance,'sourceMasks') && isfield(provenance.sourceMasks,'interpolated_mask')
        interpolationCaption=string(nnz(interpolated));
    end
    if isfield(provenance,'sourceMasks') && isfield(provenance.sourceMasks,'extrapolated_mask')
        extrapolationCaption=string(nnz(extrapolated));
    end
    title(ax,{char("A. Dispersion | native "+status+" | "+reasons), ...
        sprintf('Excluded %d; nonfinite coordinates %d; unsupported finite %d; ridge-invalid %s; interp/extrap %s/%s', ...
        nnz(~included),nnz(~finite),nnz(finite&~positive),ridgeCaption,interpolationCaption,extrapolationCaption), ...
        sprintf('Outside Cp scale: observations %d (max %.5g m/s); prediction %d (max %.5g m/s). %s', ...
        observedClipping.outsideCount,observedClipping.maximumOutside_mps, ...
        predictionClipping.outsideCount,predictionClipping.maximumOutside_mps,displayEvidence.source)}, ...
        'Interpreter','none','FontSize',10);
    legend(ax,'Location','eastoutside','Interpreter','none'); ax.Tag='plate_dispersion';
    ax=nexttile(layout,3);hold(ax,'on');grid(ax,'on');
    visibleRegression=isfinite(etaDisplay)&isfinite(y);
    rows=~included&visibleRegression;
    plot(ax,etaDisplay(rows),y(rows),'.','Color',[.65 .65 .65], ...
        'DisplayName','Excluded; display-only master-curve eta^2','Tag','excluded_regression_display');
    for k=1:numel(labels)
        rows=included&visibleRegression&repetition==labels(k);
        plot(ax,etaDisplay(rows),y(rows),'o','Color',colors(k,:),'MarkerSize',4, ...
            'DisplayName',char("Native rows; repetition "+labels(k)),'Tag','native_regression_observations');
    end
    if result.diagnostics.designRank==2 && all(isfinite([result.alpha_Pa,result.gamma_Pa]))
        x=sort(result.etaSquared(included));
        label="Native Li line";
        if ~result.accepted, label="Unconstrained diagnostic line; REJECTED"; end
        plot(ax,x,result.alpha_Pa-result.gamma_Pa*x,'k-','DisplayName',char(label), ...
            'LineWidth',1.4,'Tag','native_regression_line');
    end
    xlabel(ax,'etaSquared');ylabel(ax,'rho Cp^2 [Pa]');
    ax.YAxis.Exponent=0;ax.YAxis.TickLabelFormat='%.3g';
    title(ax,{'B. Li unweighted regression',sprintf('alpha %.5g Pa; gamma %.5g Pa',result.alpha_Pa,result.gamma_Pa), ...
        sprintf('Excluded eta unavailable %d; nonfinite rho Cp^2 %d',nnz(~included&~isfinite(etaDisplay)),nnz(~isfinite(y)))},'FontSize',10);
    legend(ax,'Location','best','Interpreter','none'); ax.Tag='plate_regression';
    ax=nexttile(layout,4);hold(ax,'on');grid(ax,'on');
    for k=1:numel(labels)
        rows=included&isfinite(result.regressionResidual_Pa(:))&repetition==labels(k);
        plot(ax,find(rows),result.regressionResidual_Pa(rows),'o','Color',colors(k,:), ...
            'MarkerSize',4,'DisplayName',char("Native residual; repetition "+labels(k)),'Tag','native_residual');
    end
    yline(ax,0,'k--','HandleVisibility','off');
    xlabel(ax,'Original observation row');ylabel(ax,'Native fitted minus observed [Pa]');
    ax.YAxis.Exponent=0;ax.YAxis.TickLabelFormat='%.3g';
    d=result.diagnostics;
    grouping="exact observed Hz (legacy)";
    if isfield(d,'frequencyGroupingSource'),grouping=string(d.frequencyGroupingSource);end
    title(ax,{'C. Native residuals and identification', ...
        sprintf('Observations %d; native coverage groups %d; ranks %d / %d',d.observationCount,d.independentFrequencyCount,d.designRank,d.frequencyDesignRank), ...
        char("Grouping: "+grouping+"; statistical independence not established"), ...
        sprintf('Condition numbers %.4g / %.4g; group eta^2 span %.4g',d.conditionNumber,d.frequencyConditionNumber,d.etaSquaredSpan), ...
        sprintf('Native RMSE %.5g Pa; nonfinite selected residuals %d; excluded have none', ...
        result.regressionRMSE_Pa,nnz(included&~isfinite(result.regressionResidual_Pa(:))))},'FontSize',10);
    ax.Tag='plate_residuals';
    title(layout,{char(string(provenance.label)), ...
        sprintf('%s; rho %.6g kg/m^3; current full thickness %.6g mm',string(provenance.material),result.physical.density_kgpm3,result.physical.thickness_m*1e3), ...
        'Exploratory A0 working hypothesis. Native acceptance does not establish experimental model validity. Full review/source references in FIG.UserData.'}, ...
        'Interpreter','none','FontSize',12);
catch exception
    close(fig); rethrow(exception);
end
end

function overlay(ax,x,y,mask,marker,color,label)
if any(mask)
    plot(ax,x(mask),y(mask),marker,'Color',color,'MarkerSize',5, ...
        'LineStyle','none','DisplayName',label);
end
end
