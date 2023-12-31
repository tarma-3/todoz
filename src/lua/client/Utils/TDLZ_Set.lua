--- @class TDLZ_Set
--- @field _table table
--- @field _comparator function
TDLZ_Set = {}
TDLZ_Set.Type = "TDLZ_Set";

--- Check if set is empty
-- @return false if contains at least one element, false otherwise
function TDLZ_Set.isEmpty(tbl)
    for k, v in pairs(tbl) do
        return false
    end
    return true
end

---@generic T
---@param comparator? fun(a: T, b: T):boolean
---@return TDLZ_Set
function TDLZ_Set:new(comparator)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o._table = {}
    o._min = nil
    o._max = nil
    o._empty = true
    o._size = 0
    o._comparator = comparator
    return o
end

function TDLZ_Set:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = type;
    o._table = {}
    o._min = nil
    o._max = nil
    o._empty = true
    o._size = 0
    return o
end

function TDLZ_Set:addAll(elements)
    if not self:contains(elements) then self._size = self._size + 1 end
    --self._table[element] = true
    local sortedKeys = self:_getSortedKeys()
    self:_updateMin(sortedKeys)
    self:_updateMax(sortedKeys)
    self._empty = TDLZ_Set.isEmpty(self._table)
end

function TDLZ_Set:add(element)
    if not self:contains(element) then self._size = self._size + 1 end
    self._table[element] = true
    local sortedKeys = self:_getSortedKeys()
    self:_updateMin(sortedKeys)
    self:_updateMax(sortedKeys)
    self._empty = TDLZ_Set.isEmpty(self._table)
end

function TDLZ_Set:remove(element)
    if self:contains(element) then self._size = self._size - 1 end
    self._table[element] = nil
    local sortedKeys = self:_getSortedKeys()
    self:_updateMin(sortedKeys)
    self:_updateMax(sortedKeys)
    self._empty = TDLZ_Set.isEmpty(self._table)
end

function TDLZ_Set:size()
    return self._size
end

function TDLZ_Set:_getSortedKeys()
    if TDLZ_Set.isEmpty(self._table) then
        return nil
    end
    local a = {}
    for k, v in pairs(self._table) do
        table.insert(a, k)
    end
    if #a == 0 or type(a[1]) == "table" or type(a[1]) == "userdata" then
        -- assert(self._comparator ~= nil, "Comparator function not specified for data type 'table' or 'userdata'")
        -- table.sort(a, self._comparator)
        return a
    end

    table.sort(a)
    return a
end

function TDLZ_Set:contains(key)
    return self._table[key] ~= nil
end

function TDLZ_Set:_updateMax(sortedKeys)
    if sortedKeys == nil then
        self._max = nil
        return
    end
    self._max = sortedKeys[1 + #sortedKeys - 1]
end

function TDLZ_Set:_updateMin(sortedKeys)
    if sortedKeys == nil then
        self._min = nil
        return
    end
    self._min = sortedKeys[1]
end

function TDLZ_Set:toList()
    local rtn = {}
    for k, v in pairs(self._table) do
        table.insert(rtn, k)
    end
    return rtn
end
