function inputs = prepareOceStudyObservations(study)
%PREPAREOCESTUDYOBSERVATIONS Select original observations for the manual studies.
% Study-local coordination, not a translator or scientific schema. OCE owns
% recovery; the existing integration APIs own request preparation. Plate and RL
% share exact acquisition selection and frequency mappings, never model policy.
%% 2. Recover individual products through OCE, then select literal acquisition identities.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
assert(any(study.mode==["QH","Pulse"]),'Select QH or Pulse explicitly.');
assert(isscalar(string(study.experimentId))&&strlength(study.experimentId)>0);
assert(isscalar(string(study.sampleId))&&strlength(study.sampleId)>0);
assert(~isempty(fieldnames(study.condition)),'Supply the mechanical condition explicitly.');
inputHashes=table();
if study.saveResult
    assert(strlength(study.resultFile)>0&&~isfile(study.resultFile),'lamb:study:OutputExists','Do not overwrite a historical result.');
    before=oceStudyProvenance(string(study.summaryFile),projectRoot);
    summaryHash=before.inputFiles;
end
savedSummary=load(study.summaryFile,'experiment');
summary=savedSummary.experiment;
if study.saveResult
    inputFiles=[string(study.summaryFile);fullfile(study.experimentRoot,string(summary.source.index.result_file))];
    referenceParts=split(replace(string(summary.source.index.result_file),'\','/'),'/',2);
    subs=unique(referenceParts(:,2),'stable');
    for sub=subs(:)'
        [~,metadataFile]=oce.io.loadAcquisitionTable(study.experimentRoot,sub);
        inputFiles(end+1,1)=string(metadataFile); %#ok<AGROW>
    end
    before=oceStudyProvenance(inputFiles,projectRoot);
    inputHashes=before.inputFiles;
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
    if study.estimator=="phase_gradient"
        assert(study.mode=="QH",'lamb:study:EstimatorMode','Phase-gradient requires a recorded QH target.');
        gradient=result.dispersion.estimators.phase_gradient;
        assert(gradient.enabled,'lamb:study:EstimatorUnavailable','The recorded phase-gradient estimator is unavailable.');
        frequency{j}=double(result.dispersion.target_frequency.requested_hz);
        speed{j}=double(gradient.directions(d).phase_speed_m_per_s);
        bins{j}=NaN;ridge{j}=gradient.directions(d).status=="valid";
        interpolated{j}=false;extrapolated{j}=false;
        sourceIndex{j}=j;repetitionId{j}=string(sourceMetadata.rep_id(j));
        continue
    end
    assert(study.estimator=="kf_ridge",'Select kf_ridge or phase_gradient.');
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
if isfield(study,'observationMask')&&~isempty(study.observationMask)
    validateattributes(study.observationMask,{'logical'},{'vector','numel',numel(frequency)});
    validMask=study.observationMask(:);
    assert(~any(validMask&~frequencyMask),'lamb:study:MaskFrequencyMismatch', ...
        'An explicit mask must respect the reviewed frequency selection.');
end
observationReview=table((1:numel(frequency))',sourceIndex,bins,repetitionId,frequency,speed, ...
    ridge,interpolated,extrapolated,qualityMask,frequencyMask,validMask, ...
    'VariableNames',{'row','sourceIndex','sourceBinIndex','repetitionId','frequency_Hz','Cp_mps', ...
    'ridgeValid','interpolated','extrapolated','qualityMask','frequencySelectionMask','validMask'});
assert(any(validMask),'The reviewed fitting mask is empty.');

%% 4. Prepare one request; QH retains its target/physical-frequency contract.
if study.mode=="QH"&&study.estimator=="kf_ridge"
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
        selection=struct('directionIndex',directionIndex(j),'estimator',study.estimator, ...
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
assert(~isfield(experimental,'independentFrequencyGroupId'));


inputs=struct('assembly',assembly,'observationReview',observationReview, ...
    'frequencySelectionMapping',frequencySelectionMapping, ...
    'graphicSamplingMapping',graphicSamplingMapping,'sourceMetadata',sourceMetadata, ...
    'sourceResultFiles',sourceFiles,'inputHashes',inputHashes);
end
