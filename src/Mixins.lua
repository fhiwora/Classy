-- Mixins
-- fyuusha (@dev_fyuusha)
-- September 13, 2021

--[=[
    @class Mixins
    This module is used to register Mixins, add Mixins to classes, and check if classes have Mixins.
    Mixins are pieces of code you can inject into a class.

    ### Example
    ```lua
        -- To register Mixins
        -- whenever you register a mixin folder, when adding a Mixin to a class, if the Mixin hasn't already been cached
        -- the folder registered (and every other folder registered) will be searched for the Mixin
        Classy.Mixins.RegisterMixinFolder(path.to.mixin.folder)

        -- registering mixins manually
        local TestMixin = {}

        function TestMixin.Add(class)
            assert(class.TestMethod == nil, "class already has a 'TestMethod' method")
            class.TestMethod = TestMixin.TestMethod
        end

        function TestMixin.TestMethod()
            print("test")
        end

        Classy.Mixins.RegisterMixin("TestMixin", TestMixin)

        -- registering a mixin in a module
        Classy.Mixins.RegisterMixinFromModule(path.to.module.script)

        -- adding a mixin to a class

        local NewClass = Classy.NewClass({
            ClassName = "New";
        }) -- you could alternatively pass the names of the Mixins you want to add as a table for the 2nd argument of the NewClass and NewSubclass methods
        Classy.Mixins.AddMixin(NewClass, "TestMixin")

        -- It's also worth noting that passing a object of a class as the first parameter to AddMixin, will add it to the entire class, not the object itself.

        local newObject = NewClass.new()
        NewClass.TestMethod()
        newObject.TestMethod()

        -- you can even use mixins on any table
        local someTable = {}
        Classy.Mixins.AddMixin(someTable, "TestMixin")

        someTable.TestMethod()
    ```
]=]



local Class = require(script.Parent:WaitForChild("Class"))
local Errors = require(script.Parent:WaitForChild("Errors"))

local MixinsFolder = script.Parent:WaitForChild("ClassMixins", 3)

local Mixins = {
    _mixinLocations = {};
    _mixins = {};
}


local function doesMixinExist(mixinName)
    local mixin = Mixins._mixins[mixinName]
    if (mixin) then return true, mixin end

    for _, mixinFolder in pairs(Mixins._mixinLocations) do
        local mixinModule = mixinFolder:FindFirstChild(mixinName, true)
        if (mixinModule) then
            mixin = require(mixinModule)
            Mixins._mixins[mixinName] = mixin
            return true, mixin
        end
    end

    return false
end


local function checkForMixin(self, mixinName)
	if (self._mixins[mixinName]) then return true end

	local super = self.Super
	while (super) do
		if (super._mixins[mixinName]) then return true end
		super = super.Super
	end

	return false
end


--[=[
    Registers the folder as a valid location for finding Mixins.

    @param folder Instance<Folder>
]=]
function Mixins.RegisterMixinFolder(folder)
    Errors.State(typeof(folder) == "Instance" and folder:IsA("Folder"), "MustBe", "folder", "Folder")
    table.insert(Mixins._mixinLocations, folder)
end


--[=[
    Manually register a Mixin see example at the [top of the page.](#top)

    @param mixinName string
    @param mixin Dictionary
]=]
function Mixins.RegisterMixin(mixinName, mixin)
    Errors.State(doesMixinExist(mixinName) == false, "ExistentItem", "Mixin", mixinName)
    assert(mixin.Add ~= nil, "Mixin '" .. mixinName .. "' doesn't have a 'Add' method")

    Mixins._mixins[mixinName] = mixin
end


--[=[
   Requires the ModuleScript passed and requiers the Mixin.

   @param mixinModule Instance<ModuleScript>
]=]
function Mixins.RegisterMixinFromModule(mixinModule)
    Errors.State(typeof(mixinModule) == "Instance" and mixinModule:IsA("ModuleScript"), "MustBe", "mixinModule", "ModuleScript")
    Errors.State(doesMixinExist(mixinModule.Name) == false, "ExistentItem", "Mixin", mixinModule.Name)

    local mixin = require(mixinModule)
    assert(mixin.Add ~= nil, "Mixin '" .. mixinModule.Name .. "' doesn't have a 'Add' method")

    Mixins._mixins[mixinModule.Name] = mixin
end


--[=[
   Registers multiple Mixins.

   @param mixins {Dictionary}
]=]
function Mixins.RegisterMultipleMixins(mixins)
    Errors.State(typeof(mixins) == "table", "MustBe", "mixins", "table")
    Errors.State(next(mixins) ~= nil, "MustNotBeEmpty", "mixins")

    for mixinName, mixin in pairs(mixins) do
        Mixins.RegisterMixin(mixinName, mixin)
    end
end


--[=[
   Requires and registers multiple Mixin Modules.

   @param mixinModules {Instance<ModuleScript>}
]=]
function Mixins.RegisterMultipleMixinsFromModules(mixinModules)
    Errors.State(typeof(mixinModules) == "table", "MustBe", "mixinModules", "table")
    Errors.State(next(mixinModules) ~= nil, "MustNotBeEmpty", "mixinModules")

    for _, mixinModule in pairs(mixinModules) do
        Mixins.RegisterMixinFromModule(mixinModule)
    end
end


--[=[
    Checks if a Class has the Mixin being checked for.

    @error Nonexistent Class -- Occurs when the Class doesn't exist

    @param classAny string | Class
    @param mixinName string
    @return boolean
]=]
function Mixins.DoesClassHaveMixin(classAny, mixinName)
    local classExists, class = Class.doesClassExist(classAny)
    if (not classExists) then return false, Errors.Report("NonexistentItem", "Class", typeof(classAny) == "string" and classAny or classAny) end
    return checkForMixin(class, mixinName)
end


--[=[
    Checks if a Class has any of the mixins passed.

    @error Nonexistent Class -- Occurs when the Class doesn't exist

    @param classAny string | Class
    @param mixins {string}
    @return boolean, table -- the boolean is whether it had any of the mixins or not, the table is an array of which mixins it had
]=]
function Mixins.DoesClassHaveAnyMixins(classAny, mixins)
    assert(typeof(mixins) == "table" and next(mixins) ~= nil, "'mixins' must be a table and not be empty")

    local classExists, class = Class.doesClassExist(classAny)
    if (not classExists) then return false, Errors.Report("NonexistentItem", "Class", typeof(classAny) == "string" and classAny or classAny) end

    local hasAny, mixinNames = false, {}
    for _, mixinName in pairs(mixins) do
        if (checkForMixin(class, mixinName)) then
            hasAny = true
            table.insert(mixinNames, mixinName)
        end
    end

    return hasAny, mixinNames
end


--[=[
   Checks if a Class has all the mixins passed.

   @error Nonexistent Class -- Occurs when the Class doesn't exist

   @param classAny string | Class
   @param mixins {string}
   @return boolean
]=]
function Mixins.DoesClassHaveAllMixins(classAny, mixins)
    assert(typeof(mixins) == "table" and next(mixins) ~= nil, "'mixins' must be a table and not be empty")

    local classExists, class = Class.DoesClassExist(classAny)
    if (not classExists) then return false, Errors.Report("NonexistentItem", "Class", typeof(classAny) == "string" and classAny or classAny) end

    local hasAll, amount = false, 0
    for _, mixinName in pairs(mixins) do
        if (checkForMixin(class, mixinName)) then
            amount += 1
        end
    end

    if (amount == #mixins) then
        hasAll = true
    end

    return hasAll
end


--[=[
    Adds a Mixin to a Class.

    @error Nonexistent Class -- Occurs when the Class doesn't exist
    @error Nonexistent Mixin -- Occurs when the Class doesn't exist
    @error Mixin Apart of Class -- Occurs when the Mixin is already apart of the Class

    @param classAny string | Class
    @param mixinName string
]=]
function Mixins.AddMixin(classAny, mixinName)
    local isClass, classToMixin = false, nil
    if (typeof(classAny) == "table" and classAny.ClassName or typeof(classAny) == "string") then
        local classExists, class = Class.DoesClassExist(classAny)
        Errors.State(classExists, "NonexistentItem", "Class", typeof(classAny) == "string" and classAny or classAny)

        classToMixin = class
        isClass = true
    end

    local mixinExists, mixin = doesMixinExist(mixinName)
    if (mixinExists) then
        if (isClass) then
            assert(classToMixin._mixins[mixinName] == nil, "Mixin '" .. mixinName .. "' is already apart of Class '" .. classToMixin.ClassName .. "'")

            classToMixin._mixins[mixinName] = true
            mixin.Add(classToMixin)
        else
            mixin.Add(classAny)
        end
    else
        Errors.Report("NonexistentItem", "Mixin", mixinName)
    end
end


--[=[
    Adds multiple Mixins to a Class.

    @error Nonexistent Class -- Occurs when the Class doesn't exist
    @error Nonexistent Mixin -- Occurs when the Class doesn't exist
    @error Mixin Apart of Class -- Occurs when the Mixin is already apart of the Class

    @param classAny string | Class
    @param mixins {string}
]=]
function Mixins.AddMultipleMixins(classAny,  mixins)
    assert(typeof(mixins) == "table" and next(mixins) ~= nil, "'mixins' must be a table and not be empty")

    for _, mixinName in pairs(mixins) do
        Mixins.AddMixin(classAny, mixinName)
    end
end


Mixins.RegisterMixinFolder(MixinsFolder)
return Mixins