function [fig, evidence] = plotAePlateFitDiagnostics(result, provenance, varargin)
%PLOTAEPLATEFITDIAGNOSTICS Present an unchanged native Plate A0 inverse result.
%   RESULT is aePlateFitDispersion output, including rejected candidates.
%   A cell vector of independent repetition results uses matching provenance cells
%   and shared physical inputs/limits; coefficients and residuals stay per result.
%   DisplayFrequency_Hz optionally selects exact stored frequencies for glyphs
%   only. It never changes the native fitting mask, values or regression.
%   PROVENANCE requires label, material, sourceReference, modelAssumptionsJustification.
%   Optional repetitionId is one text/numeric value per original observation;
%   sourceMasks has original logical valid_mask/interpolated_mask/extrapolated_mask.
%   These masks are evidence only and never replace result.validMask.
%   DisplayMode is complete or robust. PhaseSpeedLimits supplies shared m/s
%   limits; RegressionLimits and ResidualLimits supply shared Pa limits.
%   Visible is on/off. All original rows remain in FIG.UserData.
%   Excluded positive finite observations receive display-only etaSquared from
%   the canonical master curve. Native etaSquared/residuals are never replaced.
%   A supported candidate uses the canonical forward solver, even if rejected
%   by numerical coverage. With recorded per-observation thickness, the
%   forward display retains separate exact-thickness groups (no pooled curve).
%   Unsupported coefficients never produce a curve.
p = inputParser;
addParameter(p,'DisplayMode',"complete",@(x) any(string(x)==["complete","robust"]));
addParameter(p,'PhaseSpeedLimits',[],@isnumeric);
addParameter(p,'RegressionLimits',[],@isnumeric);
addParameter(p,'ResidualLimits',[],@isnumeric);
addParameter(p,'DisplayFrequency_Hz',[],@(x) isnumeric(x)&&isreal(x)&& ...
    (isempty(x)||(isvector(x)&&all(isfinite(x))&&all(x>0))));
addParameter(p,'Visible','on',@(x) any(string(x)==["on","off"]));
parse(p,varargin{:});
if iscell(result)
    assert(iscell(provenance)&&numel(result)==numel(provenance), ...
        'lamb:visualization:RepetitionProvenance','Provide provenance for every native result.');
    for k=2:numel(result)
        assert(isequaln(result{k}.physical,result{1}.physical), ...
            'lamb:visualization:PhysicalInputs','This repetition view requires shared physical inputs.');
    end
    % Keep the legacy independent-fit view, with one reviewed scale per panel.
    % The scalar joint-fit path below is unchanged.
    shared=p.Results;populations=cell(numel(result),3);
    for k=1:numel(result)
        r=result{k};cp=r.experimental.Cp_mps(:);mask=r.validMask(:);
        populations(k,:)={cp,r.physical.density_kgpm3*cp.^2,r.regressionResidual_Pa(:)};
        if string(shared.DisplayMode)=="robust"
            for panel=1:3,populations{k,panel}=populations{k,panel}(mask);end
        else
            if isempty(shared.PhaseSpeedLimits)&&r.diagnostics.physicalCandidate
                physical=r.physical;physical.alpha_Pa=r.alpha_Pa;physical.gamma_Pa=r.gamma_Pa;
                f=r.experimental.frequency_Hz(:);
                if isfield(r.experimental,'observationThickness_m')
                    h=r.experimental.observationThickness_m(:);
                    groups=unique(h(mask),'stable');
                    for g=1:numel(groups)
                        hz=unique(f(mask&h==groups(g)),'sorted');
                        if numel(hz)>1,hz=linspace(min(hz),max(hz),128)';end
                        physical.thickness_m=groups(g);
                        forward=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(hz,physical);
                        populations{k,1}=[populations{k,1};forward.phaseVelocity_mps];
                    end
                else
                    forward=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion( ...
                        linspace(min(f(mask)),max(f(mask)),128)',physical);
                    populations{k,1}=[populations{k,1};forward.phaseVelocity_mps];
                end
            end
            if r.diagnostics.designRank==2&&all(isfinite([r.alpha_Pa,r.gamma_Pa]))
                populations{k,2}=[populations{k,2};r.alpha_Pa-r.gamma_Pa*r.etaSquared(mask)];
            end
        end
    end
    limitNames=["PhaseSpeedLimits","RegressionLimits","ResidualLimits"];
    quantities=["phase_speed","regression","residual"];
    for panel=1:3
        if isempty(shared.(limitNames(panel)))
            shared.(limitNames(panel))=resolveInversePhaseSpeedLimits(populations(:,panel), ...
                'Mode',shared.DisplayMode,'Quantity',quantities(panel));
        end
    end
    options=namedargs2cell(shared);repetitionEvidence=cell(size(result));
    outsideNotes={strings(0,1);strings(0,1);strings(0,1)};
    colors=[.16 .40 .68;.75 .37 .06;.48 .30 .64];markers={'o','s','d'};
    tags={'plate_dispersion','plate_regression','plate_residuals'};
    [fig,repetitionEvidence{1}]=plotAePlateFitDiagnostics(result{1},provenance{1},options{:});
    repHandles=gobjects(numel(result),1);hasModel=false;
    alpha=strings(numel(result),1);rmse=alpha;support=alpha;
    try
        for k=1:numel(result)
            if k==1
                source=fig;
            else
                [source,repetitionEvidence{k}]=plotAePlateFitDiagnostics(result{k},provenance{k},options{:});
            end
            style=mod(k-1,3)+1;
            for panel=1:3
                from=findall(source,'Tag',tags{panel});to=findall(fig,'Tag',tags{panel});
                notes=string(from.Title.String);notes=notes(contains(notes,"outside:"));
                outsideNotes{panel}=[outsideNotes{panel}; ...
                    "Rep. "+string(provenance{k}.repetitionId(1))+": "+notes(:)];
                objects=findall(from,'Type','line');
                for j=1:numel(objects)
                    h=objects(j);tag=string(h.Tag);
                    if ~any(tag==["included_observations","native_regression_observations", ...
                            "native_regression_line","native_residual","plate_forward"])&&~startsWith(tag,"offscale_")
                        continue
                    end
                    if k>1,h=copyobj(h,to);end
                    h.Color=colors(style,:);
                    if any(tag==["included_observations","native_regression_observations","native_residual"])
                        h.Marker=markers{style};h.MarkerSize=4;
                    end
                    if tag=="included_observations",repHandles(k)=h;end
                    if tag=="plate_forward"
                        h.LineStyle='--';h.HandleVisibility='off';hasModel=true;
                    end
                end
            end
            alpha(k)=sprintf('Rep. %s: %.3g / %.3g', ...
                string(provenance{k}.repetitionId(1)),result{k}.alpha_Pa/1e3,result{k}.gamma_Pa/1e3);
            rmse(k)=sprintf('Rep. %s: %.3g',string(provenance{k}.repetitionId(1)),result{k}.regressionRMSE_Pa);
            support(k)=physicalSupport(result{k});
            if k>1,close(source);end
        end
        ax=findall(fig,'Tag','plate_dispersion');
        legendNames=arrayfun(@(k)"Rep. "+string(provenance{k}.repetitionId(1)),1:numel(result))';
        if hasModel
            repHandles(end+1)=plot(ax,NaN,NaN,'k--','DisplayName','Model','LineWidth',1.5);
            legendNames(end+1)="Model";
        end
        legendObject=legend(ax,repHandles,cellstr(legendNames),'Orientation','horizontal', ...
            'Interpreter','none','Box','off','FontSize',8,'NumColumns',4);
        legendObject.Layout.Tile='south';
        title(ax,["A. Dispersion";outsideNotes{1}],'FontSize',9,'FontWeight','normal');
        title(findall(fig,'Tag','plate_regression'),["B. Regression";"\alpha / \gamma [kPa]";alpha;outsideNotes{2}], ...
            'FontSize',9,'FontWeight','normal');
        title(findall(fig,'Tag','plate_residuals'),["C. Residuals";"RMSE [Pa]";rmse;outsideNotes{3}], ...
            'FontSize',9,'FontWeight','normal');
        layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
        if all(cellfun(@(r)r.diagnostics.physicalCandidate,result))
            statement="Physical support: \alpha \geq \gamma > 0 (all repetitions).";
        else
            violations=replace(support,["alpha","gamma",">=","<="],["\alpha","\gamma","\geq","\leq"]);
            statement="Physical support: "+join(legendNames(1:numel(result))+": "+violations,"; ");
        end
        geometryCaption=sprintf('\\rho = %.15g kg m^{-3}; current thickness h = %.3f mm', ...
            result{1}.physical.density_kgpm3,result{1}.physical.thickness_m*1e3);
        if all(cellfun(@(r)isfield(r.experimental,'observationThickness_m'),result))
            h=cell2mat(cellfun(@(r)r.experimental.observationThickness_m(r.validMask), ...
                result,'UniformOutput',false));
            geometryCaption=sprintf('\\rho = %.15g kg m^{-3}; directional h = %.3f - %.3f mm (per observation)', ...
                result{1}.physical.density_kgpm3,min(h)*1e3,max(h)*1e3);
        end
        layout.XLabel.String={char(statement),geometryCaption};
        layout.XLabel.Interpreter='tex';layout.XLabel.FontSize=9;
        countNote=findall(fig,'Tag','plate_observation_count');
        countNote.String=sprintf('Fitted observations: %d / %d', ...
            sum(cellfun(@(r)nnz(r.validMask),result)), ...
            sum(cellfun(@(r)numel(r.validMask),result)));
        evidence=struct('nativeResults',{result},'repetitionEvidence',{repetitionEvidence}, ...
            'displayFrequency_Hz',p.Results.DisplayFrequency_Hz, ...
            'sharedPanelLimits',struct('phaseSpeed_mps',shared.PhaseSpeedLimits, ...
            'regression_Pa',shared.RegressionLimits,'residual_Pa',shared.ResidualLimits));
        fig.UserData=evidence;
    catch exception
        close(fig);rethrow(exception);
    end
    return
end
if result.model~="acoustoelastic_prestressed_plate"
    error('lamb:visualization:UnsupportedResult','Use the native prestressed-plate result.');
end
for name=["label","material","sourceReference","modelAssumptionsJustification"]
    value=string(provenance.(name));
    if ~isscalar(value) || ismissing(value) || strlength(strtrim(value))==0
        error('lamb:visualization:MissingProvenance','Nonempty %s is required.',name);
    end
end
f=result.experimental.frequency_Hz(:); cp=result.experimental.Cp_mps(:);
included=result.validMask(:); n=numel(f);
displayRows=true(n,1);
if ~isempty(p.Results.DisplayFrequency_Hz)
    % Exact saved bins only: missing/excluded bins are never replaced.
    displayRows=ismember(f,p.Results.DisplayFrequency_Hz);
end
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
rowThickness=repmat(result.physical.thickness_m,n,1);
byObservation=isfield(result.experimental,'observationThickness_m');
if byObservation
    rowThickness=result.experimental.observationThickness_m(:);
end
excludedForEta=~included&positive&isfinite(rowThickness)&rowThickness>0;
q=pi*rowThickness(excludedForEta).*f(excludedForEta)./cp(excludedForEta);
indices=find(excludedForEta);indices=indices(isfinite(q)&q>0);q=q(isfinite(q)&q>0);
if ~isempty(q)
    curve=lamb.models.acoustoelastic_prestressed_plate.aePlateA0MasterCurve(q);
    etaDisplay(indices)=curve.etaSquared;
end
forward=struct('frequency_Hz',zeros(0,1),'phaseVelocity_mps',zeros(0,1));
forwardByThickness=struct('thickness_m',{},'sourceRows',{},'mode',{});
forwardStatus="unsupported candidate: no forward prediction";
if result.diagnostics.physicalCandidate
    physical=result.physical;
    physical.alpha_Pa=result.alpha_Pa;physical.gamma_Pa=result.gamma_Pa;
    if byObservation
        % One native geometry per exact measured thickness. Single-frequency
        % groups are single model markers, never artificial dispersion lines.
        groupThickness=unique(rowThickness(included),'stable');
        for groupIndex=1:numel(groupThickness)
            rows=find(included&rowThickness==groupThickness(groupIndex));
            frequencies=unique(f(rows),'sorted');
            if numel(frequencies)>1
                frequencies=linspace(min(frequencies),max(frequencies),128)';
            end
            physical.thickness_m=groupThickness(groupIndex);
            mode=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion( ...
                frequencies,physical);
            forwardByThickness(groupIndex)=struct('thickness_m',groupThickness(groupIndex), ...
                'sourceRows',rows,'mode',mode);
            forward.frequency_Hz=[forward.frequency_Hz;mode.frequency_Hz];
            forward.phaseVelocity_mps=[forward.phaseVelocity_mps;mode.phaseVelocity_mps];
        end
        forwardStatus="supported candidate; exact-thickness model groups (numerical acceptance separate)";
    else
        frequencies=linspace(min(f(included)),max(f(included)),128)';
        forward=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(frequencies,physical);
        forwardStatus="supported candidate (numerical acceptance is reported separately)";
    end
end
scaleValues=cp;
if string(p.Results.DisplayMode)=="robust",scaleValues=cp(included);end
if isempty(p.Results.PhaseSpeedLimits) && string(p.Results.DisplayMode)=="complete"
    scaleValues=[cp;forward.phaseVelocity_mps];
end
[limits,displayEvidence]=resolveInversePhaseSpeedLimits(scaleValues, ...
    'Mode',p.Results.DisplayMode,'Limits',p.Results.PhaseSpeedLimits);
[~,observedClipping]=resolveInversePhaseSpeedLimits(cp,'Limits',limits);
[~,predictionClipping]=resolveInversePhaseSpeedLimits(forward.phaseVelocity_mps,'Limits',limits);
y=result.physical.density_kgpm3*cp.^2;
evidence=struct('nativeAccepted',result.accepted,'nativeReasons',result.reasons, ...
    'nativeDiagnostics',result.diagnostics, ...
    'provenance',provenance,'display',displayEvidence,'observedClipping',observedClipping, ...
    'predictionClipping',predictionClipping,'forwardStatus',forwardStatus,'forwardCurve',forward, ...
    'forwardByThickness',{forwardByThickness}, ...
    'ridgeEvidenceAvailable',hasRidge,'nonvisibleCoordinateCount',nnz(~finite), ...
    'unsupportedFiniteCount',nnz(finite&~positive),'excludedCount',nnz(~included), ...
    'observations',table((1:n)',f,cp,included,repetition,result.etaSquared(:),etaDisplay, ...
        result.regressionResidual_Pa(:),ridgeInvalid,interpolated,extrapolated, ...
        'VariableNames',{'row','frequency_Hz','Cp_mps','included','repetitionId', ...
        'nativeEtaSquared','displayEtaSquared','nativeResidual_Pa','ridgeInvalid','interpolated','extrapolated'}));
% Each panel resolves its own units. Display screens never change fitting rows.
fitX=zeros(0,1);fitY=fitX;
solvable=result.diagnostics.designRank==2 && all(isfinite([result.alpha_Pa,result.gamma_Pa]));
if solvable
    fitX=sort(result.etaSquared(included));fitY=result.alpha_Pa-result.gamma_Pa*fitX;
end
[regressionLimits,regressionDisplay]=resolveInversePhaseSpeedLimits(y(included), ...
    'Mode',p.Results.DisplayMode,'Quantity',"regression",'Limits',p.Results.RegressionLimits);
[residualLimits,residualDisplay]=resolveInversePhaseSpeedLimits(result.regressionResidual_Pa(included), ...
    'Mode',p.Results.DisplayMode,'Quantity',"residual",'Limits',p.Results.ResidualLimits);
if string(p.Results.DisplayMode)=="complete" && isempty(p.Results.RegressionLimits)
    [regressionLimits,regressionDisplay]=resolveInversePhaseSpeedLimits([y;fitY],'Quantity',"regression");
end
evidence.regressionDisplay=regressionDisplay;evidence.residualDisplay=residualDisplay;
if ~isempty(p.Results.DisplayFrequency_Hz)
    evidence.displayFrequency_Hz=p.Results.DisplayFrequency_Hz(:);
    evidence.displayedObservationMask=included&displayRows;
end
evidence.completePanelLimits=struct('phaseSpeed_mps',resolveInversePhaseSpeedLimits([cp;forward.phaseVelocity_mps]), ...
    'regression_Pa',resolveInversePhaseSpeedLimits([y;fitY],'Quantity',"regression"), ...
    'residual_Pa',resolveInversePhaseSpeedLimits(result.regressionResidual_Pa,'Quantity',"residual"));
evidence.nativeParameters=struct('alpha_Pa',result.alpha_Pa,'gamma_Pa',result.gamma_Pa,'physical',result.physical);
evidence.sourceAvailability=struct('ridge',hasRidge,'interpolated',false,'extrapolated',false);
if isfield(provenance,'sourceMasks')
    evidence.sourceAvailability.interpolated=isfield(provenance.sourceMasks,'interpolated_mask');
    evidence.sourceAvailability.extrapolated=isfield(provenance.sourceMasks,'extrapolated_mask');
end
displayLabel=string(provenance.label);displaySubtitle="AE Plate inversion | A0 working hypothesis";
if isfield(provenance,'displayLabel'),displayLabel=string(provenance.displayLabel);end
if isfield(provenance,'displaySubtitle'),displaySubtitle=string(provenance.displaySubtitle);end
physicalStatement="Physical support: "+physicalSupport(result);
regressionStatement="Regression not solvable";
if solvable,regressionStatement="Regression solvable";end
displayLabel=replace(displayLabel,"AE Plate inversion","Prestressed plate (A_{0}) inversion");
evidence.presentation=struct('regressionStatement',regressionStatement,'physicalStatement',physicalStatement);
fig=figure('Color','w','Units','centimeters','Position',[2 2 17.8 18.5], ...
    'Visible',p.Results.Visible,'Name',char(displayLabel),'UserData',evidence);
try
    layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','loose');
    ax=nexttile(layout,1,[1 2]);hold(ax,'on');
    extensions=interpolated|extrapolated;
    showExtensions=string(p.Results.DisplayMode)=="complete";
    rows=~included&finite&~extensions&displayRows;
    if any(rows)
        plot(ax,f(rows)/1e3,cp(rows),'x','Color',[.8 .12 .12],'MarkerSize',4, ...
            'LineStyle','none','DisplayName','Excluded from fit','Tag','excluded_observations');
    end
    % Flagged extensions remain full arrays in FIG, never a connected curve.
    extensionGlyphs(ax,f/1e3,cp,finite&extensions,showExtensions,'excluded_extensions');
    labels=unique(repetition(included),'stable');
    colors=[.16 .40 .68;.75 .37 .06;.48 .30 .64];markers={'o','s','d'};
    for k=1:numel(labels)
        rows=included&finite&displayRows&repetition==labels(k);style=mod(k-1,3)+1;
        plotRows(ax,f(rows)/1e3,cp(rows),markers{style},colors(style,:), ...
            "Rep. "+labels(k),'included_observations');
    end
    if ~isempty(forward.frequency_Hz)
        if byObservation
            for j=1:numel(forwardByThickness)
                one=forwardByThickness(j).mode;
                marker='none';
                if numel(one.frequency_Hz)==1,marker='.';end
                lineHandle=plot(ax,one.frequency_Hz/1e3,one.phaseVelocity_mps, ...
                    'k--','LineWidth',1.5,'Marker',marker, ...
                    'DisplayName','Model','Tag','plate_forward');
                if j>1,lineHandle.HandleVisibility='off';end
            end
        else
            plot(ax,forward.frequency_Hz/1e3,forward.phaseVelocity_mps,'k--', ...
                'LineWidth',1.5,'DisplayName','Model','Tag','plate_forward');
        end
    end
    ylim(ax,limits);xlabel(ax,'Frequency [kHz]');ylabel(ax,'Phase speed [m/s]');
    if ~showExtensions
        visibleHz=f(finite&~extensions);
        if ~isempty(visibleHz)&&min(visibleHz)<max(visibleHz)
            padding=.03*(max(visibleHz)-min(visibleHz));
            xlim(ax,[max(0,min(visibleHz)-padding),max(visibleHz)+padding]/1e3);
        end
    end
    outsideA=[markOutside(ax,f/1e3,cp,included&finite&displayRows,limits,"m/s","selected speed",colors(1,:)); ...
        markOutside(ax,f/1e3,cp,~included&finite&(~extensions|showExtensions),limits,"m/s","excluded speed",[.8 .12 .12]); ...
        markOutside(ax,forward.frequency_Hz/1e3,forward.phaseVelocity_mps, ...
        true(size(forward.frequency_Hz)),limits,"m/s","model prediction",[.1 .1 .1])];
    title(ax,["A. Dispersion";outsideA],'FontSize',9,'FontWeight','normal');
    sharedLegend=legend(ax,'Orientation','horizontal','Interpreter','none', ...
        'Box','off','FontName','Arial','FontSize',8,'NumColumns',4);
    sharedLegend.Layout.Tile='south';ax.Tag='plate_dispersion';

    ax=nexttile(layout,3);hold(ax,'on');
    visibleRegression=isfinite(etaDisplay)&isfinite(y);
    rows=~included&visibleRegression&~extensions&displayRows;
    if any(rows)
        plot(ax,etaDisplay(rows),y(rows),'x','Color',[.8 .12 .12], ...
            'MarkerSize',4,'LineStyle','none','Tag','excluded_regression_display');
    end
    extensionGlyphs(ax,etaDisplay,y,visibleRegression&extensions,showExtensions,'excluded_regression_extensions');
    for k=1:numel(labels)
        rows=included&visibleRegression&displayRows&repetition==labels(k);style=mod(k-1,3)+1;
        plotRows(ax,etaDisplay(rows),y(rows),markers{style},colors(style,:), ...
            "Rep. "+labels(k),'native_regression_observations');
    end
    if solvable
        plot(ax,fitX,fitY,'Color',[0 0 0],'LineStyle','--','LineWidth',1.2, ...
            'Tag','native_regression_line');
    end
    ylim(ax,regressionLimits);
    if ~showExtensions
        eta=etaDisplay(included&visibleRegression);
        if ~isempty(eta)&&min(eta)<max(eta)
            padding=.03*(max(eta)-min(eta));xlim(ax,[min(eta)-padding,max(eta)+padding]);
        end
    end
    xlabel(ax,'\eta^2');ylabel(ax,'\rho c_p^2 [Pa]');
    outsideB=[markOutside(ax,etaDisplay,y,included&visibleRegression&displayRows,regressionLimits,"Pa","selected observation",colors(1,:)); ...
        markOutside(ax,etaDisplay,y,~included&visibleRegression&(~extensions|showExtensions),regressionLimits,"Pa","excluded observation",[.8 .12 .12])];
    coefficientUnit="kPa";divisor=1e3;
    if max(abs([result.alpha_Pa,result.gamma_Pa]))>=1e6,coefficientUnit="MPa";divisor=1e6;end
    coefficients=string(sprintf('\\alpha = %.3g; \\gamma = %.3g [%s]', ...
        result.alpha_Pa/divisor,result.gamma_Pa/divisor,coefficientUnit));
    title(ax,["B. Regression";coefficients;outsideB], ...
        'FontSize',9,'FontWeight','normal');ax.Tag='plate_regression';

    ax=nexttile(layout,4);hold(ax,'on');
    residual=result.regressionResidual_Pa(:);
    for k=1:numel(labels)
        rows=included&isfinite(residual)&displayRows&repetition==labels(k);style=mod(k-1,3)+1;
        plotRows(ax,f(rows)/1e3,residual(rows),markers{style},colors(style,:), ...
            "Rep. "+labels(k),'native_residual');
    end
    yline(ax,0,'k--','HandleVisibility','off','LineWidth',.6);
    ylim(ax,residualLimits);
    xlabel(ax,'Frequency [kHz]');ylabel(ax,'Fitted minus observed [Pa]');
    outsideC=markOutside(ax,f/1e3,residual,included&isfinite(residual)&displayRows,residualLimits,"Pa","selected residual",colors(1,:));
    title(ax,["C. Residuals";string(sprintf('RMSE = %.3g Pa',result.regressionRMSE_Pa));outsideC], ...
        'FontSize',9,'FontWeight','normal');ax.Tag='plate_residuals';

    support="\alpha \geq \gamma > 0";
    if ~result.diagnostics.physicalCandidate
        violation=replace(physicalSupport(result),["alpha","gamma",">=","<="], ...
            ["\alpha","\gamma","\geq","\leq"]);
        support=support+"; not satisfied ("+violation+")";
    end
    thicknessCaption=sprintf('\\rho = %.15g kg m^{-3}; current thickness h = %.3f mm', ...
        result.physical.density_kgpm3,result.physical.thickness_m*1e3);
    if byObservation
        selectedH=rowThickness(included);
        thicknessCaption=sprintf( ...
            '\\rho = %.15g kg m^{-3}; directional h = %.3f - %.3f mm (per observation)', ...
            result.physical.density_kgpm3,min(selectedH)*1e3,max(selectedH)*1e3);
    end
    notes={char("Physical support: "+support+"."),thicknessCaption};
    xlabel(layout,notes,'FontName','Arial','FontSize',9,'FontWeight','normal','Interpreter','tex');
    title(layout,{char(displayLabel),char(displaySubtitle)}, ...
        'Interpreter','tex','FontName','Arial','FontSize',9.5,'FontWeight','normal');
    axesList=findall(fig,'Type','axes');
    set(axesList,'FontName','Arial','FontSize',8,'LineWidth',.6,'Box','off', ...
        'TickDir','out','XMinorGrid','off','YMinorGrid','off','GridAlpha',.10);
    for k=1:numel(axesList)
        grid(axesList(k),'on');axesList(k).Title.FontSize=9;
    end
    regressionAxes=findall(fig,'Tag','plate_regression');
    text(regressionAxes,.98,.98,sprintf('Fitted observations: %d / %d',nnz(included),n), ...
        'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top', ...
        'FontName','Arial','FontSize',9,'Tag','plate_observation_count');
catch exception
    close(fig);rethrow(exception);
end
end

function plotRows(ax,x,y,marker,color,label,tag)
% Every original coordinate remains in its series; density changes glyphs only.
markerSize=3.5;if numel(x)>120,marker='.';markerSize=3;end
plot(ax,x,y,'LineStyle','none','Marker',marker,'Color',color,'MarkerSize',markerSize, ...
    'DisplayName',char(label),'Tag',tag);
end

function extensionGlyphs(ax,x,y,mask,visible,tag)
if ~any(mask),return;end
visibility='off';if visible,visibility='on';end
count=nnz(mask);indices=unique(round(linspace(1,count,min(count,24))));
plot(ax,x(mask),y(mask),'x','Color',[.8 .12 .12],'MarkerSize',4, ...
    'LineStyle','none','MarkerIndices',indices,'Visible',visibility,'HandleVisibility','off','Tag',tag);
end

function statement=physicalSupport(result)
if ~all(isfinite([result.alpha_Pa,result.gamma_Pa]))
    statement="unavailable coefficients";return
end
violations=strings(0,1);
if result.gamma_Pa<=0,violations(end+1)="gamma <= 0";end
if result.alpha_Pa<result.gamma_Pa,violations(end+1)="alpha < gamma";end
if isempty(violations),statement="alpha >= gamma > 0 satisfied";
else,statement=join(violations,"; ");end
end

function note=markOutside(ax,x,y,mask,limits,unit,kind,color)
% Original values stay intact; compact summaries and sparse glyphs avoid crowding.
note=strings(0,1);outside=mask&isfinite(x)&isfinite(y)&(y<limits(1)|y>limits(2));
if ~any(outside),return;end
extremes=[min(y(outside)),max(y(outside))];
captionKind=replace(kind,["selected speed","selected observation","selected residual","regression line","model prediction","excluded speed","excluded observation"], ...
    ["data","data","data","line","model","excluded","excluded"]);
captionUnit=unit;divisor=1;
if unit=="Pa"
    if max(abs(extremes))>=1e6,captionUnit="MPa";divisor=1e6;
    elseif max(abs(extremes))>=1e3,captionUnit="kPa";divisor=1e3;end
end
heading=upper(extractBetween(captionKind,1,1))+extractAfter(captionKind,1);
if extremes(1)==extremes(2)
    note=heading+" outside: "+string(sprintf('%d; %.4g %s',nnz(outside),extremes(1)/divisor,captionUnit));
else
    note=heading+" outside: "+string(sprintf('%d; [%.3g, %.3g] %s',nnz(outside),extremes(1)/divisor,extremes(2)/divisor,captionUnit));
end
% The clipped line and compact summary suffice; data edge glyphs stay distinct.
if kind=="regression line"||kind=="model prediction",return;end
for side=[-1 1]
    rows=find(mask&isfinite(x)&isfinite(y)&side*y>side*limits((side+3)/2));
    if isempty(rows),continue;end
    boundary=limits((side+3)/2);marker='^';if side<0,marker='v';end
    % Keep original coordinates; space displayed edge glyphs by 12 pixels.
    position=getpixelposition(ax,true);gap=12*diff(ax.XLim)/max(position(3),1);
    [~,order]=sort(x(rows));first=order(1);
    for candidate=order(2:end)'
        if x(rows(candidate))-x(rows(first(end)))>=gap
            first(end+1)=candidate; %#ok<AGROW>
        end
    end
    glyphRows=rows(first);
    face='none';if startsWith(kind,"selected"),face=color;end
    h=plot(ax,x(glyphRows),repmat(boundary,size(glyphRows)),marker,'Color',color, ...
        'MarkerFaceColor',face,'MarkerSize',5,'LineStyle','none','Clipping','off', ...
        'HandleVisibility','off','Tag',"offscale_"+replace(kind," ","_"));
    h.UserData=struct('originalIndices',rows,'displayedIndices',glyphRows, ...
        'originalXData',x(rows),'originalYData',y(rows),'unit',unit);
end
end
