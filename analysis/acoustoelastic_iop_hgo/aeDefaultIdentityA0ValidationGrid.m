function grid = aeDefaultIdentityA0ValidationGrid()
%AEDEFAULTIDENTITYA0VALIDATIONGRID Default grid for identity-A0 validation diagnostics.
%
% The grid is shared by the retained identity-A0 and score-grid validations so the
% two heavy diagnostics remain comparable.

IOP_mmHg = [5, 15, 25, 35];
mu_kPa = [25, 50, 100];
k1_kPa = [10, 25, 50];
k2 = [50, 100, 200];
thickness_um = [450, 650];

rows = [];
idx = 0;
for iop = IOP_mmHg
    for mu = mu_kPa
        for k1 = k1_kPa
            for k2v = k2
                idx = idx + 1;
                row = struct();
                row.CaseIndex = idx;
                row.IOP_mmHg = iop;
                row.mu_kPa = mu;
                row.k1_kPa = k1;
                row.k2 = k2v;
                row.thickness_um = 550;
                row.GridFamily = "material_iop_core";
                rows = [rows; row]; %#ok<AGROW>
            end
        end
    end
end
for h = thickness_um
    idx = idx + 1;
    row = struct();
    row.CaseIndex = idx;
    row.IOP_mmHg = 25;
    row.mu_kPa = 50;
    row.k1_kPa = 25;
    row.k2 = 100;
    row.thickness_um = h;
    row.GridFamily = "thickness_probe";
    rows = [rows; row]; %#ok<AGROW>
end
grid = struct2table(rows);
end
