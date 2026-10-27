function tests = test_plate_inverse_visualization()
%TEST_PLATE_INVERSE_VISUALIZATION Native invariance, honest presentation and export.
tests = functiontests(localfunctions);
end

function testNativeRowsResidualsAndCanonicalPrediction(testCase)
[native,review]=fixture();before=native;
[fig,e]=plotAePlateFitDiagnostics(native,review,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
verifyEqual(testCase,e.observations.frequency_Hz,native.experimental.frequency_Hz);
verifyEqual(testCase,e.observations.Cp_mps,native.experimental.Cp_mps);
verifyEqual(testCase,e.observations.included,native.validMask);
verifyEqual(testCase,e.observations.nativeResidual_Pa,native.regressionResidual_Pa);
verifyEqual(testCase,e.observations.nativeEtaSquared,native.etaSquared);
verifyEqual(testCase,e.excludedCount,4);verifyEqual(testCase,e.nonvisibleCoordinateCount,2);
verifyEqual(testCase,nnz(e.observations.ridgeInvalid),4);
verifyTrue(testCase,all(isnan(e.observations.nativeEtaSquared(~native.validMask))));
verifyTrue(testCase,all(isfinite(e.observations.displayEtaSquared([7 8]))));
physical=native.physical;physical.alpha_Pa=native.alpha_Pa;physical.gamma_Pa=native.gamma_Pa;
forward=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(e.forwardCurve.frequency_Hz,physical);
verifyEqual(testCase,e.forwardCurve,forward);
lines=findall(fig,'Tag','native_residual');
plotted=[];
for k=1:numel(lines),plotted=[plotted;lines(k).YData(:)];end %#ok<AGROW>
verifyEqual(testCase,sort(plotted),sort(native.regressionResidual_Pa(native.validMask)));
countNote=findall(fig,'Tag','plate_observation_count');
verifyEqual(testCase,string(countNote.String),"Fitted observations: 4 / 8");
verifyEqual(testCase,countNote.Parent,findall(fig,'Tag','plate_regression'));
verifyEqual(testCase,countNote.Units,'normalized');
verifyEqual(testCase,countNote.Position(1:2),[.98 .98]);
verifyEqual(testCase,countNote.FontSize,9);
excluded=findall(fig,'Type','line','-regexp','Tag','^excluded_');
verifyNotEmpty(testCase,excluded);
for glyph=excluded'
    verifyEqual(testCase,glyph.Color,[.8 .12 .12]);
    verifyEqual(testCase,glyph.Marker,'x');
    verifyEqual(testCase,glyph.MarkerSize,4);
end
end

function testMetricPrecedesClippingWithBlueOriginalValueIndicators(testCase)
[native,review]=fixture();
[fig,e]=plotAePlateFitDiagnostics(native,review,'PhaseSpeedLimits',[0 1], ...
    'RegressionLimits',[0 1],'ResidualLimits',[1e9 2e9],'Visible','off');
cleanup=onCleanup(@()close(fig));
for tag=["plate_regression","plate_residuals"]
    ax=findall(fig,'Tag',tag);captions=string(ax.Title.String);
    verifySubstring(testCase,captions(3),"Data outside:");
    verifySubstring(testCase,captions(3),"; ");
    if tag=="plate_regression",verifySubstring(testCase,captions(2),"\alpha");
    else,verifySubstring(testCase,captions(2),"RMSE = ");end
end
for tag=["offscale_selected_observation","offscale_selected_residual"]
    glyphs=findall(fig,'Tag',tag);verifyNotEmpty(testCase,glyphs);
    for glyph=glyphs'
        verifyEqual(testCase,glyph.Color,[.16 .40 .68]);
        verifyNotEmpty(testCase,glyph.UserData.originalYData);
    end
end
verifyEqual(testCase,e.observations.included,native.validMask);
end

function testUnsupportedCandidateIsNotForwardEvaluated(testCase)
[native,review]=fixture();data=native.experimental;
data.frequency_Hz=[100;500;1000;5000;10000];data.Cp_mps=[20;18;16;14;12];
data.validMask=true(5,1);review=rmfield(review,{'sourceMasks','repetitionId'});
rejected=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
verifyFalse(testCase,rejected.accepted);verifyFalse(testCase,rejected.diagnostics.physicalCandidate);
[fig,e]=plotAePlateFitDiagnostics(rejected,review,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEmpty(testCase,findall(fig,'Tag','plate_forward'));
verifyNotEmpty(testCase,findall(fig,'Tag','native_regression_line'));
verifyEqual(testCase,e.nativeReasons,rejected.reasons);
verifyFalse(testCase,e.ridgeEvidenceAvailable);
end

function testNumericalRejectionRetainsSupportedCandidate(testCase)
[native,review]=fixture();data=native.experimental;
data.independentFrequencyGroupId=ones(size(data.frequency_Hz));
rejected=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
verifyFalse(testCase,rejected.accepted);verifyTrue(testCase,rejected.diagnostics.physicalCandidate);
[fig,e]=plotAePlateFitDiagnostics(rejected,review,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyNotEmpty(testCase,findall(fig,'Tag','plate_forward'));
verifyTrue(testCase,ismember("insufficient_independent_frequencies",e.nativeReasons));
verifyEqual(testCase,rejected.alpha_Pa,native.alpha_Pa);
verifyEqual(testCase,rejected.regressionResidual_Pa,native.regressionResidual_Pa);
end

function testRobustSharedAndCompleteScalesPreserveRows(testCase)
population=[1;2;3;4;5;6;7;8;9;10;1e6;NaN];before=population;
[shared,info]=resolveInversePhaseSpeedLimits(population,'Mode',"robust");
verifyLessThan(testCase,shared(2),1e6);verifyEqual(testCase,info.outsideCount,1);
[complete,allInfo]=resolveInversePhaseSpeedLimits(population);
verifyGreaterThan(testCase,complete(2),1e6);verifyEqual(testCase,allInfo.outsideCount,0);
verifyEqual(testCase,population,before);verifyEqual(testCase,info.nonfiniteCount,1);
[native,review]=fixture();original=native;
[f1,e1]=plotAePlateFitDiagnostics(native,review,'PhaseSpeedLimits',shared,'Visible','off');
c1=onCleanup(@()close(f1));
[f2,e2]=plotAePlateFitDiagnostics(native,review,'PhaseSpeedLimits',shared,'Visible','off');
c2=onCleanup(@()close(f2));
verifyEqual(testCase,ylim(findall(f1,'Tag','plate_dispersion')),ylim(findall(f2,'Tag','plate_dispersion')));
verifyEqual(testCase,e1.display.source,"explicit_shared");
verifyEqual(testCase,e1.observations,e2.observations);verifyEqual(testCase,native,original);
verifyGreaterThan(testCase,e1.observedClipping.outsideCount,0);
verifyEqual(testCase,e1.observedClipping.maximumOutside_mps,max(native.experimental.Cp_mps,[],'omitnan'));
end

function testTrendGapsMissingStatesAndSignedDirections(testCase)
[native,~]=fixture();data=native.experimental;data.independentFrequencyGroupId=ones(size(data.frequency_Hz));
bad=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
results={native;bad;native;native;[];native};
coordinates=table([0;5;10;0;5;10],repmat("longitudinal",6,1), ...
    ["left";"left";"left";"right";"right";"right"], ...
    ["s0";"s5";"s10";"s0";"s5";"s10"],repmat("synthetic",6,1),repmat("reviewed-request.mat",6,1), ...
    'VariableNames',{'mechanicalCoordinate','axisLabel','directionId','conditionId','material','sourceReference'});
before=results;
[fig,e]=plotAePlateParameterTrends(results,coordinates,'CoordinateLabel',"Recorded strain [%]",'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,results,before);verifyEqual(testCase,nnz(e.missing),1);
verifyTrue(testCase,isnan(e.supportedDifference_Pa(2)));
lines=findall(fig,'Tag','accepted_trend');verifyEqual(testCase,numel(lines),6);
for k=1:numel(lines),verifyTrue(testCase,isnan(lines(k).YData(2)));end
verifyEqual(testCase,numel(findall(fig,'Tag','rejected_trend_candidate')),2);
verifyError(testCase,@()plotAePlateParameterTrends(results,coordinates), ...
    'lamb:visualization:InvalidTrendCoordinates');
end

function testEditableExportAndReadable300DpiTiff(testCase)
[native,review]=fixture();fig=plotAePlateFitDiagnostics(native,review,'Visible','off');
c1=onCleanup(@()close(fig));
folder=tempname;mkdir(folder);c2=onCleanup(@()rmdir(folder,'s'));
files=saveInverseFigure(fig,folder,'synthetic_plate_raw');
reopened=openfig(files.fig,'invisible');c3=onCleanup(@()close(reopened));
verifyEqual(testCase,reopened.UserData.observations,fig.UserData.observations);
verifyEqual(testCase,findall(reopened,'Tag','plate_forward').XData,findall(fig,'Tag','plate_forward').XData);
verifyEqual(testCase,findall(reopened,'Tag','plate_forward').YData,findall(fig,'Tag','plate_forward').YData);
imageInfo=imfinfo(files.tif);
verifyEqual(testCase,imageInfo.XResolution,300);verifyEqual(testCase,imageInfo.YResolution,300);
verifyGreaterThan(testCase,imageInfo.Width,0);verifyGreaterThan(testCase,imageInfo.Height,0);
expectedPixels=round(fig.Position(3:4)/2.54*300);
verifyEqual(testCase,[imageInfo.Width imageInfo.Height],expectedPixels);
verifyEqual(testCase,reopened.PaperPositionMode,'auto');
verifyNotEmpty(testCase,imread(files.tif));
verifyError(testCase,@()saveInverseFigure(fig,folder,'synthetic_plate_raw'),'lamb:visualization:OutputExists');
verifyError(testCase,@()saveInverseFigure(fig,folder,'../source'),'lamb:visualization:InvalidDestination');
end

function testRankDeficientResidualsAreNotInvented(testCase)
[native,review]=fixture();data=struct('frequency_Hz',[1000;1000], ...
    'Cp_mps',[12;12],'validMask',true(2,1),'conditionId',"one",'directionId',"axis1:left");
native=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
review=rmfield(review,{'sourceMasks','repetitionId'});
[fig,e]=plotAePlateFitDiagnostics(native,review,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyFalse(testCase,e.nativeAccepted);
verifyTrue(testCase,all(isnan(e.observations.nativeResidual_Pa)));
verifyEmpty(testCase,findall(fig,'Tag','native_residual'));
verifyEmpty(testCase,findall(fig,'Tag','native_regression_line'));
verifyEmpty(testCase,findall(fig,'Tag','plate_forward'));
end

function testSeparatePopulationsAtSameCoordinateAndMaskShape(testCase)
[native,review]=fixture();review.sourceMasks.valid_mask=true(2,1);
verifyError(testCase,@()plotAePlateFitDiagnostics(native,review), ...
    'MATLAB:incorrectNumel');
coordinates=table([0;0],repmat("transverse",2,1),repmat("left",2,1), ...
    repmat("state0",2,1),repmat("synthetic",2,1),["qh-request";"pulse-request"], ...
    ["QH pooled";"Pulse R001"], ...
    'VariableNames',{'mechanicalCoordinate','axisLabel','directionId','conditionId','material','sourceReference','seriesLabel'});
original=coordinates;
[fig,e]=plotAePlateParameterTrends({native;native},coordinates,'CoordinateLabel',"Recorded strain [%]",'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,coordinates,original);verifyEqual(testCase,e.coordinates,original);
verifyEqual(testCase,numel(findall(fig,'Tag','accepted_trend')),6);
end

function testAcceptedParameterDisplayRetainsExtremeRejectedCandidates(testCase)
[native,~]=fixture();data=struct('frequency_Hz',[100;500;1000;5000;10000], ...
    'Cp_mps',[20;18;16;14;12],'validMask',true(5,1),'conditionId',"one",'directionId',"axis1:left");
rejected=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
results={native;rejected;native};
coordinates=table([0;5;10],repmat("longitudinal",3,1),repmat("left",3,1), ...
    ["s0";"s5";"s10"],repmat("synthetic",3,1),repmat("native-request",3,1), ...
    'VariableNames',{'mechanicalCoordinate','axisLabel','directionId','conditionId','material','sourceReference'});
before=results;
[fig,e]=plotAePlateParameterTrends(results,coordinates,'CoordinateLabel',"Recorded strain [%]", ...
    'DisplayMode',"accepted",'Visible','off');
c1=onCleanup(@()close(fig));
verifyEqual(testCase,results,before);verifyGreaterThan(testCase,sum(e.outsideDisplayCount),0);
verifyEqual(testCase,e.alpha_Pa(2),rejected.alpha_Pa);verifyEqual(testCase,e.gamma_Pa(2),rejected.gamma_Pa);
lines=findall(fig,'Tag','rejected_trend_candidate');verifyEqual(testCase,numel(lines),2);
[full,complete]=plotAePlateParameterTrends(results,coordinates,'CoordinateLabel',"Recorded strain [%]",'Visible','off');
c2=onCleanup(@()close(full));
verifyEqual(testCase,sum(complete.outsideDisplayCount),0);
verifyEqual(testCase,complete.alpha_Pa,e.alpha_Pa);verifyEqual(testCase,complete.gamma_Pa,e.gamma_Pa);
end

function testComparableCaseEnvelopeDoesNotWeightDenseAcquisitions(testCase)
cases={(1:10)';(10:20)';[(2:8)';1e6]};
[limits,e]=resolveInversePhaseSpeedLimits(cases,'Mode',"robust");
dense=cases;dense{1}=repmat(dense{1},1000,1);
verifyEqual(testCase,resolveInversePhaseSpeedLimits(dense,'Mode',"robust"),limits);
verifyEqual(testCase,resolveInversePhaseSpeedLimits(cases([3 1 2]),'Mode',"robust"),limits);
verifyGreaterThanOrEqual(testCase,limits(2),max(cases{2}));
verifyLessThan(testCase,limits(2),1e6);verifyEqual(testCase,e.outsideCount,1);
verifyEqual(testCase,e.source,"case_envelope_robust");
verifyEqual(testCase,resolveInversePhaseSpeedLimits(cases,'Limits',[0 7]),[0 7]);
end

function testDenseGlyphsAndOffscaleExtremesKeepEveryNativeRow(testCase)
[native,review]=fixture();data=native.experimental;
for key=["frequency_Hz","Cp_mps","validMask"]
    data.(key)=repmat(data.(key),100,1);
end
native=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
review.repetitionId=repmat(review.repetitionId,100,1);
for key=string(fieldnames(review.sourceMasks))'
    review.sourceMasks.(key)=repmat(review.sourceMasks.(key),100,1);
end
before=native;
[fig,e]=plotAePlateFitDiagnostics(native,review,'PhaseSpeedLimits',[0 1],'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
verifyEqual(testCase,e.observations.Cp_mps,native.experimental.Cp_mps);
verifyEqual(testCase,e.observations.included,native.validMask);
series=findall(fig,'Tag','included_observations');count=0;
for k=1:numel(series)
    count=count+numel(series(k).XData);
    verifyEqual(testCase,series(k).Marker,'.');
end
verifyEqual(testCase,count,nnz(native.validMask));
edge=findall(fig,'Tag','offscale_selected_speed');
outside=native.validMask&isfinite(native.experimental.frequency_Hz)&isfinite(native.experimental.Cp_mps)&native.experimental.Cp_mps>1;
verifyEqual(testCase,edge.UserData.originalYData,native.experimental.Cp_mps(outside));
verifyEqual(testCase,edge.YData(:),ones(numel(edge.XData),1));
axis=findall(fig,'Tag','plate_dispersion');verifyTrue(testCase,any(contains(string(axis.Title.String),"outside",'IgnoreCase',true)));
verifyEqual(testCase,numel(findall(fig,'Type','legend')),1);
end

function testSignedPanelScalesHaveCorrectUnitsAndKeepZero(testCase)
values=[(-5:5)';-1e9;1e9];
[limits,e]=resolveInversePhaseSpeedLimits(values,'Mode',"robust",'Quantity',"residual");
verifyLessThan(testCase,limits(1),0);verifyGreaterThan(testCase,limits(2),0);
verifyLessThan(testCase,max(abs(limits)),1e9);verifyEqual(testCase,e.outsideCount,2);
verifyEqual(testCase,e.unit,"Pa");verifyFalse(testCase,isfield(e,'limits_mps'));
negative=resolveInversePhaseSpeedLimits([-5;-4;-3],'Mode',"robust",'Quantity',"residual");
verifyGreaterThanOrEqual(testCase,negative(2),0);
end

function testReadableSupportAndOriginalFrequencyResidualCoordinates(testCase)
[native,review]=fixture();before=native;
review.displayLabel="Sample | state | longitudinal / left | AE Plate inversion";
review.displaySubtitle="Pulse; period 166.667 us; repetition 1";
[fig,e]=plotAePlateFitDiagnostics(native,review,'DisplayMode',"robust",'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);verifyEqual(testCase,e.observations.nativeResidual_Pa,native.regressionResidual_Pa);
verifyTrue(testCase,contains(e.presentation.physicalStatement,"alpha >= gamma > 0"));
extensions=findall(fig,'Tag','excluded_extensions');verifyEqual(testCase,string(extensions.Visible),"off");
lines=findall(fig,'Tag','native_residual');xy=zeros(0,2);
for k=1:numel(lines),xy=[xy;lines(k).XData(:),lines(k).YData(:)];end %#ok<AGROW>
expected=[native.experimental.frequency_Hz(native.validMask)/1e3,native.regressionResidual_Pa(native.validMask)];
verifyEqual(testCase,sortrows(xy),sortrows(expected));
verifyEqual(testCase,numel(findall(fig,'Type','legend')),1);
verifyEqual(testCase,e.display.limits,resolveInversePhaseSpeedLimits( ...
    native.experimental.Cp_mps(native.validMask),'Mode',"robust"));
end

function testJointRepetitionDisplaySamplingKeepsFullFit(testCase)
[native,review]=fixture();data=native.experimental;count=numel(data.frequency_Hz);
for key=["frequency_Hz","Cp_mps","validMask"]
    data.(key)=repmat(data.(key),3,1);
end
joint=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,native.physical);
review.repetitionId=repelem(["1";"2";"3"],count);
for key=string(fieldnames(review.sourceMasks))'
    review.sourceMasks.(key)=repmat(review.sourceMasks.(key),3,1);
end
before=joint;requested=[100;111;3000];
[fig,e]=plotAePlateFitDiagnostics(joint,review,'DisplayFrequency_Hz',requested,'Visible','off');
cleanup=onCleanup(@()close(fig));
expected=joint.validMask&ismember(joint.experimental.frequency_Hz,requested);
verifyEqual(testCase,joint,before);
verifyEqual(testCase,e.observations.included,joint.validMask);
verifyEqual(testCase,e.observations.nativeResidual_Pa,joint.regressionResidual_Pa);
verifyEqual(testCase,e.displayedObservationMask,expected);
verifyEqual(testCase,nnz(joint.validMask),12);verifyEqual(testCase,nnz(expected),6);
verifyEqual(testCase,numel(findall(fig,'Tag','native_regression_line')),1);
verifyEqual(testCase,numel(findall(fig,'Tag','plate_forward')),1);
for tag=["included_observations","native_regression_observations","native_residual"]
    h=findall(fig,'Tag',tag);verifyEqual(testCase,numel(h),3);
    verifyEqual(testCase,sum(arrayfun(@(s)numel(s.XData),h)),6);
end
end

function testIndependentFitsShareAutomaticScalesAndClippingEvidence(testCase)
[first,review]=fixture();data=first.experimental;
data.Cp_mps(data.validMask)=3*data.Cp_mps(data.validMask);
second=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,first.physical);
original={first;second};reviews={review;review};
reviews{1}.repetitionId=repmat("1",numel(data.frequency_Hz),1);
reviews{2}.repetitionId=repmat("2",numel(data.frequency_Hz),1);
[fig,e]=plotAePlateFitDiagnostics(original,reviews,'DisplayMode',"robust",'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,e.nativeResults,original);
cp={first.experimental.Cp_mps(first.validMask);second.experimental.Cp_mps(second.validMask)};
verifyEqual(testCase,e.sharedPanelLimits.phaseSpeed_mps,resolveInversePhaseSpeedLimits(cp,'Mode',"robust"));
for k=1:2
    verifyEqual(testCase,e.repetitionEvidence{k}.display.limits,e.sharedPanelLimits.phaseSpeed_mps);
    verifyEqual(testCase,e.repetitionEvidence{k}.regressionDisplay.limits,e.sharedPanelLimits.regression_Pa);
    verifyEqual(testCase,e.repetitionEvidence{k}.residualDisplay.limits,e.sharedPanelLimits.residual_Pa);
end
[clipped,c]=plotAePlateFitDiagnostics(original,reviews,'PhaseSpeedLimits',[0 1], ...
    'RegressionLimits',[0 1],'ResidualLimits',[1e9 2e9],'Visible','off');
cleanup2=onCleanup(@()close(clipped));
for tag=["plate_dispersion","plate_regression","plate_residuals"]
    ax=findall(clipped,'Tag',tag);notes=string(ax.Title.String);
    verifyTrue(testCase,any(contains(notes,"Rep. 1: Data outside:")));
    verifyTrue(testCase,any(contains(notes,"Rep. 2: Data outside:")));
    edges=findall(ax,'-regexp','Tag','^offscale_');
    for k=1:numel(edges)
        verifyTrue(testCase,all(ismember(edges(k).YData,ylim(ax))));
        verifyNotEmpty(testCase,edges(k).UserData.originalYData);
    end
end
verifyEqual(testCase,c.nativeResults,original);
countNote=findall(clipped,'Tag','plate_observation_count');
verifyEqual(testCase,string(countNote.String),"Fitted observations: 8 / 16");
[complete,allEvidence]=plotAePlateFitDiagnostics(original,reviews,'Visible','off');
cleanup3=onCleanup(@()close(complete));
for k=1:2
    verifyEqual(testCase,allEvidence.repetitionEvidence{k}.observedClipping.outsideCount,0);
    verifyEqual(testCase,allEvidence.repetitionEvidence{k}.predictionClipping.outsideCount,0);
end
ax=findall(complete,'Tag','plate_regression');lines=findall(ax,'Tag','native_regression_line');
for k=1:numel(lines)
    verifyTrue(testCase,all(lines(k).YData>=ax.YLim(1)&lines(k).YData<=ax.YLim(2)));
end
end

function testMeasuredThicknessPresentationUsesSeparateNativeGeometries(testCase)
[native,review]=fixture();
data=native.experimental;
h=[.405;.406;.405;.406;NaN;NaN;.405;.406]*1e-3;
data.observationThickness_m=h;
physical=native.physical;
physical.alpha_Pa=300000;physical.gamma_Pa=150000;
for k=find(data.validMask(:))'
    one=physical;one.thickness_m=h(k);
    predicted=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion( ...
        data.frequency_Hz(k),one);
    data.Cp_mps(k)=predicted.phaseVelocity_mps;
end
native=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion( ...
    data,native.physical);
verifyTrue(testCase,native.diagnostics.physicalCandidate);
before=native;
[fig,e]=plotAePlateFitDiagnostics(native,review,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
verifyEqual(testCase,numel(e.forwardByThickness),2);
verifyEqual(testCase,numel(findall(fig,'Tag','plate_forward')),2);
for j=1:2
    group=e.forwardByThickness(j);
    measured=unique(h(native.validMask),'stable');
    verifyEqual(testCase,group.thickness_m,measured(j));
    physical=native.physical;
    physical.thickness_m=group.thickness_m;
    physical.alpha_Pa=native.alpha_Pa;physical.gamma_Pa=native.gamma_Pa;
    exact=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion( ...
        group.mode.frequency_Hz,physical);
    verifyEqual(testCase,group.mode,exact);
end
verifyTrue(testCase,contains(e.forwardStatus,"exact-thickness"));
layout=findall(fig,'-isa','matlab.graphics.layout.TiledChartLayout');
verifySubstring(testCase,string(layout.XLabel.String{2}),"per observation");
end

function testSourceAlignedPulseGlyphMaskAndHistoricReview(testCase)
[native,review]=fixture(); before=native;
review.modelSupportReference=review.modelAssumptionsJustification;
review=rmfield(review,'modelAssumptionsJustification');
rows=false(numel(native.validMask),1);rows([1,3])=true;
[fig,e]=plotAePlateFitDiagnostics(native,review, ...
    'DisplayObservationMask',rows,'Visible','off');
cleanup=onCleanup(@()close(fig));
verifyEqual(testCase,native,before);
verifyEqual(testCase,e.observations.included,native.validMask);
verifyEqual(testCase,e.displayedObservationMask,native.validMask & rows);
verifyEqual(testCase,e.provenance.modelAssumptionsJustification,review.modelSupportReference);
end

function [native,review]=fixture()
physical=struct('alpha_Pa',300000,'gamma_Pa',150000,'density_kgpm3',1070,'thickness_m',0.001);
f=[100;1000;3000;8000];
mode=lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion(f,physical);
data=struct('frequency_Hz',[f;0;Inf;2000;7000], ...
    'Cp_mps',[mode.phaseVelocity_mps;NaN;2;120;3], ...
    'validMask',[true(4,1);false(4,1)],'conditionId',"synthetic",'directionId',"axis1:left");
native=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(data,rmfield(physical,{'alpha_Pa','gamma_Pa'}));
assert(native.accepted);
review=struct('label',"Synthetic reviewed Plate fit",'material',"synthetic", ...
    'sourceReference',"synthetic request",'modelAssumptionsJustification',"Synthetic A0; no experimental validation", ...
    'repetitionId',["1";"2";"1";"2";"1";"2";"1";"2"], ...
    'sourceMasks',struct('valid_mask',[true(4,1);false(4,1)], ...
    'interpolated_mask',logical([0;0;0;0;0;0;1;0]), ...
    'extrapolated_mask',logical([0;0;0;0;0;0;0;1])));
end
