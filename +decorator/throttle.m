function outFunction = throttle(inFunction, ctxt, delay)
% THROTTLE executes the function at a maximum rate given by the delay input
if nargin == 2
    delay = 0.5;
end

t = timer("StartDelay", delay, "ExecutionMode", "singleShot");
t.TimerFcn = @(~,~) [];

switch ctxt.type
    case "setter"
        error("Throttle decorator can only be used with methods that return no outputs");
    case "getter"
        error("Throttle decorator can only be used with methods that return no outputs");
    otherwise
        outFunction = @(this, varargin) ...
            decorateMethod(inFunction, this, varargin{:});
end

    function decorateMethod(fn, src, varargin)
        if strcmp(t.Running, 'off')
            fn(src, varargin{:});
            t.start();
        end        
    end
end