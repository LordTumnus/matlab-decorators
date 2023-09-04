function outFunction = private(~, ctxt)
% PRIVATE throws an error whenever the function is called

c = class(ctxt.source);
switch ctxt.type
    case "setter"
        outFunction = @(this, value) decorateSetter();
    case "getter"
        outFunction = @(this) decorateGetter();
    otherwise
        outFunction = @(this, varargin) decorateMethod();
end

    function src = decorateSetter()
        src = []; %#ok<NASGU>
        error('Property cannot be set by objects that are not from the %s class', ...
            c)
    end

    function out = decorateGetter()
        out = []; %#ok<NASGU>
        error('Property cannot be get by objects that are not from the %s class', ...
            c);
    end

    function varargout = decorateMethod()
        varargout = cell(1, nargout); %#ok<NASGU>
        error('Method cannot be called by objects that are not from the %s class', ...
            c)
    end
end



