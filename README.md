# matlab-decorators
Decorator attribute for Matlab classes

When a class inherits from Decoratable, it can define decorators in the  "SetDecorator" and "GetDecorator" attribute for its properties; or the "Decorator" attribute for its methods. 
Decorators take a function (a getter, setter or method of the class) and return another function that will be executed instead of the original one. Output functions must have the same signature (nargin and nargout) as the original function.

- Decorators must start with the function handle symbol: "@"
- Decorators must accept at least 2 input arguments: the function they wrap (setter, getter or method) and the context struct
- Additional input arguments are passed in the attribute between brackets
- Many decorators can be used by using a cell array {}. In that case, decorators are called from left to right:
 `{@decorator1, @decorator2} == @decorator1(@decorator2(...))`

## Example:
```MATLAB
classdef DecoratableSubclass < Decoratable
    properties (Description = "SetDecorator = @decorator.count")
        Property1
        Property2
    end
    properties (Description = "GetDecorator = @decorator.trace")
        Property3
    end
    methods (Description = "Decorator = {@decorator.nshot, @decorator.delay(3)}")
        function threeSecondDelayMethod(~)
        end
    end
end
```
%
% This class defines a set decorator for Property1 and Property2, a get 
% decorator for Property3, and two method decorators for its method. 
% To understand the behaviour of the decorated class properties and methods, see
% the decorators defined  in the "/+decorator" package
%
%
