function tests = test_rl_inverse_visualization()
%TEST_RL_INVERSE_VISUALIZATION Native m/s evidence without refitting or row loss.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
[testCase.TestData.native,testCase.TestData.provenance] = fixture("A0");
end

function testOriginalRowsMasksAndRawResidualUnits(testCase)
native=testCase.TestData.native; before=native;
[fig,e]=plotRlFitDiagnostics(native,testCase.TestData.provenance,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
verifyEqual(testCase,e.observations.row,(1:numel(native.frequency_Hz))');
verifyEqual(testCase,e.observations.frequency_Hz,native.frequency_Hz);
verifyEqual(testCase,e.observations.observedCp_mps,native.Cp_exp_mps);
verifyEqual(testCase,e.observations.predictedCp_mps,native.Cp_fit_mps);
verifyEqual(testCase,e.observations.selected,native.validMask);
verifyEqual(testCase,e.observations.residual_mps(native.validMask),native.residualInfo.rawResiduals_mps);
verifyTrue(testCase,all(isnan(e.observations.residual_mps(~native.validMask))));
verifyNotEqual(testCase,native.residuals,native.residualInfo.rawResiduals_mps);
verifyEqual(testCase,e.nativeMetrics,native.metrics);
verifyEqual(testCase,e.nativeDiagnostics,native.modelEvaluation.diagnostics);
verifyEqual(testCase,fig.UserData,e);
layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifySubstring(testCase,string(layout.XLabel.String{1}),"Physical support:");
verifySubstring(testCase,string(layout.XLabel.String{2}),"h = 0.500 mm");
lines=findall(fig,'Tag','rl_native_residual'); plotted=[];
for k=1:numel(lines),plotted=[plotted;lines(k).YData(:)];end %#ok<AGROW>
verifyEqual(testCase,sort(plotted),sort(native.residualInfo.rawResiduals_mps));
end

function testNativePredictionAndExplicitExclusions(testCase)
native=testCase.TestData.native;
[fig,e]=plotRlFitDiagnostics(native,testCase.TestData.provenance,'Visible','off');
cleanup=onCleanup(@()close(fig));
model=findall(fig,'Tag','rl_native_prediction');
rows=find(isfinite(native.frequency_Hz)&native.frequency_Hz>0& ...
    native.frequency_Hz<=max(native.frequency_Hz(native.validMask)));
[hz,index]=unique(native.frequency_Hz(rows),'sorted');
verifyEqual(testCase,model.XData(:),hz/1e3);
verifyEqual(testCase,model.YData(:),native.Cp_fit_mps(rows(index)));
verifyEqual(testCase,model.LineStyle,'--');
verifyEqual(testCase,model.Color,[0 0 0]);
verifyNotEmpty(testCase,findall(fig,'Tag','rl_excluded'));
excluded=findall(fig,'Tag','rl_excluded');
verifyEqual(testCase,excluded.Color,[.8 .12 .12]);
verifyEqual(testCase,excluded.Marker,'x');
verifyEqual(testCase,excluded.MarkerSize,4);
verifyEqual(testCase,numel(excluded.XData),nnz(e.observations.shownInDispersion&~native.validMask));
verifyEqual(testCase,e.unavailablePredictionCount,2); % excluded DC and NaN
verifyTrue(testCase,all(~e.observations.modelAvailable([1 end])));
verifyFalse(testCase,e.observations.shownInDispersion(end));
verifyEqual(testCase,e.excludedNotShownCount,2); % high excluded Hz and NaN
legendObject=findall(fig,'Type','legend');
verifyEqual(testCase,string(legendObject.String),["Rep. 1","Rep. 2","Model","Excluded"]);
end

function testRepetitionAndModelIdentityAreNotInferred(testCase)
native=testCase.TestData.native; provenance=testCase.TestData.provenance;
provenance.repetitionId=provenance.repetitionId(1:end-1);
verifyError(testCase,@()plotRlFitDiagnostics(native,provenance,'Visible','off'), ...
    'lamb:visualization:InvalidRepetition');
other=native;other.modelFamily="mrlfe";
verifyError(testCase,@()plotRlFitDiagnostics(other,testCase.TestData.provenance,'Visible','off'), ...
    'lamb:visualization:UnsupportedResult');
provenance=rmfield(testCase.TestData.provenance,'repetitionId');
fig=plotRlFitDiagnostics(native,provenance,'Visible','off');
cleanup=onCleanup(@()close(fig));
legendObject=findall(fig,'Type','legend');
verifyEqual(testCase,string(legendObject.String{1}),"Selected observations");
end

function testS0UsesItsNativeBranchAndPredictions(testCase)
[native,provenance]=fixture("S0");
[fig,e]=plotRlFitDiagnostics(native,provenance,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,e.observations.predictedCp_mps,native.Cp_fit_mps);
layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifySubstring(testCase,string(layout.Title.String{1}),"S_{0}");
end

function testExactGraphicSamplingDoesNotChangeTheNativeFit(testCase)
native=testCase.TestData.native;before=native;provenance=testCase.TestData.provenance;
[fullFig,full]=plotRlFitDiagnostics(native,provenance,'Visible','off');
fullCleanup=onCleanup(@()close(fullFig));
requested=[2000;4000];
[fig,e]=plotRlFitDiagnostics(native,provenance,'DisplayFrequency_Hz',requested,'Visible','off');
cleanup=onCleanup(@()close(fig));
sampled=ismember(native.frequency_Hz,requested);
verifyEqual(testCase,native,before);
verifyEqual(testCase,e.observations.sampledForDisplay,sampled);
verifyEqual(testCase,e.observations.selected,native.validMask);
verifyEqual(testCase,e.observations.row,full.observations.row);
verifyEqual(testCase,e.observations.frequency_Hz,full.observations.frequency_Hz);
verifyEqual(testCase,e.observations.predictedCp_mps,full.observations.predictedCp_mps);
verifyEqual(testCase,e.observations.residual_mps,full.observations.residual_mps);
verifyEqual(testCase,e.nativeMetrics,full.nativeMetrics);
verifyEqual(testCase,e.phaseSpeedScale,full.phaseSpeedScale);
verifyEqual(testCase,e.residualLimits_mps,full.residualLimits_mps);
verifyEqual(testCase,e.displayedSelectedCount,nnz(sampled&native.validMask));
lines=findall(fig,'Tag','rl_native_residual');coordinates=zeros(0,2);
for k=1:numel(lines)
    coordinates=[coordinates;lines(k).XData(:),lines(k).YData(:)]; %#ok<AGROW>
end
expected=[native.frequency_Hz(sampled&native.validMask)/1e3, ...
    e.observations.residual_mps(sampled&native.validMask)];
verifyEqual(testCase,sortrows(coordinates),sortrows(expected));
c=findall(fig,'Tag','rl_residuals');
verifyEqual(testCase,string(c.Title.String{1}),"C. Residuals");
b=findall(fig,'Tag','rl_fit_summary');
verifyNotEmpty(testCase,b);
verifyEqual(testCase,string(b.Title.String),"B. Native fit");
verifyEqual(testCase,b.Title.FontSize,9);
verifyNotEmpty(testCase,findall(b,'Tag','rl_native_fit_summary'));
end

function testGraphicFrequencyMustExistExactly(testCase)
native=testCase.TestData.native;
[fig,e]=plotRlFitDiagnostics(native,testCase.TestData.provenance, ...
    'DisplayFrequency_Hz',2000.1,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,e.displayedSelectedCount,0);
verifyFalse(testCase,any(e.observations.sampledForDisplay));
verifyEqual(testCase,e.observations.selected,native.validMask);
lines=findall(fig,'Tag','rl_native_residual');
for k=1:numel(lines),verifyEmpty(testCase,lines(k).YData);end
end

function testSpeedResidualScaleReusesPlatePolicyWithCorrectUnits(testCase)
values=[-.4;-.2;-.1;0;.1;.2;.3;100];
[speed,info]=resolveInversePhaseSpeedLimits(values,'Mode',"robust",'Quantity',"speed_residual");
[plate,legacy]=resolveInversePhaseSpeedLimits(values,'Mode',"robust",'Quantity',"residual");
verifyEqual(testCase,speed,plate);
verifyEqual(testCase,info.unit,"m/s");verifyEqual(testCase,legacy.unit,"Pa");
verifyEqual(testCase,info.quantity,"speed_residual");
verifyEqual(testCase,info.outsideCount,1);
verifyEqual(testCase,info.maximumOutside,100);
verifyEqual(testCase,info.outsideCount,legacy.outsideCount);
for quantity=["phase_speed","regression","residual"]
    [limits,e]=resolveInversePhaseSpeedLimits([1;2;3;4],'Quantity',quantity);
    verifyEqual(testCase,limits,[0 4.4]);
    if quantity=="phase_speed"
        verifyEqual(testCase,e.unit,"m/s");verifyEqual(testCase,e.limits_mps,limits);
    else
        verifyEqual(testCase,e.unit,"Pa");verifyFalse(testCase,isfield(e,'limits_mps'));
    end
end
end

function testClippedGraphicResidualsRetainNativeRowsAndStatistics(testCase)
native=testCase.TestData.native;before=native;
provenance=testCase.TestData.provenance;provenance.modelSupportReference="A_{0} hypothesis.";
[fig,e]=plotRlFitDiagnostics(native,provenance,'DisplayFrequency_Hz',[2000;4000], ...
    'ResidualLimits',[-.05 .05],'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
outside=native.validMask & (e.observations.residual_mps<-.05 | e.observations.residual_mps>.05);
verifyEqual(testCase,e.observations.residualOutsideView,outside);
verifyEqual(testCase,e.residualClipping.originalRows,find(outside));
verifyEqual(testCase,e.residualClipping.outsideCount,nnz(outside));
verifyEqual(testCase,e.residualClipping.unit,"m/s");
verifyEqual(testCase,e.nativeMetrics,native.metrics);
verifyEqual(testCase,e.nativeFitConfiguration.optimizer,native.optimizer);
verifyEqual(testCase,e.nativeFitConfiguration.lowerBounds,native.lowerBounds);
verifyEqual(testCase,e.observations.residual_mps(native.validMask),native.residualInfo.rawResiduals_mps);
glyphs=findall(fig,'Tag','rl_offscale_residual');verifyNotEmpty(testCase,glyphs);
for k=1:numel(glyphs)
    original=glyphs(k).UserData.originalIndices;
    displayed=glyphs(k).UserData.displayedIndices;
    verifyTrue(testCase,all(outside(original)));
    verifyTrue(testCase,ismember(displayed,original));
    verifyEqual(testCase,glyphs(k).XData(:),native.frequency_Hz(displayed)/1e3);
    verifyEqual(testCase,glyphs(k).UserData.originalYData,e.observations.residual_mps(original));
    verifyTrue(testCase,all(ismember(glyphs(k).YData,[-.05 .05])));
    verifyEqual(testCase,glyphs(k).Color,[.16 .40 .68]);
    verifyEqual(testCase,glyphs(k).MarkerFaceColor,[.16 .40 .68]);
    verifyEqual(testCase,numel(glyphs(k).XData),1);
end
verifyEmpty(testCase,findall(fig,'Tag','rl_residual_clipping_note'));
c=findall(fig,'Tag','rl_residuals');
verifyEqual(testCase,string(c.Title.String{2}),string(sprintf('RMSE = %.3f m/s',native.metrics.RMSE)));
verifySubstring(testCase,string(c.Title.String{3}),"Data outside: "+nnz(outside)+"; ");
verifySubstring(testCase,string(c.Title.String{3}),"m/s");
b=findall(fig,'Tag','rl_fit_summary');
items=findall(b,'Tag','rl_native_fit_summary');
verifyEqual(testCase,numel(items),4);
captions=string({items.String});
verifyTrue(testCase,any(captions=="Search bounds: \mu \in [20, 200] kPa"));
positions=arrayfun(@(item)item.Position(2),items);
verifyLessThan(testCase,max(positions)-min(positions),.34);
layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifyEqual(testCase,string(layout.XLabel.String{1}),"Physical support: A_{0} hypothesis.");
end

function testUnsampledOutliersHaveCompactNativeBoundaryIndicators(testCase)
native=testCase.TestData.native;
[fig,e]=plotRlFitDiagnostics(native,testCase.TestData.provenance, ...
    'DisplayFrequency_Hz',2000.1,'ResidualLimits',[100 101],'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,e.displayedSelectedCount,0);
verifyFalse(testCase,any(e.observations.shownInResiduals));
glyph=findall(fig,'Tag','rl_offscale_residual');
verifyEqual(testCase,numel(glyph),1);
verifyEqual(testCase,glyph.Marker,'v');
verifyEqual(testCase,glyph.Color,[.16 .40 .68]);
verifyEqual(testCase,glyph.UserData.originalIndices,find(native.validMask));
verifyEqual(testCase,numel(glyph.XData),1);
verifyEqual(testCase,e.nativeMetrics,native.metrics);
verifyEqual(testCase,e.observations.selected,native.validMask);
end

function testMeasuredThicknessModelLinesStayWithinExactGroups(testCase)
native=testCase.TestData.native;
h=[NaN;.405;.406;.405;.406;.405;.406;.405;.406;.405;.406;NaN]*1e-3;
native.problem.experimental.observationThickness_m=h(:);
[fig,e]=plotRlFitDiagnostics(native,testCase.TestData.provenance,'Visible','off');
cleanup=onCleanup(@()close(fig));
lines=findall(fig,'Tag','rl_native_prediction');
verifyEqual(testCase,numel(lines),2);
allModelRows=find(isfinite(native.frequency_Hz)&native.frequency_Hz>0 & ...
    native.frequency_Hz<=max(native.frequency_Hz(native.validMask)));
for thickness=[.405e-3,.406e-3]
    rows=allModelRows(h(allModelRows)==thickness);
    [hz,index]=unique(native.frequency_Hz(rows),'sorted');
    expectedCp=native.Cp_fit_mps(rows(index));
    matched=false;
    for k=1:numel(lines)
        if isequal(lines(k).XData(:),hz(:)/1e3) && ...
                isequal(lines(k).YData(:),expectedCp(:))
            matched=true;
        end
    end
    verifyTrue(testCase,matched);
end
verifyEqual(testCase,e.observations.selected,native.validMask);
withinView=isfinite(native.frequency_Hz) & native.frequency_Hz>=0 & ...
    native.frequency_Hz<=max(native.frequency_Hz(native.validMask)) & ...
    isfinite(native.Cp_exp_mps);
[~,expectedScale]=resolveInversePhaseSpeedLimits( ...
    [native.Cp_exp_mps(withinView);native.Cp_fit_mps(allModelRows)], ...
    'Mode',"complete");
verifyEqual(testCase,e.phaseSpeedScale,expectedScale);
layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifySubstring(testCase,string(layout.XLabel.String{2}),"per observation");
verifySubstring(testCase,string(layout.XLabel.String{2}),"0.405");
verifySubstring(testCase,string(layout.XLabel.String{2}),"0.406");
end

function [native,provenance] = fixture(branch)
p=lamb.models.rayleigh_lamb.rlDefaultParams();p.mu=85e3;
options=lamb.models.rayleigh_lamb.rlDefaultOptions("Fast");
f=[0;1000;2000;2000;4000;6000;8000;1000;2000;4000;6000;NaN];
positive=isfinite(f)&f>0;cp=zeros(size(f));cp(end)=NaN;
cp(positive)=lamb.fitting.rayleigh_lamb.rlEvaluateFitModel(p,f(positive),branch,options)+ ...
    [.1;.2;-.2;.1;-.1;.2;-.1;.1;-.2;.2];
mask=[false;true;true;true;true;true;false;true;true;true;true;false];
ex=struct('frequency_Hz',f,'Cp_mps',cp,'validMask',mask,'standardError_Cp_mps',.25*ones(size(f)));
config=struct('branchName',branch,'freeParams',"mu",'fixedParams', ...
    struct('rho',p.rho,'thickness',p.thickness,'nu',p.nu),'initialGuess',struct('mu',50e3), ...
    'bounds',struct('mu',[20e3 200e3]),'solverOptions',options, ...
    'fitOptions',struct('useStandardErrorWeights',true));
native=lamb.fitting.rayleigh_lamb.rlFitDispersionData(ex,config);
provenance=struct('label',"Synthetic condition / signed direction",'material',"Synthetic material", ...
    'sourceReference',"Synthetic original observations",'modelSupportReference', ...
    "Synthetic modal request; no experimental physical-validity claim.", ...
    'repetitionId',[repmat("1",7,1);repmat("2",5,1)]);
end
