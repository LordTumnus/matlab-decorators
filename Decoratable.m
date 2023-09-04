% DECORATABLE
% Superclass for classed that allow decorating its properties and methods.
% 
% When a class inherits from Decoratable, it can define decorators in the 
% "SetDecorator" and "GetDecorator" attribute for its properties; or the 
% "Decorator" attribute for its methods. 
% 
% Decorators take a function (a getter, setter or method of the class) and
% return another function that will be executed instead of the original one.
% Output functions must have the same signature (nargin and nargout) as the
% original function.
%
% - Decorators must start with the function handle symbol: "@"
% - Decorators must accept at least 2 input arguments: the function they wrap 
%   (setter, getter or method) and the context struct
% - Additional input arguments are passed in the attribute between brackets
% - Many decorators can be used by using a cell array {}. In that case,
%   decorators are called from left to right:
%   {@decorator1, @decorator2} == @decorator1(@decorator2(...))
%
%
% EXAMPLE:
%
% classdef DecoratableSubclass < Decoratable
%   properties (Description = "SetDecorator = @decorator.count")
%       Property1
%       Property2
%   end
%   properties (Description = "GetDecorator = @decorator.trace")
%       Property3
%   end
%   methods (Description = "Decorator = {@decorator.nshot, @decorator.delay(3)}")
%       function threeSecondDelayMethod(~)
%       end
%   end
%
% This class defines a set decorator for Property1 and Property2, a get 
% decorator for Property3, and two method decorators for its method. 
% To understand the behaviour of the decorated class properties and methods, see
% the decorators defined  in the "/+decorator" package
%
%


classdef (Abstract, HandleCompatible) Decoratable

    properties (Access = private, Hidden)
        % DECORATED...: Dictionaries mapping a property/method name to the
        % function that will be actually executed when called
        DecoratedSetters = dictionary(string.empty(), function_handle.empty())
        DecoratedGetters = dictionary(string.empty(), function_handle.empty())
        DecoratedMethods = dictionary(string.empty(), function_handle.empty())
    end

    methods
        function this = Decoratable()
            % DECORATABLE constructor. Parse the properties and methods looking
            % for those whose attributes match a valid decorator

            % List all the properties and methods from the object
            c = meta.class.fromName(class(this));
            props = c.PropertyList;
            meths = c.MethodList;

            % Run through the properties and methods looking for those whose
            % description match a valid decorator
            this = this.iReadDecorator("setter", props);
            this = this.iReadDecorator("getter", props);
            this = this.iReadDecorator("method", meths);
        end
    end

    methods (Access = public)
        function this = decorate(this, name, type, decorator, args)
            % DECORATE applies a decorator to a property or method of the object
            %
            % @param[in] name The property/method name
            % @param[in] type The kind of decorator ("getter", "setter" for
            %                 properties; "method" for methods)
            % @param[in] decorator A valid decorator of the property/method
            % @param[in,opt] args A cell array which contains optional
            %                     arguments passed to each decorator function
            % @returns the same object decorated
            %
            % @note decorate does not check if the passed property or method
            %       name is an actual prop/mehtod of the class
            % @note calling decorate on a property or method will remove the
            %       previous decorators of the same type
            arguments
                this
                name string
                type string {mustBeMember(type,["setter","getter","method"])}
                decorator {mustBeValidDecorator}
                args cell = cell.empty();
            end

            % Wrap in a cell the decorator
            if ~iscell(decorator)
                decorator = {decorator};
            end

            if isempty(args)
                args = {cell(1,numel(decorator))};
            end

            % Create the context element. It will be passed as the second
            % argument to the decorator
            context = struct("source", this, "type", type, "name", name);
            % Create the getter/setter/method function handle that will be
            % passed as the first argument to the decorator
            switch type
                case "setter"
                    p = "DecoratedSetters";
                    fn = @(this, value) setter(this, name, value);
                    chk = @(fn) iCheckDecoratedSetterFunction(fn, name, this);
                case "getter"
                    p = "DecoratedGetters";
                    fn = @(this) getter(this, name);
                    chk = @(fn) iCheckDecoratedGetterFunction(fn, name);
                otherwise
                    p = "DecoratedMethods";
                    fn = @(this, varargin) method(this, name, varargin{:});
                    o = class(this) + ">" + class(this) + "." + name;
                    chk = @(fn) iCheckDecoratedMethodFunction(fn, name, o);
            end

            try
                % Evaluate the (last) decorator with the function handle and the
                % context and check that the output is a fn_handle
                decorated = decorator{end}(fn, context, args{end}{:});
                chk(decorated);
                % If there are more decorators, apply them from right to left
                for ii = numel(decorator):-1:2
                    decorated = decorator{ii - 1}(decorated, context, args{ii - 1}{:});
                    chk(decorated)
                end

                % Store the decorate callback in its respective dictionary type
                % (override the callback if it existed previously)
                this.(p)(name) = decorated;
            catch ME
                rethrow(ME)
            end
        end
    end

    methods (Sealed)
        function varargout = subsref(this, idxOp)
            % SUBSREF is executed whenever an object of the Decoratable class is
            % indexed (with a dot, parenthesis or braces) on the rhs of an
            % assignment
            % - For property or method dot indexing: if the called property
            %   method or property is decorated, subsref will call the decorated
            %   getter or method. Otherwise, the builtin getter or method is
            %   called
            % - For parenthesis or brace indexing, the builtin subsref is used
            % @note subsref also handles paren-dot referencing

            try
                % Use builtin subsref if the object is not dot-indexed or
                % paren-dot- indexed
                if ~(strcmp(idxOp(1).type, '.') || ...
                        (numel(idxOp) > 1 && strcmp(idxOp(2).type, '.')))
                    [varargout{1:nargout}] = builtin('subsref', this, idxOp);
                    return;
                end

                % If it is paren-dot assigned, access the element of the
                % parenthesis before continuing with the dot overload
                if ~strcmp(idxOp(1).type, '.')
                    idxElement = builtin('subsref', this, idxOp(1));
                    [varargout{1:nargout}] = subsref(idxElement, idxOp(2:end));
                    return
                end

                % the first index opertation is of type '.' and defines the
                % property or method being called
                name = string(idxOp(1).subs);

                % The method/property is not decorated: call it normally
                if ~this(1).DecoratedGetters.isKey(name) && ...
                        ~this(1).DecoratedMethods.isKey(name)
                    [varargout{1:nargout}] = builtin('subsref', this, idxOp);
                    return; % early return
                end

                if this(1).DecoratedGetters.isKey(name)
                    decoratedFcn = arrayfun(@(x) x.DecoratedGetters(name), ...
                        this, "UniformOutput", false);
                    if numel(idxOp) == 1
                        try
                            % Return all the outputs from the decorated getter
                            % call
                            if nargout > numel(this)
                                throw(MException(message("MATLAB:maxlhs")));
                            end
                            n = max(nargout, 1);
                            out = cellfun(@(x,y) x(y), ....
                                decoratedFcn(1:n), num2cell(this(1:n)), ...
                                "UniformOutput", false);
                            [varargout{1:nargout}] = out{:};
                        catch DE
                            e = iCreateDecoratedError("getter", name, DE);
                            error(e);
                        end
                    else
                        if numel(this) > 1
                            throw(MException(message("MATLAB:index:expected_one_output_from_intermediate_indexing","'.'", numel(this))));
                        end
                        try
                            % get the outputs of the decorated getter call
                            decoratedOut = decoratedFcn{1}(this);
                        catch DE
                            e = iCreateDecoratedError("getter", name, DE);
                            error(e);
                        end
                        % Dispatch any other index operation to the result of the
                        % decorated method call, and return the outputs
                        [varargout{1:nargout}] = ...
                            subsref(decoratedOut, idxOp(2:end));
                    end
                    return; % exit
                end

                % check if the referenced element is a decorated method
                if this(1).DecoratedMethods.isKey(name)
                    if (numel(idxOp) == 1) || (idxOp(2).type ~= "()")
                        args = {};
                    elseif (idxOp(2).type == "()")
                        args = idxOp(2).subs;
                    end
                    % Only the decorator of the FIRST object is called, with
                    % "this" 
                    decoratedFcn = this(1).DecoratedMethods(name);
                    if (numel(idxOp) == 1) || ...
                            (numel(idxOp) == 2 && idxOp(2).type == "()")
                        % Return all the outputs from the decorated method
                        % call
                        try
                            [varargout{1:nargout}] = decoratedFcn(this, args{:});
                        catch DE
                            e = iCreateDecoratedError("method", name, DE);
                            error(e);
                        end
                    else
                        try
                            % Return all the outputs from the decorated method
                            % call. Expects at least 1 output
                            decoratedOut = decoratedFcn(this, args{:});
                        catch DE
                            e = iCreateDecoratedError("method", name, DE);
                            error(e);
                        end
                        % Dispatch any other index operation to the result of
                        % the decorated method call, and return the outputs
                        if idxOp(2).type == "()"
                            [varargout{1:nargout}] = ...
                                subsref(decoratedOut, idxOp(3:end));
                        else
                            [varargout{1:nargout}] = ...
                                subsref(decoratedOut, idxOp(2:end));
                        end
                    end
                    return; % exit
                end
            catch ME
                if ME.identifier ~= "Decoratable:callback"
                    % throw as caller
                    throwAsCaller(ME)
                else
                    % keep the stack
                    rethrow(ME)
                end
            end
        end


        function this = subsasgn(this, idxOp, value)
            % SUBSASGN is executed whenever an object of the Decoratable class 
            % is indexed (with a dot, parenthesis or braces) on the lhs of an
            % assignment
            % - For property or method dot indexing: if the called property
            %   method or property is decorated, subsasgn will call the 
            %   decorated setter or method. Otherwise, the builtin setter or 
            %   method is called
            % - For parenthesis or brace indexing, the builtin subsasgn is used
            % @note subsasgn also handles paren-dot referencing

            try
                % Use builtin subsasgn if the object is not dot-indexed or
                % paren-dot-indexed
                if ~(strcmp(idxOp(1).type, '.') || ...
                        (numel(idxOp) > 1 && strcmp(idxOp(2).type, '.')))
                    this = builtin('subsasgn', this, idxOp, value);
                    return;
                end

                % If it is paren-dot assigned, get the paren or brace indexed
                % element (el), do the dot subsasgn (recursion), and re-asign to
                % original
                if ~strcmp(idxOp(1).type, '.')
                    el = builtin('subsref', this, idxOp(1));
                    el = subsasgn(el, idxOp(2:end), value); % recursion
                    this = builtin('subsasgn', this, idxOp(1), el);
                    return;
                end

                % the first index opertation is of type '.' and defines the
                % property or method of the class that's being called
                name = string(idxOp(1).subs);


                % If the subsasgn is not applied to a decorated property or
                % method, evaluate through the builtin asignment operator
                if ~this(1).DecoratedSetters.isKey(name) && ...
                        ~this(1).DecoratedMethods.isKey(name)
                    this = builtin('subsasgn', this, idxOp, value);
                    return; % early return
                end


                % If the subsasgn is applied to a decorated property:
                if this(1).DecoratedSetters.isKey(name)
                    % Check if this has more than one element: in that case, no
                    % assignment is possible
                    if numel(this) > 1
                        throw(MException(message("MATLAB:index:expected_one_output_for_assignment", numel(this))));
                    end

                    % 1: Check if the assignment is deep (more than one '.' operator)
                    %    and calculate the true assignment value
                    if numel(idxOp) > 1
                        out = builtin('subsref', this, idxOp(1));
                        value = subsasgn(out, idxOp(2:end), value);
                    end
                    % 2: get the decorator
                    decoratedFcn = this.DecoratedSetters(name);
                    % eval setter discerning between handle & value classes
                    try
                        if ~isa(this, 'handle')
                            this = decoratedFcn(this, value);
                        else
                            decoratedFcn(this, value);
                        end
                        return; % exit
                    catch DE
                        e = iCreateDecoratedError("setter", name, DE);
                        error(e);
                    end
                end

                % The subsasgn is applied to a method
                decoratedFcn = this(1).DecoratedMethods(name);

                % Compute the output of the method
                % there must be at least one output for the subsasgn to work
                try
                    if numel(idxOp) == 1 || ~strcmp(idxOp(2).type, '()')
                        out = decoratedFcn(this); % might throw
                    elseif strcmp(idxOp(2).type, '()')
                        args = idxOp(2).subs;
                        out = decoratedFcn(this, args{:}); % might throw
                    end
                catch DE
                    e = iCreateDecoratedError("method", name, DE);
                    error(e);
                end

                if isa(out, 'handle')
                    if numel(idxOp) == 1
                        out = value; %#ok<NASGU>
                    elseif strcmp(idxOp(2).type, '()')
                        out = subsasgn(out, idxOp(3:end), value); %#ok<NASGU>
                    else
                        out = subsasgn(out, idxOp(2:end), value); %#ok<NASGU>
                    end
                else
                    throw(MException(message("MATLAB:index:assignmentToTemporary", name)));
                end
            catch ME
                if ME.identifier ~= "Decoratable:callback"
                    throwAsCaller(ME)
                else
                    rethrow(ME)
                end
            end
        end

        
    end

    methods (Access = private, Hidden)

        function this = iReadDecorator(this, kind, elementArray)
            % IPARSEDECORATORATTRIBUTES is an internal method that will go through all the
            % elements (props or meths) of the meta array, and return a dictionary
            % in which the keys are the elements and the values are their decorator
            % callbacks parsed from the meta-description

            % Run through the parsed elements
            for ii = 1:numel(elementArray)
                % Parse the description of the element looking for the decorators
                parsedDesc = iParseDecoratorCallbacks(...
                    elementArray(ii).Description, kind);
                if isempty(parsedDesc) % no decorators
                    continue;
                end
                % evaluate decorator string
                decorator = cell(1, numel(parsedDesc));
                args = cell(1, numel(parsedDesc));
                for jj = 1:numel(parsedDesc)
                    decorator{jj} = iEvaluateInClosedScope(parsedDesc(jj).fun);
                    if isempty(parsedDesc(jj).args)
                        args{jj} = {};
                    else
                        ins = "{"+ parsedDesc(jj).args(2:end-1) + "}";
                        args{jj} = iEvaluateInClosedScope(ins);
                    end
                end
                this = this.decorate(elementArray(ii).Name, kind, decorator, args);
            end
        end
    end
end

function fn = iEvaluateInClosedScope(txt)
% IEVALUATEINCLOSEDSCOPE wraps an eval()
fn = eval(txt);
end

function cb = iParseDecoratorCallbacks(text, kind)
% IPARSEDECORATORCALLBACKS extracts from a string the callbacks assigned to a
% decorator type

% regex pattern searches for one of:
% - "decorator = @callback"
% - "decorator = {@c1, @c2, ...}"

switch kind
    case "setter"
        decoratorType = "SetDecorator";
    case "getter"
        decoratorType = "GetDecorator";
    otherwise
        decoratorType = "Decorator";
end
argPattern = "[^)@]*";
funPattern = "(?<fun>@[\w.]+)(?<args>\("+argPattern+"\))?";
pattern = "(?:(?<![\w,])"+decoratorType+"\s*=\s*)(" + funPattern + ")|(\{" + funPattern + "\s*?(,\s*?" + funPattern + ")*\})";


blocks = regexp(text ,pattern, "tokens");
if isempty(blocks) || numel(blocks)>1
    cb = string.empty();
    return;
end
funs = regexp(blocks{1}, funPattern, "names");
if isempty(funs) || numel(funs)>1
    cb = string.empty();
    return;
end
cb = funs{1};
end

function mustBeValidDecorator(dec)
% MUSTBEVALIDDECORATOR asserts that the passed argument is a valid decorator
% function. Valid decorators must:
% - be function handles
% - have 2 input arguments
% - must return a single output, and it must be a function (the decorated
%   function)
if ~iscell(dec)
    assert(isa(dec, "function_handle"), "Decorator functions must be function handles");
    nin = nargin(dec); nout = nargout(dec);
    assert(nin >= 2 || nin < 0, "Decorator functions must take 2 arguments");
    assert(nout == 1 || nout < 0, "Decorator functions must return a single value that must be a function handle");
else
    cellfun(@mustBeValidDecorator, dec);
end
end

% ---
% Error handling helpers
function e = iCreateDecoratedError(decType, name, ME)
e = struct("message", "Error while evaluating the decorated " + decType + " of '" + name + "'" + newline + ">> " + ME.message, ...
    "stack", ME.stack(1), ...
    "identifier", "Decoratable:callback");
end

function iCheckDecoratedGetterFunction(fn, name)
tf = isa(fn, 'function_handle');
tf = tf && (nargin(fn) == 1) && (nargout(fn) == -1);
assert(tf, "Decoratable:check", ...
           "Error while decorating the property getter of '" + name + "': " + ...
           "Decorated property getters must be function handles with exactly" + ...
           "one input argument and one output argument");
end

function iCheckDecoratedSetterFunction(fn, name, src)
tf = isa(fn, 'function_handle');
tf = tf && (nargin(fn) == 2) && (nargout(fn) == -1 || (isa(src,'handle') && nargout(fn) == 0));
assert(tf, "Decoratable:check", ...
           "Error while decorating the property setter of '" + name + "': " + ...
           "Decorated setters must be function handles with exactly " + ...
           "two input arguments and 1 output argument (or 0 if the object is a handle)");
end

function iCheckDecoratedMethodFunction(fn, name, ~)
tf = isa(fn, 'function_handle');
assert(tf, "Decoratable:check", ...
           "Error while decorating the method '" + name + "': " + ...
           "Decorated setters must be function handles");
end

% Wrappers
function varargout = setter(this, pname, pval)
this = builtin('subsasgn', this, substruct('.',pname), pval);
if ishandle(this)
    varargout = {};
else
    varargout = {this};
end
end

function out = getter(this, pname)
out = builtin('subsref', this, substruct('.',pname));
end

function varargout = method(this, mname, varargin)
[varargout{1:nargout}] = builtin('subsref', this, substruct('.',mname,'()',varargin));
end
