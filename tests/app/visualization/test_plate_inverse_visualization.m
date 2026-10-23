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
    'sourceReference',"synthetic request",'modelSupportReference',"Synthetic A0; no experimental validation", ...
    'repetitionId',["1";"2";"1";"2";"1";"2";"1";"2"], ...
    'sourceMasks',struct('valid_mask',[true(4,1);false(4,1)], ...
    'interpolated_mask',logical([0;0;0;0;0;0;1;0]), ...
    'extrapolated_mask',logical([0;0;0;0;0;0;0;1])));
end
