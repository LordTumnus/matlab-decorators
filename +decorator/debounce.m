function outFunction = debounce(inFunction, ctxt, delay)
% DEBOUNCE executes the function if it is not called again after a given amount
% of time ("delay")

if nargin == 2
    delay = 1;
end
t = timer("StartDelay", delay, "ExecutionMode", "singleShot");

switch ctxt.type
    case "setter"
        error("Debounce decorator can only be used with methods that return no outputs");
    case "getter"
        error("Debounce decorator can only be used with methods that return no outputs");
    otherwise
        outFunction = @(this, varargin) ...
            decorateMethod(inFunction, this, varargin{:});
end

    function decorateMethod(fn, src, varargin)
        t.stop();delete(t);
        t = timer("StartDelay", delay, "ExecutionMode", "singleShot");
        t.TimerFcn = @(~,~) fn(src, varargin{:});
        t.start();
    end
end