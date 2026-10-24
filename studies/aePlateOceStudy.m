%% 1. Configure one reviewed condition (edit here, or supply study in the workspace).
% This script coordinates existing owners; it is not a model dispatcher.
% Initialize the reviewed OCE src path explicitly before running this study.
% Recovery requires OCE PR #146's exact-identity contract (including legacy rejection).
if ~exist('study','var')
    study=struct('experimentRoot',"",'summaryFile',"",'experimentId',"", ...
        'subexperimentId',"",'sampleId',"",'mode',"QH",'period_us',"", ...
        'repetitions',["1","2","3"],'conditionId',"",'condition',struct(), ...
        'scanAxisIndex',1,'direction',"left",'curve',"raw", ...
        'frequencySelection',"all",'frequency_Hz',[], ...
        'physical',struct('density_kgpm3',NaN,'thickness_m',NaN), ...
        'review',struct('mode',"A0",'thicknessPolicy',"explicit_constant_current_thickness", ...
            'thicknessSource',"",'thicknessJustification',"", ...
            'densityReference',"",'modelSupportReference',""), ...
        'fitOptions',struct(),'existingNativeResult',[],'existingAssembly',[], ...
        'resultFile',"",'reuseOnly',true,'saveResult',false, ...
        'showFigure',true,'graphicRequestedFrequency_Hz',[], ...
        'displayLabel',"",'displaySubtitle',"", ...
        'exportFigure',false,'figureFolder',"",'figureName',"");
end

%% 2. Recover individual products through OCE, then select literal acquisition identities.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);startup;
assert(any(study.mode==["QH","Pulse"]),'Select QH or Pulse explicitly.');
assert(isscalar(string(study.experimentId))&&strlength(study.experimentId)>0);
assert(isscalar(string(study.sampleId))&&strlength(study.sampleId)>0);
assert(~isempty(fieldnames(study.condition)),'Supply the mechanical condition explicitly.');
inputHashes=table();
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'Do not overwrite a historical result.');
    summaryHash=hashStudyFiles(string(study.summaryFile));
end
savedSummary=load(study.summaryFile,'experiment');
summary=savedSummary.experiment;
if study.saveResult
    inputFiles=[string(study.summaryFile);fullfile(study.experimentRoot,string(summary.source.index.result_file))];
    referenceParts=split(replace(string(summary.source.index.result_file),'\','/'),'/',2);
    subs=unique(referenceParts(:,2),'stable');
    for sub=subs(:)'
        [~,metadataFile]=oce.io.loadAcquisitionTable(study.experimentRoot,sub);
        inputFiles(end+1,1)=string(metadataFile); %#ok<SAGROW>
    end
    inputHashes=hashStudyFiles(inputFiles);
    assert(isequal(inputHashes(1,:),summaryHash),'lamb:study:InputsChanged','Summary changed while being read.');
end
recovered=oce.results.recoverSummaryObservations(study.experimentRoot,summary);
metadata=vertcat(recovered.acquisition_metadata);
selected=metadata.experiment_id==study.experimentId & metadata.sub_experiment==study.subexperimentId & ...
    metadata.sample_id==study.sampleId & ismember(metadata.rep_id,string(study.repetitions));
excitation="quasi_harmonic";if study.mode=="Pulse",excitation="pulse";end
selected=selected&metadata.excitation_type==excitation;
for key=string(fieldnames(study.condition))'
    expected=study.condition.(key);
    assert(ismember(key,string(metadata.Properties.VariableNames)),'Condition key is absent.');
    actual=metadata.(key);
    if isa(actual,'double')
        assert(isa(expected,'double')&&isscalar(expected), ...
            'Numeric conditions require an exact scalar double selector.');
        selected=selected&actual==expected;
    else
        assert((ischar(expected)||isstring(expected))&&isscalar(string(expected))&& ...
            ~ismissing(string(expected)),'Text conditions require a scalar literal text selector.');
        selected=selected&string(actual)==string(expected);
    end
end
if study.mode=="Pulse"
    assert(strlength(study.period_us)>0,'Supply the literal saved Pulse period.');
    selected=selected&metadata.period_us==study.period_us;
end
sources=recovered(selected);sourceMetadata=metadata(selected,:);
assert(~isempty(sources),'No acquisitions match the explicit condition.');
assert(all(ismember(string(study.repetitions),sourceMetadata.rep_id)),'A selected repetition is missing.');
if study.mode=="Pulse"
    assert(height(sourceMetadata)==numel(study.repetitions), ...
        'Select exactly one Pulse acquisition per repetition, period and condition.');
end
sourceFiles=string({sources.result_file})';

%% 3. Review the fixed mask on original observed Hz; no interpolation or band optimization.
frequency=cell(numel(sources),1);speed=frequency;bins=frequency;
ridge=frequency;interpolated=frequency;extrapolated=frequency;
sourceIndex=frequency;repetitionId=frequency;directionIndex=zeros(numel(sources),1);
for j=1:numel(sources)
    result=sources(j).scientific_result;identities=result.dispersion.directions;
    d=find([identities.scan_axis_index]==study.scanAxisIndex & string({identities.direction})==study.direction);
    assert(isscalar(d),'The signed direction is missing or ambiguous.');directionIndex(j)=d;
    kf=result.dispersion.estimators.kf_ridge;one=kf.directions(d);
    index=(1:numel(kf.frequency_axis_hz))';
    if study.mode=="QH"
        index=one.target_selection.selected_bin_index;
        validateattributes(index,{'double'},{'scalar','integer','finite','positive'});
    end
    f=kf.frequency_axis_hz(:);cp=one.phase_speed_curve.(study.curve+"_phase_speed_m_per_s")(:);
    frequency{j}=f(index);speed{j}=cp(index);bins{j}=index(:);
    ridge{j}=one.ridge.valid_mask(index);ridge{j}=ridge{j}(:);
    interpolated{j}=one.ridge.interpolated_mask(index);interpolated{j}=interpolated{j}(:);
    extrapolated{j}=one.ridge.extrapolated_mask(index);extrapolated{j}=extrapolated{j}(:);
    sourceIndex{j}=repmat(j,numel(index),1);
    repetitionId{j}=repmat(string(sourceMetadata.rep_id(j)),numel(index),1);
end
frequency=vertcat(frequency{:});speed=vertcat(speed{:});bins=vertcat(bins{:});
ridge=vertcat(ridge{:});interpolated=vertcat(interpolated{:});extrapolated=vertcat(extrapolated{:});
sourceIndex=vertcat(sourceIndex{:});repetitionId=vertcat(repetitionId{:});
qualityMask=ridge&~interpolated&~extrapolated&isfinite(frequency)&frequency>0&isfinite(speed)&speed>0;
frequencySelectionMapping=table();graphicSamplingMapping=table();pulseMapping=table();
if study.frequencySelection=="explicit"
    validateattributes(study.frequency_Hz,{'double'},{'vector','nonempty','finite','positive'});
end
if study.mode=="Pulse"
    requested=zeros(0,1);
    if study.frequencySelection=="explicit",requested=study.frequency_Hz(:);end
    graphicRequested=zeros(0,1);
    if study.showFigure
        graphicRequested=study.graphicRequestedFrequency_Hz(:);
        if isempty(graphicRequested)&&isfield(summary,'summary')&&isfield(summary.summary,'dispersion_sampling')
            graphicRequested=summary.summary.dispersion_sampling.requested_frequency_hz(:);
        end
        assert(~isempty(graphicRequested),'Supply explicit Pulse graphic frequencies when OCE sampling is absent.');
        validateattributes(graphicRequested,{'double'},{'vector','finite','positive'});
    end
    requested=unique([requested;graphicRequested],'stable');
    mapping=cell(numel(requested)*numel(sources),7);mapRow=0;
    persisted=[];
    if isfield(summary,'summary')&&isfield(summary.summary,'dispersion_sampling')
        persisted=summary.summary.dispersion_sampling;
    end
    for j=1:numel(sources)
        rows=find(sourceIndex==j);f=frequency(rows);
        for k=1:numel(requested)
            if requested(k)<min(f)||requested(k)>max(f)
                mapRow=mapRow+1;mapping(mapRow,:)={j,string(sourceMetadata.rep_id(j)),requested(k), ...
                    NaN,NaN,false,"outside_observed_domain"};
                continue
            end
            [~,index]=min(abs(f-requested(k)));origin="nearest_original_bin";
            if ~isempty(persisted)
                location=find(persisted.requested_frequency_hz==requested(k));
                if isscalar(location)
                    % OCE indices belong to its aligned axis; resolve saved Hz on this source.
                    [found,originalIndex]=ismember(persisted.selected_frequency_hz(location),f);
                    if found,index=originalIndex;origin="OCE_persisted";end
                end
            end
            % Choose on the complete original axis, never on its valid subset.
            row=rows(index);
            mapRow=mapRow+1;mapping(mapRow,:)={j,string(sourceMetadata.rep_id(j)),requested(k), ...
                frequency(row),bins(row),qualityMask(row),origin};
        end
    end
    pulseMapping=cell2table(mapping(1:mapRow,:),'VariableNames', ...
        {'sourceIndex','repetitionId','requestedFrequency_Hz','observedFrequency_Hz', ...
        'sourceBinIndex','qualityValid','mappingSource'});
    graphicSamplingMapping=pulseMapping(ismember(pulseMapping.requestedFrequency_Hz,graphicRequested),:);
end
switch study.frequencySelection
    case "all"
        frequencyMask=true(size(frequency));
    case "interval"
        validateattributes(study.frequency_Hz,{'double'},{'vector','numel',2,'finite','positive'});
        assert(study.frequency_Hz(1)<=study.frequency_Hz(2));
        frequencyMask=frequency>=study.frequency_Hz(1)&frequency<=study.frequency_Hz(2);
    case "explicit"
        requested=study.frequency_Hz(:);frequencyMask=false(size(frequency));mapping=cell(numel(requested)*numel(sources),7);mapRow=0;
        if study.mode=="QH"
            registered=sourceMetadata.frequency_Hz;
            if isnumeric(registered),registered=double(registered(:));
            else,registered=str2double(string(registered));end
            for k=1:numel(requested)
                rows=find(registered(sourceIndex)==requested(k));
                if isempty(rows)
                    mapRow=mapRow+1;mapping(mapRow,:)={NaN,"",requested(k),NaN,NaN,false,"unrecorded_physical_frequency"};
                end
                for row=rows'
                    frequencyMask(row)=true;
                    mapRow=mapRow+1;mapping(mapRow,:)={sourceIndex(row),repetitionId(row),requested(k), ...
                        frequency(row),bins(row),qualityMask(row),"registered_QH_frequency"};
                end
            end
            frequencySelectionMapping=cell2table(mapping(1:mapRow,:),'VariableNames', ...
                {'sourceIndex','repetitionId','requestedFrequency_Hz','observedFrequency_Hz', ...
                'sourceBinIndex','qualityValid','mappingSource'});
        else
            frequencySelectionMapping=pulseMapping(ismember(pulseMapping.requestedFrequency_Hz,requested),:);
            frequencyMask=ismember([sourceIndex,bins], ...
                [frequencySelectionMapping.sourceIndex,frequencySelectionMapping.sourceBinIndex],'rows');
        end
    otherwise
        error('lamb:study:FrequencySelection','Use all, interval or explicit.');
end
validMask=qualityMask&frequencyMask;
observationReview=table((1:numel(frequency))',sourceIndex,bins,repetitionId,frequency,speed, ...
    ridge,interpolated,extrapolated,qualityMask,frequencyMask,validMask, ...
    'VariableNames',{'row','sourceIndex','sourceBinIndex','repetitionId','frequency_Hz','Cp_mps', ...
    'ridgeValid','interpolated','extrapolated','qualityMask','frequencySelectionMask','validMask'});
assert(any(validMask),'The reviewed fitting mask is empty.');

%% 4. Prepare one request; QH retains its target/physical-frequency contract.
if study.mode=="QH"
    observations=table([sources.summary_source_row]',bins,validMask, ...
        'VariableNames',{'sourceRow','binIndex','include'});
    selection=struct('experimentId',study.experimentId,'subexperimentId',study.subexperimentId, ...
        'sampleId',study.sampleId,'conditionId',study.conditionId,'condition',study.condition, ...
        'scanAxisIndex',study.scanAxisIndex,'direction',study.direction,'curve',study.curve, ...
        'metadataReference',string(study.summaryFile),'observations',observations);
    assembly=prepareOceQhFitObservations(recovered,selection);
else
    prepared=cell(numel(sources),1);
    for j=1:numel(sources)
        selection=struct('directionIndex',directionIndex(j),'estimator',"kf_ridge", ...
            'curve',study.curve,'validMask',validMask(sourceIndex==j));
        metadata=struct('conditionId',study.conditionId, ...
            'repetitionId',str2double(string(sourceMetadata.rep_id(j))), ...
            'loadingCondition',study.condition,'sourceResultFile',sources(j).result_file, ...
            'metadataReference',string(study.summaryFile),'acquisitionMetadata',sourceMetadata(j,:), ...
            'recoveryProvenance',sources(j).provenance);
        prepared{j}=prepareOceFitObservations(sources(j).scientific_result,selection,metadata);
    end
    f=cellfun(@(p)p.experimental.frequency_Hz,prepared,'UniformOutput',false);
    cp=cellfun(@(p)p.experimental.Cp_mps,prepared,'UniformOutput',false);
    mask=cellfun(@(p)p.experimental.validMask,prepared,'UniformOutput',false);
    experimental=struct('frequency_Hz',vertcat(f{:}),'Cp_mps',vertcat(cp{:}), ...
        'validMask',vertcat(mask{:}),'conditionId',study.conditionId, ...
        'directionId',prepared{1}.experimental.directionId);
    assert(all(cellfun(@(p)p.experimental.directionId==experimental.directionId,prepared)));
    angles=cellfun(@(p)p.experimental.source.scanAxisAngle_deg,prepared);
    assert(all(angles==angles(1)),'Do not pool differing physical scan-axis angles.');
    assembly=struct('experimental',experimental,'prepared',{prepared}, ...
        'lineage',observationReview(:,{'row','sourceIndex','sourceBinIndex','repetitionId'}), ...
        'sourceResultFiles',sourceFiles);
end
experimental=assembly.experimental;
assert(isequaln(experimental.frequency_Hz,frequency)&&isequaln(experimental.Cp_mps,speed));
assert(isequal(experimental.validMask,validMask));
assert(study.mode=="QH"||~isfield(experimental,'independentFrequencyGroupId'));

%% 5. Review physical inputs explicitly; one scalar policy for both acquisition modes.
physical=study.physical;review=study.review;fitOptions=study.fitOptions;
assert(review.mode=="A0"&&review.thicknessPolicy=="explicit_constant_current_thickness");
for name=["density_kgpm3","thickness_m"]
    validateattributes(physical.(name),{'double'},{'scalar','finite','real','positive'});
end
for name=["thicknessSource","thicknessJustification","densityReference","modelSupportReference"]
    assert(isscalar(string(review.(name)))&&strlength(strtrim(string(review.(name))))>0, ...
        'Physical inputs need explicit sources and justification.');
end
% OCT values remain observations; the study never silently selects another thickness.

%% 6. Reuse only an identical request; otherwise call the maintained Plate owner once.
existing=study.existingNativeResult;existingAssembly=study.existingAssembly;
if isempty(existing)&&strlength(study.resultFile)>0&&isfile(study.resultFile)
    saved=load(study.resultFile,'nativeResult','assembly');
    existing=saved.nativeResult;existingAssembly=saved.assembly;
end
reusedResult=false;
if ~isempty(existing)
    if isempty(fieldnames(fitOptions)),fitOptions=existing.options;end
    same=isequaln(existing.physical,physical)&&isequaln(existing.options,fitOptions);
    for name=string(fieldnames(experimental))'
        same=same&&isfield(existing.experimental,name)&&isequaln(existing.experimental.(name),experimental.(name));
    end
    same=same&&~isempty(existingAssembly);
    if ~isempty(existingAssembly)
        if isfield(existingAssembly,'sourceResultFiles')
            recordedFiles=string(existingAssembly.sourceResultFiles(:));
        else
            recordedFiles=string({existingAssembly.lineage.resultFile})';
        end
        same=same&&isequal(recordedFiles,sourceFiles);
    end
    if study.mode=="QH"
        % Coverage is owned by fitOceQhPrestressedPlate. Reuse its recorded physical inputs,
        % never reconstruct a second grouping implementation in this script.
        same=same&&~isempty(existingAssembly)&& ...
            isequaln(existingAssembly.physicalFrequency_Hz,assembly.physicalFrequency_Hz)&& ...
            isequaln(existingAssembly.requestedTargetFrequency_Hz,assembly.requestedTargetFrequency_Hz);
    else
        same=same&&~isfield(existing.experimental,'independentFrequencyGroupId');
    end
    if same,nativeResult=existing;reusedResult=true;end
end
assert(reusedResult||~study.reuseOnly,'lamb:study:RequestMismatch', ...
    'No identical reviewed result is available. Inspect observationReview and physical inputs before enabling a new fit.');
if ~reusedResult
    if study.mode=="QH"
        outcome=fitOceQhPrestressedPlate(assembly,physical,review,fitOptions);
        nativeResult=outcome.nativeResult;
    else
        nativeResult=lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(experimental,physical,fitOptions);
    end
end
assert(isequal(nativeResult.validMask,validMask));
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'Do not overwrite a historical result.');
    assert(isequal(hashStudyFiles(inputHashes.path),inputHashes), ...
        'lamb:study:InputsChanged','An OCE input changed after recovery; do not persist this study.');
    % Small configuration only: arrays, physical inputs and reviews already have owners below.
    selectionFields={'experimentRoot','summaryFile','experimentId','subexperimentId','sampleId', ...
        'mode','period_us','repetitions','conditionId','condition','scanAxisIndex','direction', ...
        'curve','frequencySelection','frequency_Hz','graphicRequestedFrequency_Hz'};
    effectiveSelection=struct();
    for field=selectionFields,effectiveSelection.(field{1})=study.(field{1});end
    if study.mode=="Pulse"&&study.showFigure
        effectiveSelection.graphicRequestedFrequency_Hz=graphicRequested;
    end
    oceRoot=fileparts(fileparts(fileparts(fileparts(which('oce.results.recoverSummaryObservations')))));
    studyRecord=struct('selection',effectiveSelection, ...
        'matlabVersion',string(version),'matlabRelease',string(version('-release')), ...
        'code',struct('Lamb',studyRepositoryState(projectRoot),'OCE',studyRepositoryState(oceRoot)), ...
        'inputFiles',inputHashes,'numericallyReused',reusedResult, ...
        'provenanceScope',"current_input_bytes_unchanged_during_this_study", ...
        'historicalProcessingContentVerified',false);
    save(study.resultFile,'studyRecord','nativeResult','assembly','physical','review', ...
        'observationReview','frequencySelectionMapping','graphicSamplingMapping','-v7.3');
end

fprintf('AE Plate: %d selected rows; reused=%d; alpha=%.15g Pa; gamma=%.15g Pa; RMSE=%.15g Pa; numerical accepted=%d\n', ...
    nnz(validMask),reusedResult,nativeResult.alpha_Pa,nativeResult.gamma_Pa,nativeResult.regressionRMSE_Pa,nativeResult.accepted);

%% 7. Sample graphic bins independently and render the unchanged native result.
graphicFrequency=[];graphicMask=validMask;
if study.showFigure
    if study.mode=="Pulse"
        graphicFrequency=unique(graphicSamplingMapping.observedFrequency_Hz( ...
            isfinite(graphicSamplingMapping.observedFrequency_Hz)));
        graphicMask=validMask&ismember([sourceIndex,bins], ...
            [graphicSamplingMapping.sourceIndex,graphicSamplingMapping.sourceBinIndex],'rows');
        assert(isequal(validMask&ismember(frequency,graphicFrequency),graphicMask), ...
            'Graphic frequencies collide across different source grids; review the selected original bins.');
    end
    reference=string(study.resultFile);if strlength(reference)==0,reference="Reviewed in-memory native request";end
    provenance=struct('label',study.displayLabel,'displayLabel',study.displayLabel, ...
        'displaySubtitle',study.displaySubtitle,'material',string(sourceMetadata.material(1)), ...
        'sourceReference',reference,'originalResultReferences',sourceFiles, ...
        'modelSupportReference',review.modelSupportReference,'physicalReview',review, ...
        'repetitionId',repetitionId,'sourceMasks',struct('valid_mask',ridge, ...
        'interpolated_mask',interpolated,'extrapolated_mask',extrapolated));
    [fig,figureEvidence]=plotAePlateFitDiagnostics(nativeResult,provenance, ...
        'DisplayMode',"robust",'DisplayFrequency_Hz',graphicFrequency,'Visible','on');
    drawnow;
    if study.exportFigure
        assert(isfolder(study.figureFolder)&&strlength(study.figureName)>0);
        output=fullfile(study.figureFolder,study.figureName);
        assert(~isfile(output+".fig")&&~isfile(output+".png"),'Do not overwrite historical figures.');
        savefig(fig,output+".fig");exportgraphics(fig,output+".png",'Resolution',96);
    end
end

function hashes=hashStudyFiles(paths)
% Fingerprint inputs before recovery and again at persistence, without loading MAT schemas.
paths=unique(string(paths(:)),'stable');bytes=zeros(numel(paths),1);sha256=strings(numel(paths),1);
for k=1:numel(paths)
    fid=fopen(paths(k),'rb');
    assert(fid>=0,'lamb:study:UnreadableInput','Cannot hash input: %s',paths(k));
    closeFile=onCleanup(@() fclose(fid));
    digest=java.security.MessageDigest.getInstance('SHA-256');
    while ~feof(fid)
        chunk=fread(fid,1024*1024,'*uint8');bytes(k)=bytes(k)+numel(chunk);digest.update(chunk);
    end
    sha256(k)=lower(string(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[])));
    clear closeFile
end
hashes=table(paths,bytes,sha256,'VariableNames',{'path','bytes','sha256'});
end

function state=studyRepositoryState(root)
% Git describes the code used now, never the historical producer of a PhaseSpeed file.
prefix=sprintf('git --no-optional-locks -c safe.directory="%s" -c core.quotepath=false -C "%s" ',root,root);
[headStatus,head]=system([prefix 'rev-parse HEAD']);
[statusCode,status]=system([prefix 'status --porcelain=v1 --untracked-files=all']);
state=struct('root',string(root),'commit',strtrim(string(head)), ...
    'status',string(status),'available',headStatus==0&&statusCode==0);
if ~state.available,state.commit="unknown";end
end
