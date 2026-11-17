function paths = saveInverseFigure(fig, outputRoot, filename)
%SAVEINVERSEFIGURE Save an editable FIG and 300-dpi TIF outside source products.
%   FILENAME is an explicit deterministic basename, without directory/extension.
%   Both destinations must be absent. No native result or original is modified.
validateattributes(fig, {'matlab.ui.Figure'}, {'scalar'});
outputRoot = string(outputRoot); filename = string(filename);
if ~isscalar(outputRoot) || ismissing(outputRoot) || strlength(outputRoot)==0 || ...
        ~isscalar(filename) || ismissing(filename) || ...
        isempty(regexp(filename,'^[A-Za-z0-9][A-Za-z0-9_-]*$','once'))
    error('lamb:visualization:InvalidDestination','Supply an output root and a safe basename.');
end
paths = struct('fig',fullfile(outputRoot,filename+'.fig'), ...
    'tif',fullfile(outputRoot,filename+'.tif'));
if isfile(paths.fig) || isfile(paths.tif)
    error('lamb:visualization:OutputExists','Figure destination already exists: %s.',filename);
end
if ~isfolder(outputRoot), mkdir(outputRoot); end
% Export the full physical canvas; tight content cropping changes image sizes.
fig.PaperPositionMode='auto';
% Stage both files beside the destinations (same volume) and publish only after both exist.
stem = tempname(outputRoot);
stage = struct('fig',stem+".fig",'tif',stem+".tif");
cleanup = onCleanup(@()deleteExisting(stage)); %#ok<NASGU>
savefig(fig, stage.fig);
print(fig, stage.tif, '-dtiff', '-r300');
publishNoReplace(stage.fig, paths.fig, filename);
try
    publishNoReplace(stage.tif, paths.tif, filename);
catch publishError
    deleteExisting(struct('fig',paths.fig)); % Published by this call's successful no-replace move.
    rethrow(publishError);
end
end

function publishNoReplace(source, destination, filename)
% MATLAB movefile overwrites an existing destination (and may return status 0 without
% throwing), so use Java NIO Files.move without REPLACE_EXISTING, which fails if the
% destination exists. Requires the MATLAB JVM.
try
    noOptions = javaArray('java.nio.file.CopyOption',0);
    java.nio.file.Files.move(java.nio.file.Paths.get(char(source),javaArray('java.lang.String',0)), ...
        java.nio.file.Paths.get(char(destination),javaArray('java.lang.String',0)), noOptions);
catch moveError
    if isa(moveError,'matlab.exception.JavaException') && ...
            isa(moveError.ExceptionObject,'java.nio.file.FileAlreadyExistsException')
        error('lamb:visualization:OutputExists','Figure destination already exists: %s.',filename);
    end
    error('lamb:visualization:PublishFailed','Could not publish %s: %s',destination,moveError.message);
end
end

function deleteExisting(files)
for name = string(fieldnames(files))'
    if isfile(files.(name)), delete(files.(name)); end
end
end
