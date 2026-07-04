function label = guiFitDisplayLabel(kind, value)
%GUIFITDISPLAYLABEL Return readable FitTool UI labels for internal ids.

kind = lower(string(kind));
value = string(value);

switch kind
    case "model"
        switch lower(value)
            case {"rayleigh_lamb", "rayleighlamb"}
                label = "Rayleigh-Lamb";
            case {"mrlfe", "mrlferealk"}
                label = "mRLFE";
            case {"acoustoelastic_iop_hgo", "acoustoelasticiophgo"}
                label = "AE IOP/HGO";
            otherwise
                label = value;
        end
    case "branch"
        switch value
            case "A0Like"
                label = "A0-like";
            case "S0Like"
                label = "S0-like";
            case "atlasA0"
                label = "atlas A0";
            otherwise
                label = value;
        end
    case "policy"
        switch value
            case "adaptivePhysicalTail"
                label = "Adaptive physical tail";
            case "delayedCut"
                label = "Delayed cut";
            otherwise
                label = value;
        end
    case "quality"
        text = replace(value, "_", " ");
        if strlength(text) == 0
            label = "";
        else
            label = upper(extractBefore(text, 2)) + extractAfter(text, 1);
        end
    otherwise
        label = value;
end
end
