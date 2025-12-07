---@meta Siuhnexus-BountyAPI
local public = {}

-- document whatever you made publicly available to other plugins here
-- use luaCATS annotations and give descriptions where appropriate
--  e.g. 
--	---@param a integer helpful description
--	---@param b string helpful description
--	---@return table c helpful description
--	function public.do_stuff(a, b) end

---@class BountyConfiguration Contains structured information about a custom chaos challenge (aka bounty)
---@field Id string The unique identifier this challenge will be recognized by. Make sure that this is unique (for example by prefixing it with your Thunderstore username). Using a non-unique identifier will result in bountys overwriting each other.
---@field Title string The title used for the in-game menu.
---@field Description string The text describing the challenge in the in-game menu.
---@field Difficulty? 1|2|3|4|5 The difficulty rating for this challenge. If not provided, it is set to 3.
---@field IsStandardBounty? boolean Whether this challenge should be treated like a chaos trial or not. For example, harvest points are disabled and story encounters do not happen in regular chaos trials. If not provided, this is set to true.
---@field SingleBiome? boolean If true, the challenge run will only take place in the biome specified by BiomeChar. If false (default), the run will start at the biome specified by BiomeChar and end like a regular run. 
---@field BiomeChar string Specifies the starting biome
---@field DataOverrides? ({ Table: table, Keys: string|string[], Values: any|any[] }[]) | fun(RegisterValues: TrackedValueRegisterer) If you want to safely apply overrides in game tables only for the duration of a run that get automatically applied when loading from a savefile. You can just pass the needed changes as a list if it is as simple as applying the changes when the challenge starts and removing them when it ends. Otherwise, define a function that uses the passed registerer to store the registered values for later use during the challenge. Example: If you want to add a few boons, the first method will suffice. If you want to scale enemy stats depending on the number of cleared biomes, you need to use the function variant.
---@field SetupFunctions? (fun(BountyRunData: table, FromSave: boolean): nil)[]|fun(BountyRunData: table, FromSave: boolean): nil All functions in this collection are called when the run starts from the crossroads ore from a savefile. The first argument is a table that gets persisted to savefiles and can thus be used to store values that can't be determined otherwise. If loaded from a save, the second argument to the functions will be set to true. 
---@field RoomTransition? fun(BountyRunData: table, RoomName: string): string|table|nil This function gets called when leaving a room. It is used mainly to manipulate which room gets chosen next, by returning the corresponding name or room data. The first argument is a table that gets persisted to savefiles and can thus be used to store values that can't be determined otherwise. The second argument is the name of the room that is currently being left.
---@field CanEnd? fun(BountyRunData: table, RoomName: string): boolean This function gets called when the game believes it is time to end the bounty run (in the boss room at the end of the biome/route). You can prevent the bounty from ending by returning false. If it is not set, this function will just return true to use the base game's behaviour.
---@field EndFunctions? (fun(BountyRunData: table, Cleared: boolean): nil)[]|fun(BountyRunData: table, Cleared: boolean): nil All functions in this collection are called when the run ends. The first argument is a table that gets persisted to savefiles and can thus be used to store values that can't be determined otherwise. The second argument is set to true if the challenge was cleared.
---@field BaseData? table Can be used to provide the bounty data in the format used by the BountyData script. This gets automatically generated if it is not provided. Do not set texts for the in-game menus in this table. Just use Title and Description.

---This method registers a custom bounty based on the passed specifications
---@param Configuration BountyConfiguration
public.RegisterBounty = function(Configuration) end

return public