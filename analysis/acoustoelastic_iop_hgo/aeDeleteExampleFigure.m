function figureFolder = aeDeleteExampleFigure(scriptFile, taskName, filePrefix)
%AEDELETEEXAMPLEFIGURE Delete generated example figure files when obsolete.

scriptFolder = fileparts(scriptFile);
figureFolder = fullfile(scriptFolder, 'figures', char(taskName));
if ~exist(figureFolder, 'dir')
    return;
end

generatedExtensions = [".fig", ".png"];
for i = 1:numel(generatedExtensions)
    filePath = fullfile(figureFolder, char(string(filePrefix) + generatedExtensions(i)));
    if exist(filePath, 'file')
        delete(filePath);
    end
end
end
