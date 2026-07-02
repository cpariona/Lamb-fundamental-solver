function base = guiMergeStructs(base, overlay)
%GUIMERGESTRUCTS Overlay fields from one scalar struct onto another.

if ~isstruct(overlay)
    return;
end

names = fieldnames(overlay);
for i = 1:numel(names)
    base.(names{i}) = overlay.(names{i});
end
end
