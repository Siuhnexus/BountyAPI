---@meta Siuhnexus-BountyAPI

import "modules/safeGameTableModifier.lua"

function prefix(key)
    return "Siuhnexus-BountyAPI_" .. key
end

local HelpTextFile = rom.path.combine(rom.paths.Content, "Game/Text/en/HelpText.en.sjson")

local Order = {
	"Id",
	"Name",
	"InheritFrom",
	"DisplayName",
	"Description",
	"DisplayInEditor",
	"Thing",
	"ChildAnimation",
	"CreateAnimation",
	"CreateAnimations",
	"Color",
	"FilePath",
	"OffsetX",
	"OffsetY",
	"OffsetZ",
	"Scale",
	"Hue",
	"StartFrame",
	"EndFrame",
	"NumFrames",
	"PlaySpeed",
	"ColorFromOwner",
	"AngleFromOwner",
	"Sound",
	"StartRed",
	"StartGreen",
	"StartBlue",
	"EndRed",
	"EndGreen",
	"EndBlue",
	"VisualFx",
	"Duration",
	"StartOffsetZ",
	"EndOffsetZ",
	"PingPongShiftOverDuration",
	"AmbientSound",
	"Graphic",
	"EditorOutlineDrawBounds",
}

---@type {[string]: BountyConfiguration}
RegisteredCustomBounties = {}
BountyDataStorage = prefix("CustomBountyStorage")
CustomBountyActive = false

BiomeToEncounters = {
    F = "HecateEncounters",
    G = "ScyllaEncounters",
    H = "InfestedCerberusEncounters",
    I = "ChronosEncounters",
    N = "PolyphemusEncounters",
    O = "ErisEncounters",
    P = "PrometheusEncounters",
    Q = "TyphonEncounters"
}

---This method registers a custom bounty based on the passed specifications
---@param Configuration BountyConfiguration
public.RegisterBounty = function(Configuration)
    if Configuration == nil or type(Configuration) ~= "table" then
        print("Bounty could not be registered: No configuration or faulty configuration")
        return
    end
    if Configuration.Difficulty == nil then Configuration.Difficulty = 3 end
    if Configuration.IsStandardBounty == nil then Configuration.IsStandardBounty = true end
    if Configuration.SingleBiome == nil then Configuration.SingleBiome = false end
    if Configuration.BiomeChar == nil then print("Bounty registration failed: A starting biome has not been provided"); return end
    if Configuration.DataOverrides == nil then Configuration.DataOverrides = {} end
    if Configuration.SetupFunctions == nil then Configuration.SetupFunctions = {}
    elseif type(Configuration.SetupFunctions) ~= "table" then Configuration.SetupFunctions = { Configuration.SetupFunctions } end
    if Configuration.RoomTransition == nil then Configuration.RoomTransition = function() end end
    if Configuration.CanEnd == nil then Configuration.CanEnd = function() return true end end
    if Configuration.EndFunctions == nil then Configuration.EndFunctions = {}
    elseif type(Configuration.EndFunctions) ~= "table" then Configuration.EndFunctions = { Configuration.EndFunctions } end
    if Configuration.Title == nil or Configuration.Description == nil then print("Bounty registration failed: Title or Description were not provided"); return end

    local encounters = BiomeToEncounters[Configuration.BiomeChar]
    if not Configuration.SingleBiome then
        local c = Configuration.BiomeChar
        encounters = (c == "F" or c == "G" or c == "H" or c == "I") and BiomeToEncounters.I or BiomeToEncounters.Q
    end
    if Configuration.BaseData == nil then
        Configuration.BaseData = {
            InheritFrom = { "DefaultPackagedBounty", encounters }
        }
    else
        if Configuration.BaseData.InheritFrom == nil then
            Configuration.BaseData.InheritFrom = { "DefaultPackagedBounty" }
        end
        table.insert(Configuration.BaseData.InheritFrom, encounters)
    end
    if Configuration.BaseData.DifficultyRating == nil then Configuration.BaseData.DifficultyRating = Configuration.Difficulty end
    if Configuration.BaseData.ForcedReward == nil and Configuration.BaseData.LootOptions == nil then
		Configuration.BaseData.LootOptions =
		{
			{
				Name = "GemPointsBigDrop",
				Overrides =
				{
					CanDuplicate = false,
				}
			},
		}
    end
    if Configuration.BaseData.StartingBiome == nil then
        Configuration.BaseData.StartingBiome = Configuration.BiomeChar
    end

    local name = prefix(Configuration.Id)
    Configuration.BaseData.Name = name
    Configuration.BaseData.Text = name .. "_Short"
    sjson.hook(HelpTextFile, function(data)
        table.insert(data.Texts, sjson.to_object({
            Id = name,
            DisplayName = Configuration.Title,
            Description = "\n" .. Configuration.Description .. "\n"
        }, Order))
        table.insert(data.Texts, sjson.to_object({
            Id = name .. "_Short",
            DisplayName = Configuration.Title
        }, Order))
    end)
    ProcessDataInheritance(Configuration.BaseData, BountyData)
    ProcessSimpleExtractValues(Configuration.BaseData)
    BountyData[name] = Configuration.BaseData
    for _, data in ipairs(ScreenData.BountyBoard.ItemCategories) do
        table.insert(data, name)
    end

    if not Configuration.IsStandardBounty then
        for _, req in ipairs(NamedRequirementsData.StandardPackageBountyActive) do
            if req.IsNone ~= nil then
                table.insert(req.IsNone, name)
            end
        end
    end
    RegisteredCustomBounties[name] = Configuration
end



---Registers the needed data overrides for the run
---@param toRegister { Table: table, Keys: string|string[], Values: any|any[] }[]
function registerGameTableOverrides(toRegister)
    for _, data in ipairs(toRegister) do
        if type(data.Keys) ~= "table" then data.Keys = { data.Keys } end
        if type(data.Values) ~= "table" then data.Values = { data.Values } end
        if #data.Keys ~= #data.Values then
            print("For every key in the data overrides, there has to be a value and vice versa. Aborting data overrides.")
            return
        end
        ---@type TrackedValue[]
        local valueAccess = table.pack(RegisterValues(data.Table, data.Keys))
        for i, v in ipairs(valueAccess) do
            v.set(data.Values[i])
        end
    end
end

modutil.mod.Path.Wrap("MapStateInit", function (base, ...)
    if CustomBountyActive or CurrentRun == nil or CurrentRun.Hero == nil or CurrentRun.Hero.IsDead or CurrentRun.ActiveBounty == nil then return base(...) end
    local bountyConfig = RegisteredCustomBounties[CurrentRun.ActiveBounty]
    if bountyConfig == nil then return base(...) end

    if type(bountyConfig.DataOverrides) == "function" then
        bountyConfig.DataOverrides(RegisterValues)
    else
        registerGameTableOverrides(bountyConfig.DataOverrides)
    end

    local store = CurrentRun[BountyDataStorage]
    for _, fun in ipairs(bountyConfig.SetupFunctions) do
        fun(store, true)
    end
    CustomBountyActive = true
    return base(...)
end)

modutil.mod.Path.Wrap("StartNewRun", function(base, currentRun, args)
    if args.ActiveBounty == nil then return base(currentRun, args) end
    local bountyConfig = RegisteredCustomBounties[args.ActiveBounty]
    if bountyConfig == nil then return base(currentRun, args) end

    local configData = bountyConfig.BaseData or {}
    -- Fix arcana to be currently selected set if nothing else is specified
    if configData.MetaUpgradeStateEquipped == nil and configData.RandomMetaUpgradeCostTotal == nil and StoredGameState ~= nil then
        GameState.MetaUpgradeState = DeepCopyTable(StoredGameState.MetaUpgradeState)
        GetCurrentMetaUpgradeCost()
        print("Reequipped selected arcana set")
    end
    -- Fix fear to be currently selected set if nothing else is specified
    if configData.ShrineUpgradesActive == nil and configData.RandomShrineUpgradePointTotal == nil and StoredGameState ~= nil then
        GameState.ShrineUpgrades = ShallowCopyTable(StoredGameState.ShrineUpgrades)
        print("Reselected chosen fear")
    end

    local result = base(currentRun, args)

    if type(bountyConfig.DataOverrides) == "function" then
        bountyConfig.DataOverrides(RegisterValues)
    else
        registerGameTableOverrides(bountyConfig.DataOverrides)
    end

    local store = {}
    for _, fun in ipairs(bountyConfig.SetupFunctions) do
        fun(store, false)
    end
    CurrentRun[BountyDataStorage] = store
    CustomBountyActive = true

    return result
end)

modutil.mod.Path.Wrap("LeaveRoom", function(base, currentRun, door)
    if CurrentRun == nil or CurrentRun.ActiveBounty == nil then return base(currentRun, door) end
    local bountyConfig = RegisteredCustomBounties[CurrentRun.ActiveBounty]
    if bountyConfig == nil then return base(currentRun, door) end

    local result = bountyConfig.RoomTransition(CurrentRun[BountyDataStorage], CurrentRun.CurrentRoom.Name)
    if result ~= nil then
        if type(result) == "table" then
            door.Room = result
        else
            door.Room = CreateRoom(RoomData[result])
        end
    end
    return base(currentRun, door)
end)

modutil.mod.Path.Wrap("CheckPackagedBountyCompletion", function(base, ...)
    if CurrentRun == nil or CurrentRun.ActiveBounty == nil then return base(...) end
    local bountyConfig = RegisteredCustomBounties[CurrentRun.ActiveBounty]
    if bountyConfig == nil then return base(...) end

    if not bountyConfig.CanEnd(CurrentRun[BountyDataStorage], CurrentRun.CurrentRoom.Name) then return false end
    return base(...)
end)

modutil.mod.Path.Wrap("OpenRunClearScreen", function(base, ...)
    if CurrentRun == nil or CurrentRun.ActiveBounty == nil then return base(...) end
    local bountyConfig = RegisteredCustomBounties[CurrentRun.ActiveBounty]
    if bountyConfig == nil then return base(...) end

    if not bountyConfig.CanEnd(CurrentRun[BountyDataStorage], CurrentRun.CurrentRoom.Name) then return end
    return base(...)
end)

modutil.mod.Path.Wrap("KillHero", function(base, ...)
    if CurrentRun == nil or CurrentRun.ActiveBounty == nil then return base(...) end
    local bountyConfig = RegisteredCustomBounties[CurrentRun.ActiveBounty]
    if bountyConfig == nil then return base(...) end

    local store = CurrentRun[BountyDataStorage]
    local cleared = CurrentRun.BountyCleared
    for _, fun in ipairs(bountyConfig.EndFunctions) do
        fun(store, cleared)
    end
    RestoreDefaults()
    CustomBountyActive = false
    return base(...)
end)