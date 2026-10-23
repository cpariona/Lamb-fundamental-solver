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
savefig(fig, paths.fig);
exportgraphics(fig, paths.tif, 'Resolution',300);
end
