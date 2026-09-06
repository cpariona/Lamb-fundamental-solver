function figureFolder = mrlfeSaveExampleFigure(fig, scriptFile, taskName, filePrefix)
%MRLFESAVEEXAMPLEFIGURE Save example figures next to the sweep script.

if nargin < 4 || isempty(filePrefix)
    filePrefix = taskName;
end

scriptFolder = fileparts(scriptFile);
figureFolder = fullfile(scriptFolder, 'figures', char(taskName));
if ~exist(figureFolder, 'dir')
    mkdir(figureFolder);
end

figPath = fullfile(figureFolder, char(filePrefix) + ".fig");
pngPath = fullfile(figureFolder, char(filePrefix) + ".png");

savefig(fig, figPath);
exportgraphics(fig, pngPath, 'Resolution', 300);
end
