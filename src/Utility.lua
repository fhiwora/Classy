local function copyTable(t)
    local n = {}
    for i, v in pairs(t) do
        if (typeof(v) == "table") then
            n[i] = copyTable(v)
        else
            n[i] = v
        end
    end
    return n
end


return {
    CopyTable = copyTable;
}