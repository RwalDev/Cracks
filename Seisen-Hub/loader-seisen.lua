print("Seisen Hub - Cracked By Rwal :3")
MoonSec_StringsHiddenAttr = true
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Seisen Hub - Cracked",
    LoadingTitle = "Loading Seisen Hub...",
    LoadingSubtitle = "Cracked by Rwal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SeisenHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false
})

local ScriptsTab = Window:CreateTab("Scripts")

local scripts = {
    ["Dungeon Heroes"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_DungeonHeroes.lua",
    ["Build an Island"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_BuildanIsland.lua",
    ["Swordburst 3"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_Swordburst3.lua",
    ["Anime Eternal"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_AnimeEternal.lua",
    ["Hyper Shot"] = "https://raw.githubusercontent.com/RwalDev/Cracks/refs/heads/main/Seisen-Hub/Script_HyperShot.lua"
}

for name, url in pairs(scripts) do
    ScriptsTab:CreateButton({
        Name = name,
        Callback = function()
            pcall(function()
                loadstring(game:HttpGet(url))()
            end)
            Rayfield:ToggleUI()
        end
    })
end

local CreditsTab = Window:CreateTab("Credits")

CreditsTab:CreateParagraph({
    Title = "Cracked By",
    Content = "Rwal :3"
})

CreditsTab:CreateParagraph({
    Title = "Original Made By",
    Content = "Seisen"
})
