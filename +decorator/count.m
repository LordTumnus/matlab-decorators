function outFunction = count(inFunction, ctxt)
% Count and display the amount of times a function is called
currentCount = 0;

switch ctxt.type
    case "setter"
        outFunction = @(this, value) ...
            decorateSetter(inFunction, ctxt.name, this, value);
    case "getter"
        outFunction = @(this) ...
            decorateGetter(inFunction, ctxt.name, this);
    otherwise
        outFunction = @(this, varargin) ...
            decorateMethod(inFunction, ctxt.name, this, varargin{:});
end


    function src = decorateSetter(fn, name, src, value)
        src = fn(src, value);
        currentCount = currentCount + 1;
        disp("Object property <" + name + "> has been set " + currentCount + " times");
    end

    function out = decorateGetter(fn, name, src)
        currentCount = currentCount + 1;
        out = fn(src);
        disp("Object property <" + name + "> has been gotten " + currentCount + " times");
    end

    function varargout = decorateMethod(fn, name, src, varargin)
        currentCount = currentCount + 1;
        [varargout{1:nargout}] = fn(src, varargin{:});
        disp("Object method <" + name + "> has been called " + currentCount + " times");
    end


end
