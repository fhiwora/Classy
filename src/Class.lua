--[=[
    @class Class
    This is the internal definition of a class, and what is used internally for your classes, which you can also access.  
    To see an example of using Classy go [here.](https://dev-fyuusha.github.io/Classy/api/Classy)
]=]



--[=[
    @prop ClassName string
    @readonly
    @within Class
    The name of the class.
]=]

--[=[
    @prop Super string
    @within Class
    The class that the class inherits from (if it inherits).
]=]

--[=[
    @prop _isObject boolean
    @readonly
    @private
    @within Class
    Tells whether it is an object or not.  
    This is useful for when you need to check if you're messing with a class or an object of a class
]=]

--[=[
    @prop _internallyDestroyed boolean
    @readonly
    @private
    @within Class
    Distinguishes whether or not the object has been destroyed internally.  
    This is to keep from running Destroy multiple times.  
    Should not be used in your own code, as Classy handles if an object has already been destroyed.
]=]

--[=[
    @prop _mixins {[string]: boolean}
    @readonly
    @private
    @within Class
    A list of all the mixins that are currently in the class.
]=]

--[=[
    @function new
    @within Class
    @param ... tuple?
    @return Object<Class>
    Creates a new object of the class it is being called on.
    ```lua
        local class = Classy.new({
            ClassName = "class"
        })

        local object = class.new()
    ```
]=]

--[=[
    @function init
    @within Class
    @param ... tuple?
    Does any initialization of the object when [new](#new) is called.
]=]

--[=[
    @function terminate
    @within Class
    @param ... tuple?
    Does any deconstruction of the object when [Destroy](#Destroy) is called.
]=]

--[=[
    @function Destroy
    @within Class
    @param ... tuple?
    Destroys the object it is called on.
]=]

--[=[
    @function _isInternallyDestroyed
    @private
    @within Class
    @return boolean
    Returns whether the object is destroyed or not.  
    This is to keep from running Destroy multiple times.  
    Should not be used in your own code, as Classy handles if an object has already been destroyed.
]=]



local Utility = require(script.Parent:WaitForChild("Utility"))

local Class = {
    _classes = {};
}


local function doesClassExist(classAny)
    local className = typeof(classAny) == "table" and classAny.ClassName or classAny
    local class = Class._classes[className]

    return class ~= nil and true or false, class
end


local RESTRICTED_INDICES = {
    _isObject = true,
    _internallyDestroyed = true,
    _isInternallyDestroyed = true,
    _mixins = true,
    ClassName = true,
    new = true,
    Destroy = true,
}

local RESTRICTED_INDICES_NOT_NIL = {
    terminate = true,
    init = true,
}

local function createClassBase(classInfo, superclass)
    local copiedInfo = Utility.CopyTable(classInfo)

    local class
    if (superclass) then
        class = setmetatable(copiedInfo, {__index = superclass})
    else
        class = copiedInfo
    end

    class.__index = class
    class.__newindex = function(t, i, v)
        if (RESTRICTED_INDICES[i]) then
            error("Not allowed to set '" .. tostring(i) .. "' to a new value")
        elseif (RESTRICTED_INDICES_NOT_NIL[i] and rawget(t, i)) then
            error("Not allowed to set '" .. tostring(i) .. "' to a new value")
        else
            rawset(t, i, v)
        end
    end

    class._mixins = {}
    class.Super = superclass

    class._isInternallyDestroyed = function(self)
        return self._interallyDestroyed == true
    end

    class.Destroy = function(self, ...)
        if (self._isInternallyDestroyed(self)) then return end

        if (self.terminate) then
            self:terminate(...)
        end

        local super = self.Super
        while (super) do
            if (super.terminate) then
                super.terminate(self, ...)
            end

            super = super.Super
        end

        self._interallyDestroyed = true
        rawset(self, "_interallyDestroyed", true)
    end

    class.new = function(...)
        local object
        if (class.Super) then
            object = setmetatable(class.Super.new(...), class)
        else
            object = setmetatable({
                _interallyDestroyed = false;
                _isObject = true;
            }, class)
        end

        if (class.init) then
            class.init(object, ...)
        end

        return object
    end

    return class
end


local function createClass(classInfo, superclass)
    local class = createClassBase(classInfo, superclass)
    Class._classes[classInfo.ClassName] = class
    return class
end


return {
    CreateClass = createClass;
    DoesClassExist = doesClassExist;
}