function outFunction = timer(inFunction, ctxt)
% TIMER prints the amount of time a function takes to execute

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
timer = tic;
src = fn(src, value);
disp("'" + name + "' setter took " + toc(timer) + " seconds to execute");
end

function out = decorateGetter(fn, name, src)
timer = tic;
out = fn(src);
disp("'" + name + "' getter took " + toc(timer) + " seconds to execute");
end

function varargout = decorateMethod(fn, name, src, varargin)
timer = tic;
[varargout{1:nargout}] = fn(src, varargin{:});
disp("Method '" + name + "' took " + toc(timer) + " seconds to execute");
end