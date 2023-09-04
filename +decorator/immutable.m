function outFunction = immutable(inFunction, ctxt)
% IMMUTABLE limits the setting of a property to only once
propertySet = false;

switch ctxt.type
    case "setter"
        outFunction = @(this, value) ...
            decorateSetter(inFunction, ctxt.name, this, value);
    otherwise
        error("The immutable decorator can only be applied to property setters");
end

    function src = decorateSetter(fn, name, src, value)
        if propertySet
            error("Object property <" + name + "> can only be set once");
        end
        src = fn(src, value);
        propertySet = true;
    end
end
