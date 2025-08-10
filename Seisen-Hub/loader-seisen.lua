warn("Seisen Hub - Cracked By Rwal :3")
MoonSec_StringsHiddenAttr = true
local fetchedData = {
    ["7546582051"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_DungeonHeroes.lua",
    ["7541395924"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_BuildanIsland.lua",
    ["4093155512"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_Swordburst3.lua",
    ["7882829745"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_AnimeEternal.lua",
    ["5995470825"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_HyperShot.lua"
}

local placeId = tostring(game.PlaceId)
local scriptUrl = fetchedData[placeId]

if scriptUrl then
    loadstring(game:HttpGet(scriptUrl))()
else
    warn("The Game Is Not Supported")
end
