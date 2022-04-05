-- Classy
-- fyuusha (@dev_fyuusha)
-- September 12, 2021

--[=[
    @class Classy
    This is the top level of Classy, where you access everything you need to create classes.  
    Classy is a library to make it easier to create classes and make them easier to read.  
    Classy has the ability to create subclasses and add Mixins for component based programming.

    ### Restricted Keywords
    - Super
    - new
    - Destroy
    - _mixins
    - _internallyDestroyed
    - _isInternallyDestroyed
    - _isObject

    These keywords are used internally by Classy for managing your classes.  
    You're allowed to use and access these fields and methods of your classes, the only exceptions are `_isInternallyDestroyed` and `_internallyDestroyed` (it is already used internally when `Destroy` is called).  
    To learn more about these keywords, please read the documentation for [Class](https://dev-fyuusha.github.io/Chain/api/Class).

    ### Example
    ```lua
    -- Simple class and subclass
    local Car = Classy.NewClass({
        ClassName = "Car";

        init = function(self, maxSpeed, color)
            self.MaxSpeed = maxSpeed or 32
            self.Color = color or Color3.fromRGB(255, 0, 0)

            print("car initialized")
        end;

        terminate = function(self)
            print("car destroyed")
        end;

        Honk = function(self)
            print(self.ClassName, "BEEP")
        end;
    })

    local greenCar = Car.new(120, Color3.fromRGB(0, 255, 0))
    greenCar:Honk()

    local Truck = Classy.NewSubclass({
        ClassName = "Truck";
    }, "Car") -- you could also alternatively pass the class itself

    function Truck:init(maxSpeed, color, tireAmount)
        self.TireAmount = tireAmount
        print("truck initialized")
    end

    function Truck:terminate()
        print("truck destroyed")
    end

    local semiTruck = Truck.new(90, Color3.fromRGB(0, 0, 255), 18)
    semiTruck:Honk()

    greenCar:Destroy()
    semiTruck:Destroy()

    local pickupTruck = Classy.NewObjectOfClass("Truck", 140, Color3.fromRGB(255, 0, 255), 4)
    pickupTruck:Honk()
    pickupTruck:Destroy()


    -- Mixin Addition
    -- With Mixins you can have them automatically picked up by Classy by putting them in the ClassMixins folder as Module Scripts
    -- For more information on Mixins and how to use them check the Mixins ModuleScript
    local VehicleBoostMixin = {}


    function VehicleBoostMixin.Add(class)
        assert(class.Boost == nil, "class already has a 'Boost' method")
        class.Boost = VehicleBoostMixin.Boost
    end


    function VehicleBoostMixin:Boost()
        local oldMaxSpeed = self.MaxSpeed
        self.MaxSpeed = oldMaxSpeed * 2
        print("VROOOOOOMMM")
        task.delay(1, function()
            self.MaxSpeed = oldMaxSpeed
        end)
    end

    Classy.Mixins.RegisterMixin("VehicleBoostMixin", VehicleBoostMixin)

    -- In another Script
    local fastCar = Car.new(160, Color3.fromRGB(255, 255, 255))

    -- you could alternatively pass the names of the Mixins you want to add as a table for the 2nd argument of the NewClass and NewSubclass methods
    Classy.Mixins.AddMixin(Car, "VehicleBoostMixin") -- you can even use this on a regular table

    -- It's also worth noting that passing a object of a class as the first parameter to AddMixin, will add it to the entire class, not the object itself.

    fastCar:Boost()
    fastCar:Destroy()
    ```
]=]

--[=[
    @prop Mixins Mixins
    @within Classy
    This is a reference to the Mixins table, where you can register mixins, add mixins to a class, and more.
    For full documentation refer to the [Mixins](https://dev-fyuusha.github.io/Chain/api/Mixins) documentation
]=]

--[=[
    @interface ClassInfo
    @within Classy
    .ClassName string -- The name of the class
    .terminate function? -- [Optional] The method that is called when destroying an object of the class
    .init function? -- [Optional] The method that is called when creating an object of the class

    This is what you should be sending when creating a new class or subclass.
    It is to be noted, however, that you can define `terminate` and `init` outside of this table by referring to your class and defining it, like so:
    ```lua
        local newClass = Classy.NewClass({
            ClassName = "newClass"
        })

        --[[
            it is to be noted that any arguments you pass to `new` on newClass
            and `Destroy` on individual objects will be passed to init and terminate respectively.
        --]]
        function newClass:init()

        end

        function newClass:terminate()

        end
    ```

    You can also define static fields in the ClassInfo.
]=]



local Class = require(script:WaitForChild("Class"))
local Mixins = require(script:WaitForChild("Mixins"))
local Errors = require(script:WaitForChild("Errors"))

local Classy = {
    Mixins = Mixins;
}


local function createClass(classInfo, superclass)
    local class = Class.CreateClass(classInfo, superclass)

    if (not superclass) then
        Mixins.AddMultipleMixins(class, {
            "IsAMixin", "HasMixin",
        })
    end

    return class
end


--[=[
    This creates a new subclass of an already existing class.

    @error Nonexistent Superclass -- Occurs when the Superclass passed doesn't exist

    @param subclassInfo ClassInfo -- The info for the class (see [ClassInfo](#ClassInfo))
    @param superclassAny string | Class -- The class that this one will be inheriting from
    @param mixins {string}? -- A table of mixins to add
    @return Class
]=]
function Classy.NewSubclass(subclassInfo, superclassAny, mixins)
    Errors.State(typeof(subclassInfo) == "table", "MustBe", "subclassInfo", "table")
    Errors.State(next(subclassInfo) ~= nil, "MustNotBeEmpty", "subclassInfo")
    assert(subclassInfo.ClassName ~= nil, "Newly created Class must have a Class Name")
    Errors.State(Class.DoesClassExist(subclassInfo.ClassName) == false, "ExistentItem", "Class", subclassInfo.ClassName)

    local superclassExists, superclass = Class.DoesClassExist(superclassAny)
    if (not superclassExists) then return nil, Errors.Report("NonexistentItem", "Superclass", tostring(superclassAny)) end

    local class = createClass(subclassInfo, superclass)
    if (mixins) then
        Mixins.AddMultipleMixins(class, mixins)
    end

    return class
end


--[=[
    This creates a new class.

    @param classInfo ClassInfo -- The info for the class (see [ClassInfo](#ClassInfo))
    @param mixins {string}? -- A table of mixins to add
    @param superclassAny string | Class -- The class that this one will be inheriting from
    @return Class
]=]
function Classy.NewClass(classInfo, mixins, superclassAny)
    Errors.State(typeof(classInfo) == "table", "MustBe", "classInfo", "table")
    Errors.State(next(classInfo) ~= nil, "MustNotBeEmpty", "classInfo")
    assert(classInfo.ClassName ~= nil, "Newly created Class must have a Class Name")
    Errors.State(Class.DoesClassExist(classInfo.ClassName) == false, "ExistentItem", "Class", classInfo.ClassName)

    local class
    if (superclassAny) then
        class = Classy.NewSubclass(classInfo, superclassAny)
    else
        class = createClass(classInfo)
    end

    if (mixins) then
        Mixins.AddMultipleMixins(class, mixins)
    end

    return class
end


--[=[
    This creates a object of an already existing class.

    @param className string
    @param ... tuple? -- this will pass any arguments you wish to pass to the [instantiation](https://dev-fyuusha.github.io/Chain/api/Class) of the class
    @return Object<Class>
]=]
function Classy.NewObjectOfClass(className, ...)
    Errors.State(typeof(className) == "string", "MustBe", "className", "string")

    local classExists, class = Class.DoesClassExist(className)
    if (not classExists) then return nil, Errors.Report("ExistentItem", "Class", className) end

    return class.new(...)
end


--[=[
    This gets a class by its class name.

    @error Nonexistent Class -- Occurs when the class couldn't be found

    @param className string
    @return Class
]=]
function Classy.GetClass(className)
    Errors.State(typeof(className) == "string", "MustBe", "className", "string")

    local classExists, class = Class.DoesClassExist(className)
    if (not classExists) then return nil, Errors.Report("ExistentItem", "Class", className) end

    return class
end


return Classy