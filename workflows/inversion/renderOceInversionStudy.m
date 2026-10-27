function [fig,figureEvidence,figurePaths] = renderOceInversionStudy(study, inputs, nativeResult, review, family)
%RENDEROCEINVERSIONSTUDY Render original OCE rows without changing fit masks.
fig=[];figureEvidence=struct();figurePaths=struct();
if ~study.showFigure,return;end
review=normalizeInverseProvenance(review);
experimental=inputs.assembly.experimental;
r=inputs.observationReview;
displayRows=[];
if study.excitationMode=="Pulse"
    mapping=inputs.graphicSamplingMapping;
    % Row identities, not shared floating-point Hz, own Pulse glyph selection.
    displayRows=ismember([r.sourceIndex,r.sourceBinIndex], ...
        [mapping.sourceIndex,mapping.sourceBinIndex],'rows');
    assert(numel(displayRows)==numel(experimental.frequency_Hz), ...
        'lamb:study:GraphicMapping','Graphic rows must align with source observations.');
end
label=string(study.displayLabel);
if strlength(strtrim(label))==0
    label=string(study.sampleId)+" | "+string(study.subexperimentId)+ ...
        " | axis "+string(study.scanAxisIndex)+" "+string(study.direction);
    label=replace(label,"_","\_"); % Preserve literal IDs under the native TeX title interpreter.
end
reference=string(study.resultFile);
if ~study.saveResult,reference="Reviewed in-memory native request";end
provenance=struct('label',label, ...
    'material',string(inputs.sourceMetadata.material(1)), ...
    'sourceReference',reference,'originalResultReferences',inputs.sourceResultFiles, ...
    'modelAssumptionsJustification',review.modelAssumptionsJustification,'physicalReview',review, ...
    'repetitionId',r.repetitionId);
% Empty overrides leave the native model title/subtitle intact.
if strlength(strtrim(string(study.displayLabel)))>0
    provenance.displayLabel=string(study.displayLabel);
end
if strlength(strtrim(string(study.displaySubtitle)))>0
    provenance.displaySubtitle=string(study.displaySubtitle);
end
visible="off";
if ~isfield(study,'figureVisible')||study.figureVisible
    visible="on";
end
if family=="RayleighLamb"
    [fig,figureEvidence]=plotRlFitDiagnostics(nativeResult,provenance, ...
        'DisplayObservationMask',displayRows,'Visible',visible);
else
    provenance.sourceMasks=struct('valid_mask',r.ridgeValid, ...
        'interpolated_mask',r.interpolated,'extrapolated_mask',r.extrapolated);
    [fig,figureEvidence]=plotAePlateFitDiagnostics(nativeResult,provenance, ...
        'DisplayMode',"robust",'DisplayFrequency_Hz',graphicHz,'Visible',visible);
end
if visible=="on",drawnow;end
if study.exportFigure
    figurePaths=saveInverseFigure(fig,study.figureFolder,study.figureName);
end
if visible=="off",close(fig);fig=[];end
end
