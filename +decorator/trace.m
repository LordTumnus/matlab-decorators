function outFunction = trace(inFunction, ctxt)
% TRACE displays the inputs and outputs of the called function in the console
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
end

function src = decorateSetter(fn, name, src, value)
disp("Calling set(" + name + ", " + value + ")");
src = fn(src, value);
end

function out = decorateGetter(fn, name, src)
out = fn(src);
disp("Calling getter of " + name + " => " + jsonencode(out));
end

function varargout = decorateMethod(fn, name, src, varargin)
disp("Calling " + name + ".(" + strjoin(string(cellfun(@(x) jsonencode(x), varargin, "uni", false)), ", ") + ")");
[varargout{1:nargout}] = fn(src, varargin{:});
disp("=> " + strjoin(string(cellfun(@(x) jsonencode(x), varargout, "uni", false)), ", "));
end