function text = guiFormatSweepValues(values)
%GUIFORMATSWEEPVALUES Format numeric sweep defaults for text edit controls.

if isempty(values)
    text = '';
    return;
end

values = values(:).';
parts = strings(1, numel(values));
for i = 1:numel(values)
    parts(i) = string(sprintf('%.6g', values(i)));
end
text = char(strjoin(parts, ', '));
end
