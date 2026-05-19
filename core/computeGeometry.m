function geometry = computeGeometry(params)
% Build geometry structure from total thickness.

thickness = params.thickness;
if thickness <= 0
    error('thickness must be positive.');
end

geometry = struct();
geometry.thickness = thickness;
geometry.halfThickness = thickness / 2;
end
