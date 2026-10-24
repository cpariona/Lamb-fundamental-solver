function [fig, evidence] = plotAePlateParameterTrends(results, coordinates, varargin)
%PLOTAEPLATEPARAMETERTRENDS Compare reviewed native Plate results without refitting.
%   RESULTS is a cell vector of native results; [] declares a missing result.
%   COORDINATES is a same-height table with mechanicalCoordinate (double),
%   axisLabel, directionId, conditionId, material and sourceReference (text).
%   Optional seriesLabel distinguishes actual acquisition populations, such
%   as pooled QH and one Pulse acquisition, at the same reviewed coordinate.
%   Coordinates are caller-reviewed measurements/metadata, never inferred here.
%   CoordinateLabel supplies their physical meaning/unit. Label names the study.
%   Declare missing states explicitly. Accepted lines break at rejected/missing
%   states. Finite rejected alpha/gamma candidates use red x markers; their
%   alpha-gamma is not presented as a supported physical result.
%   DisplayMode="accepted" resolves parameter ranges from all finite native
%   accepted values, counting any rejected candidates outside the scale.
%   Default "complete" includes all finite candidates. No result is removed.
p=inputParser;
addParameter(p,'CoordinateLabel',"",@(x) isscalar(string(x)) && strlength(string(x))>0);
addParameter(p,'Label',"Reviewed Plate results",@(x) isscalar(string(x)));
addParameter(p,'Visible','on',@(x) any(string(x)==["on","off"]));
addParameter(p,'DisplayMode',"complete",@(x) any(string(x)==["complete","accepted"]));
parse(p,varargin{:});
required=["mechanicalCoordinate","axisLabel","directionId","conditionId","material","sourceReference"];
if ~iscell(results) || ~isvector(results) || ~istable(coordinates) || ...
        height(coordinates)~=numel(results) || any(~ismember(required,string(coordinates.Properties.VariableNames))) || ...
        strlength(string(p.Results.CoordinateLabel))==0
    error('lamb:visualization:InvalidTrendCoordinates','Supply native cells, reviewed coordinates and their explicit physical label/unit.');
end
validateattributes(coordinates.mechanicalCoordinate,{'double'},{'vector','real','finite'});
for name=required(2:end)
    text=string(coordinates.(name));
    if any(ismissing(text) | strlength(strtrim(text))==0)
        error('lamb:visualization:MissingProvenance','Nonempty per-result %s is required.',name);
    end
end
n=numel(results);alpha=nan(n,1);gamma=alpha;difference=alpha;
density=alpha;thickness=alpha;accepted=false(n,1);missing=false(n,1);reasons=strings(n,1);
for k=1:n
    r=results{k};
    if isempty(r), missing(k)=true;reasons(k)="missing native result";continue;end
    if r.model~="acoustoelastic_prestressed_plate"
        error('lamb:visualization:UnsupportedResult','Trend inputs must be native Plate results.');
    end
    alpha(k)=r.alpha_Pa;gamma(k)=r.gamma_Pa;accepted(k)=r.accepted;
    density(k)=r.physical.density_kgpm3;thickness(k)=r.physical.thickness_m;
    if ~isempty(r.reasons), reasons(k)=join(string(r.reasons),', '); end
    if accepted(k) && r.diagnostics.physicalCandidate
        principal=lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(alpha(k),gamma(k));
        difference(k)=principal.stressDifferencePropagationMinusNormal_Pa;
    end
end
values=[alpha,gamma,difference]/1e3;
gridCoordinates=unique(coordinates.mechanicalCoordinate);
if ~ismember('seriesLabel',coordinates.Properties.VariableNames)
    coordinates.seriesLabel=repmat("native",n,1);
elseif any(ismissing(string(coordinates.seriesLabel)) | strlength(string(coordinates.seriesLabel))==0)
    error('lamb:visualization:MissingProvenance','Nonempty seriesLabel is required when supplied.');
end
groups=unique(coordinates(:,{'axisLabel','directionId','seriesLabel'}),'rows','stable');
for k=1:height(groups)
    rows=string(coordinates.axisLabel)==string(groups.axisLabel(k)) & ...
        string(coordinates.directionId)==string(groups.directionId(k)) & ...
        string(coordinates.seriesLabel)==string(groups.seriesLabel(k));
    if numel(unique(coordinates.mechanicalCoordinate(rows)))~=nnz(rows)
        error('lamb:visualization:AmbiguousTrendCoordinate','One result per coordinate and signed axis is required.');
    end
end
evidence=struct('coordinates',coordinates,'accepted',accepted,'missing',missing,'nativeReasons',reasons, ...
    'alpha_Pa',alpha,'gamma_Pa',gamma,'supportedDifference_Pa',difference, ...
    'density_kgpm3',density,'currentFullThickness_m',thickness,'coordinateLabel',string(p.Results.CoordinateLabel));
evidence.parameterLimits_kPa=nan(3,2);
evidence.outsideDisplayCount=zeros(3,1);
evidence.maximumAbsoluteOutside_kPa=nan(3,1);
evidence.displayMode=string(p.Results.DisplayMode);
fig=figure('Color','w','Position',[50 50 1450 650],'Visible',p.Results.Visible, ...
    'Name',char(string(p.Results.Label)),'UserData',evidence);
try
    layout=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
    colors=lines(height(groups));labels=["alpha [kPa]","gamma [kPa]","alpha - gamma [kPa]"];
    for panel=1:3
        ax=nexttile(layout);hold(ax,'on');grid(ax,'on');
        for k=1:height(groups)
            rows=string(coordinates.axisLabel)==string(groups.axisLabel(k)) & ...
                string(coordinates.directionId)==string(groups.directionId(k)) & ...
                string(coordinates.seriesLabel)==string(groups.seriesLabel(k));
            indices=find(rows);[~,positions]=ismember(coordinates.mechanicalCoordinate(rows),gridCoordinates);
            y=nan(size(gridCoordinates));valid=accepted(indices)&isfinite(values(indices,panel));
            y(positions(valid))=values(indices(valid),panel);
            marker='o';if mod(k,2)==0,marker='s';end
            plot(ax,gridCoordinates,y,'-','Marker',marker,'Color',colors(k,:), ...
                'LineWidth',1.3,'DisplayName',char(string(groups.seriesLabel(k))+" / "+string(groups.axisLabel(k))+" / "+string(groups.directionId(k))+"; accepted"), ...
                'Tag','accepted_trend');
            rejected=rows&~accepted&~missing&isfinite(values(:,panel));
            if panel<3
                plot(ax,coordinates.mechanicalCoordinate(rejected),values(rejected,panel),'x', ...
                    'Color',[.75 .15 .15],'LineWidth',1.5,'MarkerSize',8, ...
                    'DisplayName',char(string(groups.seriesLabel(k))+" / "+string(groups.axisLabel(k))+" / "+string(groups.directionId(k))+"; rejected candidate"), ...
                    'Tag','rejected_trend_candidate');
            end
        end
        xlabel(ax,char(string(p.Results.CoordinateLabel)));ylabel(ax,char(labels(panel)));
        population=values(accepted&isfinite(values(:,panel)),panel);
        if string(p.Results.DisplayMode)=="accepted" && ~isempty(population)
            lower=min(population);upper=max(population);
            padding=0.1*max([upper-lower,abs(lower),abs(upper),eps]);
            ylim(ax,[lower-padding,upper+padding]);
        end
        ax.YAxis.Exponent=0;ax.YAxis.TickLabelFormat='%.3g';
        limits=ylim(ax);
        outside=isfinite(values(:,panel)) & (values(:,panel)<limits(1) | values(:,panel)>limits(2));
        evidence.parameterLimits_kPa(panel,:)=limits;
        evidence.outsideDisplayCount(panel)=nnz(outside);
        if any(outside),evidence.maximumAbsoluteOutside_kPa(panel)=max(abs(values(outside,panel)));end
        title(ax,char(labels(panel)),'Interpreter','none');
        if panel==3
            title(ax,{'alpha - gamma: accepted supported fits only', ...
                sprintf('%d rejected and %d missing not interpreted',nnz(~accepted&~missing),nnz(missing))},'FontSize',10);
        end
        if any(outside)
            title(ax,{char(labels(panel)),sprintf('Outside range: %d rejected; max |value| %.4g kPa', ...
                nnz(outside&~accepted),evidence.maximumAbsoluteOutside_kPa(panel))},'FontSize',10);
        end
        legend(ax,'Location','best','Interpreter','none');
    end
    present=~missing;
    physicalCaption='No native physical results available';
    if any(present)
        physicalCaption=sprintf('%s; rho %.6g-%.6g kg/m^3; current full thickness %.6g-%.6g mm', ...
            join(unique(string(coordinates.material),'stable'),', '),min(density(present)),max(density(present)), ...
            1e3*min(thickness(present)),1e3*max(thickness(present)));
    end
    title(layout,{char(string(p.Results.Label)),physicalCaption, ...
        'Exploratory A0 working hypothesis; no interpolation across rejected/missing states. Per-result source/physical provenance in FIG.UserData.'}, ...
        'Interpreter','none','FontSize',11);
    fig.UserData=evidence;
catch exception
    close(fig);rethrow(exception);
end
end
