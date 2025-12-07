# Bounty API

This mod serves as an API for other mods to use. It does nothing on its own. Use this mod to add custom challenges to the pitch-black stone in Hades 2. The functionality is documented using Lua annotations, so writing the following in your `main.lua` should give you autocomplete:
```lua
---@module "Siuhnexus-BountyAPI"
bountyAPI = mods["Siuhnexus-BountyAPI"]
```
Make sure to register your challenges only once when loading, so if you follow the structure of the mod template, just do something like this in your `ready.lua`:
```lua
bountyAPI.RegisterBounty({
    Id = "ModAuthor-ModName_SuperDuperChallenge",
    Title = "The Ultimate Challenge",
    Description = "Face every guardian at once",
    Difficulty = 5,
    IsStandardBounty = false,
    BiomeChar = "F",

    DataOverrides = function (RegisterValues)
        print("Overriding all the needed game tables for this challenge run...")
    end,
    SetupFunctions = function (BountyRunData, FromSave)
        if FromSave then
            print("Reacting to the data found in the persisted storage for this challenge run...")
        else
            print("Setting up the persisted data storage for this challenge run...")
        end
    end,
    RoomTransition = function (BountyRunData, RoomName)
        print("Room " .. RoomName .. " is being left. Choosing next room...")
    end,
    CanEnd = function (BountyRunData, RoomName)
        print("Determining whether this challenge run should end")
        return true
    end,
    EndFunctions = function (BountyRunData, Cleared)
        print("Challenge run is ending. Cleaning up...")
    end
})
```
If you have questions/ideas/weird bugs, feel free to open an issue or a pr.