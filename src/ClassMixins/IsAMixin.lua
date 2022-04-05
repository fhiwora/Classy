local IsAMixin = {}


function IsAMixin.Add(class)
    assert(class.IsA == nil, "class already has an IsA method")
    assert(class.ClassName, "class must have a ClassName")
    assert(typeof(class.ClassName) == "string", "class' ClassName must be a string")

    class.IsA = IsAMixin.IsA
end


function IsAMixin:IsA(className)
	assert(typeof(className) == "string", "'className' must be a string!")
	if (self.ClassName == className) then return true end

	local super = self.Super
	while (super) do
		if (super.ClassName == className) then
			return true
		end
		super = super.Super
	end

	return false
end


return IsAMixin