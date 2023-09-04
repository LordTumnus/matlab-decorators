function outFunction = twice(inFunction, ctxt)
% TWICE calls a function two times

switch ctxt.type
    case "setter"
        outFunction = @(this, value) decorateSetter(inFunction, this, value);
    case "getter"
        outFunction = @(this) decorateGetter(inFunction, this);
    otherwise
        outFunction = @(this, varargin) decorateMethod(inFunction, this, varargin{:});
end

    function src = decorateSetter(fn, src, val)
        fn(src, val);
        src = fn(src, val);
    end

    function out = decorateGetter(fn, src)
        fn(src);
        out = fn(src);
    end

    function varargout = decorateMethod(fn, src, varargin)
        fn(src, varargin{:});
        [varargout{1:nargout}] = fn(src, varargin{:});
    end
end



