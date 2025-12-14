---@meta _

---Prefixes a given key string for use in global contexts (e. g. game tables)
---@param key string
---@return string
function PrefixGlobal(key)
    return "Siuhnexus_EndlessNight_" .. key
end

---@type (fun(): nil)[][]
local flushCallbacks = {}

---@class TrackedValue
---@field get fun(): any|nil Retrieves the current value assigned to the game table key if access is still granted
---@field set fun(value: any) Sets the value assigned to the game table key if access is still granted
---@field reset fun() Resets the value assigned to the game table key to its original value if access is still granted
---@field flush fun() Resets the value assigned to the game table key to its original value and prevents further actions (get, set, reset) using this instance. After calling this, free up memory by getting rid of references to this instance.

---@alias TrackedValueRegisterer fun(object: table, keys: string | string[]): TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue, TrackedValue Keeps track of changed values in game tables and provides an easy API to safely mutate and query them

---@type TrackedValueRegisterer
function RegisterValues(object, keys)
    ---@type (fun():nil)[]
    local flushes = {}
    ---@type TrackedValue[]
    local tracked = {}
    if type(keys) == "string" then keys = { keys } end

    for _, key in ipairs(keys) do
        local value = object[key]
        local invalidated = false
        local flush = function()
            if not invalidated then
                object[key] = value
                invalidated = true
            end
        end
        table.insert(flushes, flush)
        table.insert(tracked, {
            get = function ()
                if invalidated then
                    print("Attempted to get the value of a game table key while access has been revoked")
                    return
                end
                return object[key]
            end,
            set = function (value)
                if invalidated then
                    print("Attempted to set the value of a game table key while access has been revoked")
                    return
                end
                object[key] = value
            end,
            reset = function ()
                if invalidated then
                    print("Attempted to reset the value of a game table key while access has been revoked")
                    return
                end
                object[key] = value
            end,
            flush = flush
        })
    end

    table.insert(flushCallbacks, flushes)
    return table.unpack(tracked)
end

---Restores original values to all registered objects and locks them to prevent further changes
function RestoreDefaults()
    for _, clist in ipairs(flushCallbacks) do
        for _, invalidate in ipairs(clist) do
            invalidate()
        end
    end
    flushCallbacks = {}
end