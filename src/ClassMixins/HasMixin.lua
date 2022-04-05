local HasMixin = {}


function HasMixin.Add(class)
    assert(class.HasMixin == nil, "class already has an HasMixin method")
    assert(class.HasAnyMixins == nil, "class already has an HasAnyMixins method")
    assert(class.HasAllMixins == nil, "class already has an HasAllMixins method")

    assert(class.ClassName, "class must have a ClassName")
    assert(typeof(class.ClassName) == "string", "class' ClassName must be a string")

	class.HasMixin = HasMixin.HasMixin
	class.HasAnyMixins = HasMixin.HasAnyMixins
	class.HasAllMixins = HasMixin.HasAllMixins
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


function HasMixin:HasMixin(mixinName)
	return checkForMixin(self, mixinName)
end


function HasMixin:HasAnyMixins(mixins)
    assert(typeof(mixins) == "table" and next(mixins) ~= nil, "'mixins' must be a table and not be empty")

    local hasAny, mixinNames = false, {}
    for _, mixinName in pairs(mixins) do
        if (checkForMixin(self, mixinName)) then
            hasAny = true
            table.insert(mixinNames, mixinName)
        end
    end

    return hasAny, mixinNames
end


function HasMixin:HasAllMixins(mixins)
    assert(typeof(mixins) == "table" and next(mixins) ~= nil, "'mixins' must be a table and not be empty")

    local hasAll, amount = false, 0
    for _, mixinName in pairs(mixins) do
        if (checkForMixin(self, mixinName)) then
            amount += 1
        end
    end

    if (amount == #mixins) then
        hasAll = true
    end

    return hasAll
end


return HasMixin