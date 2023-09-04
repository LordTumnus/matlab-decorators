function outFunction = delay(inFunction, ctxt, time)
% DELAY executes a function after a fixed amount of time

if nargin == 2
    time = 0.5;
end

switch ctxt.type
    case "setter"
        error("Delay decorator can only be used with methods that return no outputs");
    case "getter"
        error("Delay decorator can only be used with methods that return no outputs");
    otherwise
        outFunction = @(this, varargin) ...
            decorateMethod(inFunction, this, time, varargin{:});
end

end

function decorateMethod(fn, src, time, varargin)
t = timer("StartDelay", time, "ExecutionMode", "singleShot");
t.TimerFcn = @(~,~) fn(src, varargin{:});
t.StopFcn = @(~, ~) delete(t);
t.start();
end