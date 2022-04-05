local ERRORS = {
    MustBe = "'%s' must be a %s";
    MustNotBeEmpty = "'%s' must not be empty";

    ExistentItem = "%s '%s' already exists";
    NonexistentItem = "%s '%s' doesn't exist";
}


local function getErrString(errorName, ...)
    assert(typeof(errorName) == "string", ERRORS.MustBe:format("errorName", "string"))
    local err = ERRORS[errorName]
    if (not err) then return error(ERRORS.NonexistentItem:format("Error", errorName)) end

    local t = {...}
    for i, v in ipairs(t) do
        t[i] = tostring(v)
    end

    return err:format(table.unpack(t))
end


local function report(errorName, ...)
    assert(typeof(errorName) == "string", ERRORS.MustBe:format("errorName", "string"))
    return error(getErrString(errorName, ...))
end


local function state(equality, errorName, ...)
    assert(typeof(errorName) == "string", ERRORS.MustBe:format("errorName", "string"))
    return assert(equality, getErrString(errorName, ...))
end


return {
    Report = report;
    State = state;
}