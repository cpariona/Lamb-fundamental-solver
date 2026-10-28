function batchResult = runOceInversionBatch(plan, family)
%RUNOCEINVERSIONBATCH Execute a list of independently reviewed OCE studies.
% PLAN.experimentRoot: machine-local experiment anchor.
% PLAN.oceRepositoryRoot: machine-local OCE code checkout.
% PLAN.inversionsRoot: optional absolute output root; defaults to a sibling
%   OCE_Inversions folder alongside the supplied experiment directory.
% PLAN.cases: scalar struct or struct array, each with exact observation,
% model, frequency, physical-review and optional outputRelativeFolder choices.
% PLAN.execute: false (default) returns read-only output plan without fitting.
% PLAN.saveResult, PLAN.exportFigure: write flags, default true only on execute.
% PLAN.continueOnError: false (default) stops rather than hiding failures.
% The same executeOceInversionStudy owner runs one case for human/batch callers.
assert(isstruct(plan)&&isscalar(plan)&&isfield(plan,'cases')&& ...
    isstruct(plan.cases)&&~isempty(plan.cases), ...
    'lamb:batch:InvalidPlan','A nonempty reviewed struct array is required.');
family=string(family);
assert(any(family==["RayleighLamb","Plate"]),'lamb:batch:Model','Unknown model.');
execute=false;
if isfield(plan,'execute'),execute=plan.execute;end
validateattributes(execute,{'logical'},{'scalar'});
saveResult=true;exportFigure=true;continueOnError=false;
if isfield(plan,'saveResult'),saveResult=plan.saveResult;end
if isfield(plan,'exportFigure'),exportFigure=plan.exportFigure;end
if isfield(plan,'continueOnError'),continueOnError=plan.continueOnError;end
for flag={saveResult,exportFigure,continueOnError}
    validateattributes(flag{1},{'logical'},{'scalar'});
end
assert(isfield(plan,'experimentRoot')&&isfield(plan,'oceRepositoryRoot'), ...
    'lamb:batch:Roots','Supply experiment and OCE source repository roots.');
if isfield(plan,'inversionsRoot') && ~isempty(plan.inversionsRoot) && ...
        ~(isscalar(string(plan.inversionsRoot)) && ...
          strlength(strtrim(string(plan.inversionsRoot)))==0)
    inversionsRoot=string(plan.inversionsRoot);
else
    sourceRoot=replace(string(plan.experimentRoot),char(92),"/");
    while endsWith(sourceRoot,"/") && strlength(sourceRoot)>1
        sourceRoot=extractBefore(sourceRoot,strlength(sourceRoot));
    end
    inversionsRoot=fullfile(string(fileparts(char(sourceRoot))),"OCE_Inversions");
end
n=numel(plan.cases);
cases=cell(n,1);outputs=strings(n,1);subexperiments=strings(n,1);
for j=1:n
    caseStudy=plan.cases(j);
    caseStudy.experimentRoot=string(plan.experimentRoot);
    caseStudy.inversionsRoot=inversionsRoot;
    caseStudy.saveResult=saveResult;
    caseStudy.exportFigure=exportFigure;
    caseStudy.showFigure=exportFigure;
    caseStudy.figureVisible=false;
    caseStudy.existingNativeResult=[];
    caseStudy.existingAssembly=[];
    % plan.execute=true is explicit authorization for a new fit unless the
    % batch itself explicitly requests reuse-only for every case.
    caseStudy.reuseOnly=~execute;
    if isfield(plan,'reuseOnly')
        validateattributes(plan.reuseOnly,{'logical'},{'scalar'});
        caseStudy.reuseOnly=plan.reuseOnly;
    end
    assert(isfield(caseStudy,'fitFrequencySelection') && ...
        any(string(caseStudy.fitFrequencySelection)==["interval","explicit","all"]), ...
        'lamb:batch:BandReview','Each case requires an explicit frequency selection.');
    if string(caseStudy.fitFrequencySelection)=="all"
        assert(isfield(caseStudy,'fullBandReviewed') && ...
            isequal(caseStudy.fullBandReviewed,true), ...
            'lamb:batch:BandReview', ...
            'Using all frequencies requires an explicit reviewed approval per case.');
    else
        assert(isfield(caseStudy,'fitFrequency_Hz')&&~isempty(caseStudy.fitFrequency_Hz), ...
            'lamb:batch:BandReview','Provide a reviewed frequency interval or explicit bins.');
    end
    if ~isfield(caseStudy,'plotTargetFrequency_Hz')
        caseStudy.plotTargetFrequency_Hz=[];
    end
    if ~isfield(caseStudy,'displayLabel'),caseStudy.displayLabel="";end
    if ~isfield(caseStudy,'displaySubtitle'),caseStudy.displaySubtitle="";end
    if ~isfield(caseStudy,'summaryFile'),caseStudy.summaryFile="";end
    caseStudy=resolveOceInversionPaths(caseStudy,family);
    outputs(j)=string(caseStudy.resultFile);
    subexperiments(j)=string(caseStudy.subexperimentId);
    cases{j}=caseStudy;
end
normalizedOutputs=lower(replace(outputs,char(92),"/"));
assert(numel(unique(normalizedOutputs))==n, ...
    'lamb:batch:DuplicateOutput', ...
    'Cases must use distinct output tags or relative folders.');
if execute
    for j=1:n
        if saveResult
            if cases{j}.reuseOnly
                assert(isfile(cases{j}.resultFile),'lamb:study:MissingReuseResult', ...
                    'Reuse-only batch requires an existing inversion MAT.');
            else
                assert(~isfile(cases{j}.resultFile),'lamb:study:OutputExists', ...
                    'Refusing batch overwrite: %s',cases{j}.resultFile);
            end
            assert(~isfile(fullfile(cases{j}.figureFolder,"inversion_failure.mat")), ...
                'lamb:study:OutputExists','A failure record already exists for this case.');
        end
        if exportFigure
            assert(~isfile(fullfile(cases{j}.figureFolder,"inversion.fig"))&& ...
                ~isfile(fullfile(cases{j}.figureFolder,"inversion.tif")), ...
                'lamb:study:OutputExists','Refusing batch overwrite of figures.');
        end
    end
end
status=repmat("planned",n,1);
messages=strings(n,1);
selectedRows=nan(n,1);
metricValue=nan(n,1);
metricUnit=strings(n,1);
nativeAccepted=nan(n,1); % Plate native acceptance only; NaN for RL.
results=cell(n,1);
failureFiles=strings(n,1);
if execute
    for j=1:n
        try
            [results{j},executionError]=executeOceInversionStudy( ...
                cases{j},family,plan.oceRepositoryRoot);
            native=results{j}.nativeResult;
            selectedRows(j)=nnz(native.validMask);
            if family=="RayleighLamb"
                metricValue(j)=native.metrics.RMSE;
                metricUnit(j)="m/s";
            else
                metricValue(j)=native.regressionRMSE_Pa;
                metricUnit(j)="Pa";
                nativeAccepted(j)=double(native.accepted);
            end
            if ~isempty(executionError),rethrow(executionError);end
            status(j)="completed";
        catch exception
            status(j)="failed";
            if ~isempty(results{j}),status(j)="partial";end
            messages(j)=string(exception.identifier)+" | "+string(exception.message);
            if saveResult
                try
                    failureFiles(j)=persistFailedCase(cases{j},family,exception,results{j});
                catch archiveError
                    warning('lamb:batch:FailurePersistence', ...
                        'Could not persist failed case %d: %s',j,archiveError.message);
                end
            end
            if ~continueOnError,rethrow(exception);end
        end
    end
end
report=table((1:n)',subexperiments,outputs,status,selectedRows, ...
    metricValue,metricUnit,nativeAccepted,messages,failureFiles, ...
    'VariableNames',{'caseIndex','subexperimentId','resultFile','status', ...
    'selectedObservations','nativeRMSE','nativeRMSEUnit','plateNumericalAccepted', ...
    'message','failureRecordFile'});
batchResult=struct('family',family,'executed',execute,'report',report, ...
    'cases',{cases},'results',{results});
end

function path=persistFailedCase(study,family,exception,result)
% Store the error separately, retaining completed-stage evidence for partial
% success. Never overwrite a native result or an earlier failure record.
path=fullfile(study.figureFolder,"inversion_failure.mat");
assert(~isfile(path),'lamb:study:OutputExists','A failure record already exists.');
keys=["experimentId","subexperimentId","sampleId","excitationMode","period_us", ...
    "repetitions","conditionId","condition","scanAxisIndex","direction", ...
    "estimator","curve","fitFrequencySelection","fitFrequency_Hz", ...
    "fullBandReviewed","observationMask","thicknessPolicy", ...
    "thicknessReferenceSourceIndex","fitConfig","physical","fitOptions", ...
    "review","summaryRelativeFile","resolvedSummaryRelativeFile", ...
    "outputRelativeFolder","resolvedOutputRelativeFolder", ...
    "resolvedOutputBase","outputTag"];
request=struct();
for name=keys
    if isfield(study,name),request.(name)=study.(name);end
end
[~,stackName,stackExt]=cellfun(@fileparts,{exception.stack.file}, ...
    'UniformOutput',false);
message=replace(string(exception.message),string(study.experimentRoot), ...
    "<experimentRoot>");
if isfield(study,'inversionsRoot')
    message=replace(message,string(study.inversionsRoot),"<inversionsRoot>");
end
failureRecord=struct('family',string(family),'request',request, ...
    'utcTime',datetime('now','TimeZone','UTC'), ...
    'errorId',string(exception.identifier), ...
    'errorMessage',message, ...
    'stackFunctions',string({exception.stack.name})', ...
    'stackFiles',string(strcat(stackName,stackExt))', ...
    'stackLines',[exception.stack.line]');
failureRecord.completedThrough="none";
failureRecord.nativeResultRelativeFile="";
failureRecord.nativeResultBase=study.resolvedOutputBase;
if ~isempty(result)
    failureRecord.completedThrough=result.completedThrough;
    if result.completedThrough=="persistence" && isfile(study.resultFile)
        failureRecord.nativeResultRelativeFile= ...
            fullfile(study.resolvedOutputRelativeFolder,"inversion.mat");
    end
end
folder=fileparts(path);
if ~isfolder(folder),mkdir(folder);end
save(path,'failureRecord','-v7.3');
end
