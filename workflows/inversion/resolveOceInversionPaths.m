function study = resolveOceInversionPaths(study, family)
%RESOLVEOCEINVERSIONPATHS Resolve source-relative inputs and rooted outputs.
% Single-study outputs remain inside experimentRoot. Batch callers may pass
% inversionsRoot to save outside the experiment while preserving relative paths.
family=string(family);
assert(isscalar(family)&&any(family==["RayleighLamb","Plate"]), ...
    'lamb:study:ModelFamily','Select RayleighLamb or Plate.');
root=string(study.experimentRoot);
assert(isscalar(root)&&~ismissing(root)&&strlength(strtrim(root))>0&&isfolder(root), ...
    'lamb:study:ExperimentRoot','Supply an existing experiment root.');
sub=safePart(study.subexperimentId);
if isfield(study,'summaryRelativeFile') && ...
        strlength(string(study.summaryRelativeFile))>0
    summaryRel=safeRelative(study.summaryRelativeFile);
elseif isfield(study,'resolvedSummaryRelativeFile') && ...
        isfield(study,'resolvedSubexperimentId') && ...
        string(study.resolvedSubexperimentId)==sub
    % Batch preflight and execution share this reviewed relative reference.
    summaryRel=safeRelative(study.resolvedSummaryRelativeFile);
elseif ~isfield(study,'resolvedSummaryRelativeFile') && ...
        isfield(study,'summaryFile') && strlength(string(study.summaryFile))>0
    summaryRel=safeRelative(study.summaryFile);
else
    summaryRel=fullfile("Results",sub,"summary.mat");
end
study.resolvedSubexperimentId=sub;
study.resolvedSummaryRelativeFile=summaryRel;
study.summaryFile=fullfile(root,summaryRel);
if ~isfield(study,'outputTag'),study.outputTag="";end
tag=string(study.outputTag);
if strlength(tag)>0
    tag=safePart(tag);
else
    period="";
    if study.excitationMode=="Pulse",period="_"+safePart(study.period_us)+"us";end
    tag=safePart(study.excitationMode+period+"_"+study.conditionId+ ...
        "_axis"+string(study.scanAxisIndex)+"_"+study.direction);
end
outputRoot=root;
study.resolvedOutputBase="experimentRoot";
if isfield(study,'inversionsRoot') && ~isempty(study.inversionsRoot)
    outputRoot=string(study.inversionsRoot);
    assert(isscalar(outputRoot)&&~ismissing(outputRoot)&& ...
        strlength(strtrim(outputRoot))>0, ...
        'lamb:study:InversionsRoot', ...
        'inversionsRoot must be a nonempty absolute folder path.');
    normalized=replace(outputRoot,char(92),"/");
    isAbsolute=startsWith(normalized,"/") || ...
        ~isempty(regexp(char(normalized),'^[A-Za-z]:/','once'));
    assert(isAbsolute,'lamb:study:InversionsRoot', ...
        'inversionsRoot must be an absolute folder path.');
    study.resolvedOutputBase="inversionsRoot";
    [~,experimentFolder]=fileparts(char(root));
    experimentFolder=safePart(string(experimentFolder));
end
if ~isfield(study,'outputRelativeFolder')||strlength(string(study.outputRelativeFolder))==0
    if study.resolvedOutputBase=="inversionsRoot"
        destination=fullfile(experimentFolder,sub,family,tag);
    else
        destination=fullfile("Results",sub,"Inversions",family,tag);
    end
else
    destination=safeRelative(study.outputRelativeFolder);
end
study.resolvedOutputRelativeFolder=destination;
study.resultFile=fullfile(outputRoot,destination,"inversion.mat");
study.figureFolder=fullfile(outputRoot,destination);
study.figureName="inversion";
% Never allow accidental study overwrites. This is checked again at saving.
end

function value=safePart(value)
value=string(value);
assert(isscalar(value)&&~ismissing(value)&& ...
    ~isempty(regexp(char(value),'^[A-Za-z0-9][A-Za-z0-9_.-]*$','once'))&& ...
    ~endsWith(value,"."), ...
    'lamb:study:UnsafeOutputPath','An output identity contains unsafe characters.');
end

function value=safeRelative(value)
value=string(value);
assert(isscalar(value)&&~ismissing(value)&&strlength(value)>0, ...
    'lamb:study:UnsafeOutputPath','A nonempty relative path is required.');
% Validate both separator conventions, including on a non-Windows runner.
normalized=replace(value,char(92),"/");
parts=split(normalized,"/");
assert(~startsWith(normalized,"/")&&~contains(normalized,":")&& ...
    all(parts~=""&parts~="."&parts~=".."), ...
    'lamb:study:UnsafeOutputPath','Output and summary paths must be root-relative.');
for part=parts(:)'
    safePart(part);
end
value=fullfile(parts{:});
end
