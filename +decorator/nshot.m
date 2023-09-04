function outFunction = nshot(inFunction, ctxt, limit)
% NSHOT limits the amount of times a method can be called
% The limit defaults to 1 (single shot) unless otherwise specified

if nargin == 2
    limit = 1;
end

called = 0;

switch ctxt.type
    case "setter"
        error("n-Shot decorator can only be used with methods");
    case "getter"
        error("n-Shot decorator can only be used with methods");
    otherwise
        outFunction = @(this, varargin) ...
            decorateMethod(inFunction, this, varargin{:});
end

    function decorateMethod(fn, src, varargin)
        if called < limit
            fn(src, varargin{:});
            called = called + 1;
        else
            error("Function '" + ctxt.name + "' is " + limit + "-shot and has already" + ...
                " been called the maximum number of times allowed");
        end
    end
end