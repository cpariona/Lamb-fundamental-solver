function lines = guiBuildMrlfeStatusText(guiResult, elapsedText)
%GUIBUILDMRLFESTATUSTEXT Present completion, coverage and canonical quality.
if nargin < 2
    elapsedText = "";
end
lines = strings(0,1);
metadata = guiGetStructField(guiResult, 'metadata', struct());
results = guiGetStructField(metadata, 'modelResults', struct());
names = fieldnames(results);
partial = string(guiGetStructField(metadata, 'status', "success")) == "partial";
for i = 1:numel(names)
    result = results.(names{i});
    if string(guiGetStructField(result, 'model', "")) ~= "mrlfe"
        continue;
    end
    valid = result.validMask(:);
    partial = partial || ~all(valid);
    lines(end+1,1) = sprintf('%s: Cp valid %d/%d | quality accepted: %d | %s', ...
        result.branch, nnz(valid), numel(valid), result.quality.accepted, ...
        result.quality.reason); %#ok<AGROW>
end
if isempty(lines)
    return;
end
headline = "Status: computed";
if partial
    headline = headline + " (partial)";
end
lines = [headline + string(elapsedText) + "."; lines];
end
