function batchResult = runOceInversionBatch(plan, family)
%RUNOCEINVERSIONBATCH Execute a list of independently reviewed OCE studies.
% PLAN.experimentRoot: machine-local experiment anchor.
% PLAN.oceRepositoryRoot: machine-local OCE code checkout.
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
n=numel(plan.cases);
cases=cell(n,1);outputs=strings(n,1);subexperiments=strings(n,1);
for j=1:n
    caseStudy=plan.cases(j);
    caseStudy.experimentRoot=string(plan.experimentRoot);
    caseStudy.saveResult=saveResult;
    caseStudy.exportFigure=exportFigure;
    caseStudy.showFigure=exportFigure;
    caseStudy.figureVisible=false;
    caseStudy.existingNativeResult=[];
    caseStudy.existingAssembly=[];
    if ~isfield(caseStudy,'reuseOnly'),caseStudy.reuseOnly=true;end
    if ~isfield(caseStudy,'graphicRequestedFrequency_Hz')
        caseStudy.graphicRequestedFrequency_Hz=[];
    end
    if ~isfield(caseStudy,'displayLabel'),caseStudy.displayLabel="";end
    if ~isfield(caseStudy,'displaySubtitle'),caseStudy.displaySubtitle="";end
    if ~isfield(caseStudy,'summaryFile'),caseStudy.summaryFile="";end
    caseStudy=resolveOceInversionPaths(caseStudy,family);
    outputs(j)=string(caseStudy.resultFile);
    subexperiments(j)=string(caseStudy.subexperimentId);
    cases{j}=caseStudy;
end
assert(numel(unique(lower(replace(outputs,"\\","/"))))==n, ...
    'lamb:batch:DuplicateOutput','Cases must use distinct output tags or relative folders.');
if execute
    for j=1:n
        if saveResult
            assert(~isfile(cases{j}.resultFile),'lamb:study:OutputExists', ...
                'Refusing batch overwrite: %s',cases{j}.resultFile);
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
results=cell(n,1);
if execute
    for j=1:n
        try
            results{j}=executeOceInversionStudy(cases{j},family,plan.oceRepositoryRoot);
            status(j)="completed";
        catch exception
            status(j)="failed";
            messages(j)=string(exception.identifier)+" | "+string(exception.message);
            if ~continueOnError,rethrow(exception);end
        end
    end
end
report=table((1:n)',subexperiments,outputs,status,messages, ...
    'VariableNames',{'caseIndex','subexperimentId','resultFile','status','message'});
batchResult=struct('family',family,'executed',execute,'report',report, ...
    'cases',{cases},'results',{results});
end
