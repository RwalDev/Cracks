-- Obsidian UI Example Script
-- Make sure you are running this in an environment that supports Obsidian UI (e.g., Roblox with a Lua executor)

-- Load the Obsidian UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

-- Create a comprehensive cleanup system to track all connections and tasks
local _SCRIPT_CONNECTIONS = {}
local _SCRIPT_TASKS = {}
local _CLEANUP_COMPLETED = false

-- Helper function to track connections
local function trackConnection(connection, name)
    if connection and typeof(connection) == "RBXScriptConnection" then
        _SCRIPT_CONNECTIONS[name or "unnamed"] = connection
        return connection
    end
    return connection
end

-- Helper function to track tasks  
local function trackTask(task, name)
    if task then
        _SCRIPT_TASKS[name or "unnamed"] = task
        return task
    end
    return task
end

-- Services (move to top for global use)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Combat = RS:WaitForChild("Systems", 9e9):WaitForChild("Combat", 9e9):WaitForChild("PlayerAttack", 9e9)
local Effects = RS:WaitForChild("Systems", 9e9):WaitForChild("Effects", 9e9):WaitForChild("DoEffect", 9e9)
local Skills = RS:WaitForChild("Systems", 9e9):WaitForChild("Skills", 9e9):WaitForChild("UseSkill", 9e9)
local SkillAttack = RS:WaitForChild("Systems", 9e9):WaitForChild("Combat", 9e9):WaitForChild("PlayerSkillAttack", 9e9)
local mobFolder = workspace:WaitForChild("Mobs", 9e9)
local VirtualUser = game:GetService("VirtualUser")
local PlayerData = {player = Players.LocalPlayer}
local connections = connections or {}
local AntiAfkSystem = {
    setup = function()
        local conn = PlayerData.player.Idled:Connect(function()
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
        table.insert(connections, conn)
    end,
    cleanup = function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
    end
}

AntiAfkSystem.setup()

-- Try to get the skill system module
local skillSystem = nil
local profileSystem = nil
pcall(function()
    skillSystem = require(RS:WaitForChild("Systems", 9e9):WaitForChild("Skills", 9e9))
    profileSystem = require(RS:WaitForChild("Systems", 9e9):WaitForChild("Profile", 9e9))
end)

local LocalPlayer = Players.LocalPlayer

-- Global variables for character references
local Character = nil
local HRP = nil

-- Auto skill configuration
local CONFIG = {
    SKILL_SLOTS = {1, 2, 3, 4}, -- Skill slots to use
    FALLBACK_COOLDOWN = 2, -- Fallback cooldown if skill data not found
    SKILL_CHECK_INTERVAL = 0.5, -- How often to check for skills (faster for better responsiveness)
    SKILL_RANGE = 500, -- Range to use skills
}

-- Runtime state for auto skill
local RuntimeState = {
    autoSkillEnabled = false,
    lastUsed = {}, -- Track last time each skill was used
    skillData = {}, -- Store skill data
    selectedSkills = {}, -- Store selected skills
    skillToggles = {}, -- Store enabled/disabled state for each skill
}


local configFolder = "SeisenHub"
local configFile = configFolder .. "/seisen_hub_dh.txt"
local HttpService = game:GetService("HttpService")

-- Ensure folder exists
if not isfolder(configFolder) then
    makefolder(configFolder)
end

-- Default config
local config = {
    killAuraEnabled = false,
    autoStartDungeon = false,
    autoReplyDungeon = false,
    autoNextDungeon = false,
    autoFarmEnabled = false,
    autoSkillEnabled = false,
    autoMiniBossEnabled = false,
    skillToggles = {}, -- [skillName] = true/false
    dungeonSequenceIndex = 1,
    normalDungeonName = "Shattered Forest lvl 1+",
    normalDungeonDifficulty = "Normal",
    normalDungeonPlayerLimit = 1,
    raidDungeonName = "Abyssal Depths",
    raidDungeonDifficulty = "RAID",
    raidDungeonPlayerLimit = 7,
    eventDungeonName = "Gauntlet",
    eventDungeonDifficulty = "Normal",
    eventDungeonPlayerLimit = 4,
    completedDungeons = {}, -- [dungeonName_difficulty] = true
    autoReplyDungeon = false,
    autoClaimDailyQuest = false,
    autoEquipHighestWeapon = false,
    fpsBoostEnabled = false,
    maxfpsBoostenabled = false,
    supermaxfpsBoostenabled = false,
    autoSellEnabled = false,
    autoSellRarity = "Common",
    customCursorEnabled = true,
}

-- Load config if file exists
if isfile(configFile) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            config[k] = v
        end
    end
end

-- Helper to save config
local function saveConfig()
    writefile(configFile, HttpService:JSONEncode(config))
end

-- Now, use config values as your defaults:
_G.killAuraEnabled = config.killAuraEnabled
autoStartDungeon = config.autoStartDungeon
autoReplyDungeon = config.autoReplyDungeon
autoNextDungeon = config.autoNextDungeon
autoFarmEnabled = config.autoFarmEnabled
autoMiniBossEnabled = config.autoMiniBossEnabled
RuntimeState = RuntimeState or {}
RuntimeState.autoSkillEnabled = config.autoSkillEnabled
RuntimeState.skillToggles = config.skillToggles or {}
dungeonSequenceIndex = config.dungeonSequenceIndex or 1
normalDungeonName = config.normalDungeonName
normalDungeonDifficulty = config.normalDungeonDifficulty
normalDungeonPlayerLimit = config.normalDungeonPlayerLimit
raidDungeonName = config.raidDungeonName
raidDungeonDifficulty = config.raidDungeonDifficulty
raidDungeonPlayerLimit = config.raidDungeonPlayerLimit
eventDungeonName = config.eventDungeonName
eventDungeonDifficulty = config.eventDungeonDifficulty
eventDungeonPlayerLimit = config.eventDungeonPlayerLimit
autoReplyDungeon = config.autoReplyDungeon
autoClaimDailyQuest = config.autoClaimDailyQuest
autoEquipHighestWeapon = config.autoEquipHighestWeapon
fpsBoostEnabled = config.fpsBoostEnabled
supermaxfpsBoostenabled = config.supermaxfpsBoostenabled
maxfpsBoostenabled = config.maxfpsBoostenabled
autoSellEnabled = config.autoSellEnabled or false
selectedRarity = config.autoSellRarity or "Common"

-- Skill table data (from your provided table)
local function initializeSkillData()
    RuntimeState.skillData = {
        ["Whirlwind"] = {
            ["DisplayName"] = "Whirlwind",
            ["Cooldown"] = 6,
            ["UseLength"] = 1.9,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.7},
                {["Type"] = "Normal", ["Damage"] = 0.7},
                {["Type"] = "Normal", ["Damage"] = 0.7},
                {["Type"] = "Normal", ["Damage"] = 0.7},
                {["Type"] = "Normal", ["Damage"] = 0.7},
                {["Type"] = "Normal", ["Damage"] = 0.7}
            }
        },
        ["FerociousRoar"] = {
            ["DisplayName"] = "Ferocious Roar",
            ["Cooldown"] = 9,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5}
            }
        },
        ["Rumble"] = {
            ["DisplayName"] = "Rumble",
            ["Cooldown"] = 10,
            ["UseLength"] = 1.2,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 4},
                {["Type"] = "Normal", ["Damage"] = 4},
                {["Type"] = "Normal", ["Damage"] = 4},
                {["Type"] = "Normal", ["Damage"] = 4},
                {["Type"] = "Normal", ["Damage"] = 4}
            }
        },
        ["PiercingWave"] = {
            ["DisplayName"] = "Piercing Wave",
            ["Cooldown"] = 8,
            ["UseLength"] = 0.7,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.8},
                {["Type"] = "Normal", ["Damage"] = 2.8},
                {["Type"] = "Normal", ["Damage"] = 2.8},
                {["Type"] = "Normal", ["Damage"] = 2.8},
                {["Type"] = "Normal", ["Damage"] = 2.8}
            }
        },
        ["Fireball"] = {
            ["DisplayName"] = "Fireball",
            ["Cooldown"] = 8,
            ["UseLength"] = 1.2,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 4}
            }
        },
        ["DrillStrike"] = {
            ["DisplayName"] = "Drill Strike",
            ["Cooldown"] = 9,
            ["UseLength"] = 1,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5},
                {["Type"] = "Normal", ["Damage"] = 3.5}
            }
        },
        ["FireBreath"] = {
            ["DisplayName"] = "Fire Breath",
            ["Cooldown"] = 13,
            ["UseLength"] = 3.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2}
            }
        },
        ["FrenziedStrike"] = {
            ["DisplayName"] = "Frenzied Strike",
            ["Cooldown"] = 14,
            ["UseLength"] = 2.6,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5}
            }
        },
        ["Eruption"] = {
            ["DisplayName"] = "Eruption",
            ["Cooldown"] = 16,
            ["UseLength"] = 4,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 8}
            }
        },
        ["SerpentStrike"] = {
            ["DisplayName"] = "Serpent Strike",
            ["Cooldown"] = 10,
            ["UseLength"] = 1.6,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5},
                {["Type"] = "Normal", ["Damage"] = 2.5}
            }
        },
        ["Cannonball"] = {
            ["DisplayName"] = "Cannonball",
            ["Cooldown"] = 12,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 3}
            }
        },
        ["Skybreaker"] = {
            ["DisplayName"] = "Skybreaker",
            ["Cooldown"] = 8,
            ["UseLength"] = 1.6,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5}
            }
        },
        ["Eviscerate"] = {
            ["DisplayName"] = "Eviscerate",
            ["Cooldown"] = 16,
            ["UseLength"] = {1.7, 0.6, 0.6},
            ["CanMultiHit"] = true,
            ["NumCharges"] = 3,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2}
            }
        },
        ["Thunderclap"] = {
            ["DisplayName"] = "Thunderclap",
            ["Cooldown"] = 11,
            ["UseLength"] = 2.3,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 3}
            }
        },
        ["HammerStorm"] = {
            ["DisplayName"] = "Hammer Storm",
            ["Cooldown"] = 18,
            ["UseLength"] = 2.4,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 13},
                {["Type"] = "Normal", ["Damage"] = 7},
                {["Type"] = "Normal", ["Damage"] = 4},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 1}
            }
        },
        -- Added Frost Arc
        ["FrostArc"] = {
            ["DisplayName"] = "Frost Arc",
            ["Cooldown"] = 10,
            ["UseLength"] = 0.7,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {
                    ["Type"] = "Normal",
                    ["Damage"] = 2.5,
                    ["Status"] = "Chilled",
                    ["StatusDuration"] = 3
                }
            }
        },
        ["HolyLight"] = {
            ["DisplayName"] = "Holy Light",
            ["Cooldown"] = 25,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = false,
            ["Hits"] = {},
            ["DamagePerRarity"] = 0.5,
            ["PreloadAnimation"] = "HolyLight"
        },
        ["Whirlpool"] = {
            ["DisplayName"] = "Whirlpool",
            ["Cooldown"] = 22,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05},
                {["Type"] = "Normal", ["Damage"] = 0.75, ["Status"] = "Slow", ["StatusDuration"] = 1.05}
            },
            ["DamagePerRarity"] = 0.25,
            ["PreloadAnimation"] = "Whirlpool"
        },
        ["MeteorShower"] = {
            ["DisplayName"] = "Meteor Shower",
            ["Cooldown"] = 20,
            ["UseLength"] = 2.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Magic", ["Damage"] = 3.5},
                {["Type"] = "Magic", ["Damage"] = 3.5},
                {["Type"] = "Magic", ["Damage"] = 3.5},
                {["Type"] = "Magic", ["Damage"] = 3.5},
                {["Type"] = "Magic", ["Damage"] = 3.5}
            },
            ["PreloadAnimation"] = "MeteorShower"
        },
        ["ShadowStrike"] = {
            ["DisplayName"] = "Shadow Strike",
            ["Cooldown"] = 12,
            ["UseLength"] = 1.1,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Dark", ["Damage"] = 5, ["Status"] = "Blind", ["StatusDuration"] = 2}
            },
            ["PreloadAnimation"] = "ShadowStrike"
        },
        ["Berserk"] = {
            ["DisplayName"] = "Berserk",
            ["Cooldown"] = 18,
            ["UseLength"] = 2,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Rage", ["StatusDuration"] = 5}
            },
            ["PreloadAnimation"] = "Berserk"
        },
        ["ChainHeal"] = {
            ["DisplayName"] = "Chain Heal",
            ["Cooldown"] = 20,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {}, -- Healing skill, no damage
            ["PreloadAnimation"] = "ChainHeal"
        },
        ["ChainLightning"] = {
            ["DisplayName"] = "Chain Lightning",
            ["Cooldown"] = 14,
            ["UseLength"] = 1.7,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Magic", ["Damage"] = 2.8},
                {["Type"] = "Magic", ["Damage"] = 2.2},
                {["Type"] = "Magic", ["Damage"] = 1.6}
            },
            ["PreloadAnimation"] = "ChainLightning"
        },
        ["FlameRider"] = {
            ["DisplayName"] = "Flame Rider",
            ["Cooldown"] = 16,
            ["UseLength"] = 2.2,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Fire", ["Damage"] = 3.5},
                {["Type"] = "Fire", ["Damage"] = 3.5}
            },
            ["PreloadAnimation"] = "FlameRider"
        },
        ["MagicMissiles"] = {
            ["DisplayName"] = "Magic Missiles",
            ["Cooldown"] = 10,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 1},
                {["Type"] = "Normal", ["Damage"] = 1},
                {["Type"] = "Normal", ["Damage"] = 1},
                {["Type"] = "Normal", ["Damage"] = 1},
                {["Type"] = "Normal", ["Damage"] = 1}
            },
            ["PreloadAnimation"] = "MagicMissiles"
        },
        ["SelfHeal"] = {
            ["DisplayName"] = "Self Heal",
            ["Cooldown"] = 18,
            ["UseLength"] = 1.1,
            ["CanMultiHit"] = false,
            ["Hits"] = {}, -- Healing skill, no damage
            ["PreloadAnimation"] = "SelfHeal"
        },
        ["MeteorStorm"] = {
            ["DisplayName"] = "Meteor Storm",
            ["Cooldown"] = 26,
            ["UseLength"] = 1.6,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.25},
                {["Type"] = "Normal", ["Damage"] = 2.25},
                {["Type"] = "Normal", ["Damage"] = 2.25},
                {["Type"] = "Normal", ["Damage"] = 2.25},
                {["Type"] = "Normal", ["Damage"] = 2.25},
                {["Type"] = "Normal", ["Damage"] = 2.25}
            },
            ["DamagePerRarity"] = 0.6,
            ["PreloadAnimation"] = "MeteorStorm"
        },
        ["PantherPounce"] = {
            ["DisplayName"] = "Panther Pounce",
            ["Cooldown"] = 8,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 4, ["Status"] = "Punctured", ["StatusDuration"] = 5}
            }
        },
        ["NaturesGrasp"] = {
            ["DisplayName"] = "Nature's Grasp",
            ["Cooldown"] = 10,
            ["UseLength"] = 1.1,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2, ["Status"] = "Snare", ["StatusDuration"] = 4}
            }
        },
        ["CallOfTheWild"] = {
            ["DisplayName"] = "Call of the Wild",
            ["Cooldown"] = 12,
            ["UseLength"] = 1.1,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["PartyAnimal"] = {
            ["DisplayName"] = "Party Animal",
            ["Cooldown"] = 24,
            ["UseLength"] = 2,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["MonkeyKing"] = {
            ["DisplayName"] = "Monkey King",
            ["Cooldown"] = 15,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Heal", ["Damage"] = 2.5},
                {["Type"] = "Heal", ["Damage"] = 2.5},
                {["Type"] = "Heal", ["Damage"] = 2.5},
                {["Type"] = "Heal", ["Damage"] = 2.5},
                {["Type"] = "Heal", ["Damage"] = 2.5},
                {["Type"] = "Heal", ["Damage"] = 2.5}
            }
        },
        ["Skybreaker"] = {
            ["DisplayName"] = "Skybreaker",
            ["Cooldown"] = 8,
            ["UseLength"] = 1.6,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5}
            }
        },
        ["ConsecutiveLightning"] = {
            ["DisplayName"] = "Consecutive Lightning",
            ["Cooldown"] = 21,
            ["UseLength"] = {0.3, 0.4, 0.25, 0.35, 0.5},
            ["CanMultiHit"] = true,
            ["NumCharges"] = 5,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "ElectricShock", ["StatusDuration"] = 8}
            }
        },
        ["Eviscerate"] = {
            ["DisplayName"] = "Eviscerate",
            ["Cooldown"] = 16,
            ["UseLength"] = {1.7, 0.6, 0.6},
            ["CanMultiHit"] = true,
            ["NumCharges"] = 3,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2}
            }
        },
        ["Supercharge"] = {
            ["DisplayName"] = "Supercharge",
            ["Cooldown"] = 25,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["MagicCircle"] = {
            ["DisplayName"] = "Magic Circle",
            ["Cooldown"] = 22,
            ["UseLength"] = 2.4,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["SelfHeal"] = {
            ["DisplayName"] = "Self Heal",
            ["Cooldown"] = 15,
            ["UseLength"] = 1,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Heal", ["Damage"] = 3, ["CannotCrit"] = true}
            }
        },
        ["DivineIntervention"] = {
            ["DisplayName"] = "Divine Intervention",
            ["Cooldown"] = 26,
            ["UseLength"] = 2,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Heal", ["Damage"] = 1.5},
                {["Type"] = "Heal", ["Damage"] = 1.5},
                {["Type"] = "Heal", ["Damage"] = 1.5},
                {["Type"] = "Heal", ["Damage"] = 1.5},
                {["Type"] = "Heal", ["Damage"] = 1.5}
            }
        },
        ["SolarRay"] = {
            ["DisplayName"] = "Solar Ray",
            ["Cooldown"] = 14,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5.5}
            }
        },
        ["ArcaneBlast"] = {
            ["DisplayName"] = "Arcane Blast",
            ["Cooldown"] = 16,
            ["UseLength"] = 2.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5}
            }
        },
        ["DeathsGrasp"] = {
            ["DisplayName"] = "Death's Grasp",
            ["Cooldown"] = 25,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Normal", ["Damage"] = 2},
                {["Type"] = "Heal", ["Damage"] = 0.3, ["CannotCrit"] = true},
                {["Type"] = "Heal", ["Damage"] = 0.3, ["CannotCrit"] = true},
                {["Type"] = "Heal", ["Damage"] = 0.3, ["CannotCrit"] = true},
                {["Type"] = "Heal", ["Damage"] = 0.3, ["CannotCrit"] = true}
            }
        },
        ["IcyBlast"] = {
            ["DisplayName"] = "Icy Blast",
            ["Cooldown"] = 8,
            ["UseLength"] = 1.35,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 2.5, ["Status"] = "Chilled", ["StatusDuration"] = 3}
            }
        },
        ["MysticChains"] = {
            ["DisplayName"] = "Mystic Chains",
            ["Cooldown"] = 15,
            ["UseLength"] = 1.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 1.25, ["Status"] = "Slow", ["StatusDuration"] = 5},
                {["Type"] = "Normal", ["Damage"] = 1.25},
                {["Type"] = "Normal", ["Damage"] = 1.25},
                {["Type"] = "Normal", ["Damage"] = 1.25},
                {["Type"] = "Normal", ["Damage"] = 1.25}
            }
        },
        ["EarthEruption"] = {
            ["DisplayName"] = "Earth Eruption",
            ["Cooldown"] = 25,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4},
                {["Type"] = "Normal", ["Damage"] = 0.5, ["Status"] = "Burn", ["StatusDuration"] = 0.4}
            }
        },
        ["EarthRain"] = {
            ["DisplayName"] = "Earth Rain",
            ["Cooldown"] = 28,
            ["UseLength"] = 3.1,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5}
            }
        },
        ["EarthRipple"] = {
            ["DisplayName"] = "Earth Ripple",
            ["Cooldown"] = 15,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Slow", ["StatusDuration"] = 3}
            }
        },
        ["Severance"] = {
            ["DisplayName"] = "Severance",
            ["Cooldown"] = 20,
            ["UseLength"] = 3.3,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 9}
            }
        },
        ["CrystalChaos"] = {
            ["DisplayName"] = "Crystal Chaos",
            ["Cooldown"] = 15,
            ["UseLength"] = 2,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 4.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 4.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 4.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 4.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 4.5, ["Status"] = "Stun", ["StatusDuration"] = 3}
            }
        },
        ["TitansGrasp"] = {
            ["DisplayName"] = "Titan's Grasp",
            ["Cooldown"] = 18,
            ["UseLength"] = 1.4,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 8},
                {["Type"] = "Normal", ["Damage"] = 8},
                {["Type"] = "Normal", ["Damage"] = 8},
                {["Type"] = "Normal", ["Damage"] = 8},
                {["Type"] = "Normal", ["Damage"] = 8}
            }
        },
        ["BladeStorm"] = {
            ["DisplayName"] = "Blade Storm",
            ["Cooldown"] = 15,
            ["UseLength"] = 1.35,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.35},
                {["Type"] = "Normal", ["Damage"] = 0.35},
                {["Type"] = "Normal", ["Damage"] = 0.35},
                {["Type"] = "Normal", ["Damage"] = 0.35},
                {["Type"] = "Normal", ["Damage"] = 0.35},
                {["Type"] = "Normal", ["Damage"] = 0.35}
            }
        },
        ["MushroomBounce"] = {
            ["DisplayName"] = "Mushroom Bounce",
            ["Cooldown"] = 10,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 2.75}
            }
        },
        ["Grovebreaker"] = {
            ["DisplayName"] = "Grovebreaker",
            ["Cooldown"] = 14,
            ["UseLength"] = 2.1,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Punctured", ["StatusDuration"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Punctured", ["StatusDuration"] = 5},
                {["Type"] = "Normal", ["Damage"] = 5, ["Status"] = "Punctured", ["StatusDuration"] = 5}
            }
        },
        ["RootQuake"] = {
            ["DisplayName"] = "Root Quake",
            ["Cooldown"] = 15,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 3.5, ["Status"] = "Slow", ["StatusDuration"] = 4},
                {["Type"] = "Normal", ["Damage"] = 3.5, ["Status"] = "Slow", ["StatusDuration"] = 4},
                {["Type"] = "Normal", ["Damage"] = 3.5, ["Status"] = "Slow", ["StatusDuration"] = 4}
            }
        },
        ["Stampede"] = {
            ["DisplayName"] = "Stampede",
            ["Cooldown"] = 16,
            ["UseLength"] = 3.4,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 5.5, ["Status"] = "Stun", ["StatusDuration"] = 3}
            }
        },
        ["ShatteringEarth"] = {
            ["DisplayName"] = "Shattering Earth",
            ["Cooldown"] = 20,
            ["UseLength"] = 2.35,
            ["CanMultiHit"] = false,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Stun", ["StatusDuration"] = 3},
                {["Type"] = "Normal", ["Damage"] = 6, ["Status"] = "Stun", ["StatusDuration"] = 3}
            }
        },
        ["DustDevil"] = {
            ["DisplayName"] = "Dust Devil",
            ["Cooldown"] = 16,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5},
                {["Type"] = "Normal", ["Damage"] = 0.5}
            }
        },
        ["DuneCaller"] = {
            ["DisplayName"] = "Dune Caller",
            ["Cooldown"] = 30,
            ["UseLength"] = 4.5,
            ["CanMultiHit"] = true,
            ["Hits"] = {
                {["Type"] = "Normal", ["Damage"] = 20}
            }
        },
        ["HardenedSkin"] = {
            ["DisplayName"] = "Hardened Skin",
            ["Cooldown"] = 30,
            ["UseLength"] = 1.8,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["ShroomFrenzy"] = {
            ["DisplayName"] = "Shroom Frenzy",
            ["Cooldown"] = 25,
            ["UseLength"] = 2.7,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["BarkskinRally"] = {
            ["DisplayName"] = "Barkskin Rally",
            ["Cooldown"] = 32,
            ["UseLength"] = 2.5,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["GuardiansPact"] = {
            ["DisplayName"] = "Guardian's Pact",
            ["Cooldown"] = 21,
            ["UseLength"] = 1.4,
            ["CanMultiHit"] = false,
            ["Hits"] = {}
        },
        ["Polymorph"] = {
            ["DisplayName"] = "Polymorph",
            ["Cooldown"] = 30,
            ["UseLength"] = 2.2,
            ["CanMultiHit"] = true,
            ["Hits"] = {}
        },
    }
    
    -- Initialize default selected skills
    RuntimeState.selectedSkills = {"Whirlwind", "FerociousRoar", "Rumble"}
end

-- Initialize skill data
initializeSkillData()

-- Function to update character references
local function updateCharacterReferences()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")
end

-- Listen for character changes
trackConnection(LocalPlayer.CharacterAdded:Connect(updateCharacterReferences), "CharacterAdded")

-- Initialize character references
if LocalPlayer.Character then
    updateCharacterReferences()
end

-- Debug function to check workspace structure
local function debugWorkspace()
end

-- Auto Skill Helper Functions
-- Get multiple enemies within range
local function getEnemiesInRange(range)
    local enemies = {}
    
    -- Check if we have valid character references
    if not LocalPlayer.Character then
        return enemies
    end
    
    local character = LocalPlayer.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return enemies
    end
    
    -- Check if mob folder exists
    if not mobFolder then
        return enemies
    end
    
    for _, mob in ipairs(mobFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobHrp = mob:FindFirstChild("HumanoidRootPart")
            
            if mobHrp then
                -- Check for different health systems used in Dungeon Heroes
                local isAlive = false
                local health = 0
                
                -- Try Humanoid first (standard Roblox)
                local mobHumanoid = mob:FindFirstChild("Humanoid")
                if mobHumanoid then
                    health = mobHumanoid.Health
                    isAlive = health > 0
                end
                
                -- If no Humanoid, try Healthbar system (Dungeon Heroes specific)
                if not isAlive then
                    local healthbar = mob:FindFirstChild("Healthbar")
                    if healthbar then
                        -- Look for health value in Healthbar
                        local healthValue = healthbar:FindFirstChild("Health") or healthbar:FindFirstChild("HP") or healthbar:FindFirstChild("CurrentHealth")
                        if healthValue and healthValue:IsA("NumberValue") then
                            health = healthValue.Value
                            isAlive = health > 0
                        end
                    end
                end
                
                -- Try direct health value on mob
                if not isAlive then
                    local healthValue = mob:FindFirstChild("Health") or mob:FindFirstChild("HP") or mob:FindFirstChild("CurrentHealth")
                    if healthValue and healthValue:IsA("NumberValue") then
                        health = healthValue.Value
                        isAlive = health > 0
                    end
                end
                
                -- Try MaxHealth value
                if not isAlive then
                    local maxHealthValue = mob:FindFirstChild("MaxHealth")
                    if maxHealthValue and maxHealthValue:IsA("NumberValue") then
                        health = maxHealthValue.Value
                        isAlive = health > 0
                    end
                end
                
                -- If still no health system found, assume it's alive (some games don't use standard health)
                if not isAlive then
                    isAlive = true
                    health = 100 -- Default assumption
                end
                
                if isAlive then
                    local distance = (mobHrp.Position - hrp.Position).Magnitude
                    if distance <= range then
                        table.insert(enemies, mob)
                    end
                end
            end
        end
    end
    
    -- Sort by distance (nearest first)
    table.sort(enemies, function(a, b)
        local distA = (a.HumanoidRootPart.Position - hrp.Position).Magnitude
        local distB = (b.HumanoidRootPart.Position - hrp.Position).Magnitude
        return distA < distB
    end)
    
    return enemies
end

-- Get nearest mob (for backward compatibility)
local function getNearestMob(maxDistance)
    local enemies = getEnemiesInRange(maxDistance or CONFIG.SKILL_RANGE)
    return enemies[1] -- Return the nearest enemy
end

local function faceTarget(target)
    if not Character or not HRP or not target then return end
    local dir = (target.Position - HRP.Position).Unit
    HRP.CFrame = CFrame.new(HRP.Position, HRP.Position + Vector3.new(dir.X, 0, dir.Z))
end

local function getSkillCooldown(skillName)
    local skillData = RuntimeState.skillData[skillName]
    if skillData then
        return skillData.Cooldown
    end
    return CONFIG.FALLBACK_COOLDOWN
end

local function getEquippedSkills()
    local equippedSkills = {}
    
    -- Try to get skills from the skill system if available
    if skillSystem and skillSystem.GetSkillInActiveSlot then
        for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
            local skill = skillSystem:GetSkillInActiveSlot(LocalPlayer, tostring(slot))
            if skill and skill ~= "" then
                table.insert(equippedSkills, skill)
            end
        end
    else
        -- Fallback to common skill names if skill system not available
        equippedSkills = {"Whirlwind", "FerociousRoar", "Rumble", "PiercingWave", "Fireball", "DrillStrike", "FireBreath", "FrenziedStrike", "Eruption", "SerpentStrike", "Cannonball", "Skybreaker", "Eviscerate", "Thunderclap", "HammerStorm"}
    end
    
    return equippedSkills
end

local function useSkill(skillName, target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local skillData = RuntimeState.skillData[skillName]
    if not skillData then
        return
    end
    
    -- Get multiple enemies in range for area-of-effect attacks
    local enemies = getEnemiesInRange(CONFIG.SKILL_RANGE)
    local maxEnemies = 10 -- Allow up to 10 enemies instead of skill hit count
    
    -- Limit enemies to max enemies
    local enemiesToHit = {}
    for i = 1, math.min(maxEnemies, #enemies) do
        table.insert(enemiesToHit, enemies[i])
    end
    
    -- Use the skill based on Dungeon Heroes format
    local skillArgs = {
        [1] = skillName,
        [2] = 1,
    }
    
    pcall(function()
        Skills:FireServer(unpack(skillArgs))
    end)
    
    -- Wait a bit before using skill attack
    task.wait(0.1)
    
    -- Handle all skills with multiple hits
    local numHits = #skillData.Hits
    if numHits > 1 then
        -- Use skill attack for each hit on multiple enemies
        for hitIndex = 1, numHits do
            local attackArgs = {
                [1] = enemiesToHit, -- Attack all enemies in range
                [2] = skillName,
                [3] = hitIndex,
            }
            
            pcall(function()
                SkillAttack:FireServer(unpack(attackArgs))
            end)
            
            -- Small delay between hits
            task.wait(0.05)
        end
    else
        -- Single hit skill on multiple enemies
        local attackArgs = {
            [1] = enemiesToHit, -- Attack all enemies in range
            [2] = skillName,
            [3] = 1,
        }
        
        pcall(function()
            SkillAttack:FireServer(unpack(attackArgs))
        end)
    end
    
    -- Wait a bit before creating effect
    task.wait(0.1)
    
    -- Create effect for each enemy hit
    for _, enemy in pairs(enemiesToHit) do
        local effectArgs = {
            [1] = "SlashHit",
            [2] = enemy.HumanoidRootPart.Position,
            [3] = {
                [1] = enemy.HumanoidRootPart.CFrame,
                [3] = Color3.new(0.866667, 0.603922, 0.364706),
                [4] = 30,
                [5] = 1.5,
            }
        }
        
        pcall(function()
            Effects:FireServer(unpack(effectArgs))
        end)
        
        -- Small delay between effects
        task.wait(0.02)
    end
end

-- Auto Skill loop
trackTask(task.spawn(function()
    while true do
        if RuntimeState.autoSkillEnabled and Character and HRP then
            -- Check each skill that is enabled via checkboxes
            for skillName, enabled in pairs(RuntimeState.skillToggles) do
                if enabled then
                    local cooldown = getSkillCooldown(skillName)
                    local last = RuntimeState.lastUsed[skillName] or 0
                    local timeSinceLastUse = tick() - last
                    
                    if timeSinceLastUse >= cooldown then
                        local target = getNearestMob()
                        if target then
                            faceTarget(target.HumanoidRootPart)
                            pcall(function()
                                useSkill(skillName, target)
                            end)
                            RuntimeState.lastUsed[skillName] = tick()
                        end
                    end
                end
            end
        end
        task.wait(CONFIG.SKILL_CHECK_INTERVAL)
    end
end), "AutoSkillLoop")

-- Create the main window
local Window = Library:CreateWindow({
    Title = "Seisen Hub",
    Footer = "Dungeon Heroes",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.LeftAlt,
    ShowCustomCursor = true -- Enable custom cursor
})

-- Add tabs
local MainTab = Window:AddTab("Main", "box")
local DungeonTab = Window:AddTab("Dungeon", "swords")
local SettingsTab = Window:AddTab("UI Settings", "settings")

-- Add groupboxes
local FeaturesBox = MainTab:AddLeftGroupbox("Features")
local AutoSkillBox = MainTab:AddRightGroupbox("Auto Skill")
-- local InfoBox = MainTab:AddRightGroupbox("Information") -- Removed as requested

--// Auto Farm Configuration
local autoFarmEnabled = false
local autoFarmHeight = 50 -- studs above mob
local autoFarmSpeed = 80 -- higher = faster
local autoFarmCheckInterval = 0.2

--// Auto Mini Boss Configuration
local autoMiniBossEnabled = false

-- Noclip state
local noclipConnection = nil

-- Add Auto Farm toggle
local AutoFarmToggle = FeaturesBox:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = config.autoFarmEnabled,
    Tooltip = "Automatically moves above mobs and attacks them",
    Callback = function(Value)
        autoFarmEnabled = Value
        config.autoFarmEnabled = Value
        saveConfig()
        Library:Notify({Title = "Auto Farm", Description = Value and "Enabled" or "Disabled", Time = 2})

        -- Noclip logic
        if Value then
            if not noclipConnection then
                noclipConnection = trackConnection(game:GetService("RunService").Stepped:Connect(function()
                    if Character then
                        for _, part in ipairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end), "AutoFarmNoclip")
            end
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            -- Restore CanCollide when disabling
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- Add Auto Mini Boss toggle
local AutoMiniBossToggle = FeaturesBox:AddToggle("AutoMiniBoss", {
    Text = "Auto Mini Boss",
    Default = config.autoMiniBossEnabled,
    Tooltip = "Automatically tweens to mini bosses in dungeon rooms (1-5) and replays when killed",
    Callback = function(Value)
        autoMiniBossEnabled = Value
        config.autoMiniBossEnabled = Value
        saveConfig()
        Library:Notify({Title = "Auto Mini Boss", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})

--// Auto Farm Loop
trackTask(task.spawn(function()
    local bodyVelocity = nil
    local currentMob = nil

    while true do
        if autoFarmEnabled and Character and HRP then
            -- Find the next valid mob
            local found = false
            for _, mob in ipairs(mobFolder:GetChildren()) do
                if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                    -- Skip mobs that have PetHealthbar or PetIItemRef
                    if mob:FindFirstChild("PetHealthbar") or mob:FindFirstChild("PetIItemRef") then
                        continue
                    end
                    -- Skip TargetDummy mobs
                    if mob.Name == "TargetDummy" then
                        continue
                    end
                    local mobHRP = mob.HumanoidRootPart
                    local healthbar = mob:FindFirstChild("Healthbar")
                    if healthbar and mobHRP then
                        -- Check if mob is alive (healthbar exists)
                        currentMob = mob
                        found = true
                        break
                    end
                end
            end
            if found and currentMob then
                local mobHRP = currentMob:FindFirstChild("HumanoidRootPart")
                local healthbar = currentMob:FindFirstChild("Healthbar")
                if mobHRP and healthbar then
                    -- Create BodyVelocity if not exists
                    if not bodyVelocity or bodyVelocity.Parent ~= HRP then
                        if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) end
                        bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                        bodyVelocity.P = 1e4
                        bodyVelocity.Parent = HRP
                    end

                    -- Calculate target position (above mob) using adjustable height
                    local targetPos = mobHRP.Position + Vector3.new(0, autoFarmHeight, 0)
                    local direction = (targetPos - HRP.Position)
                    local distance = direction.Magnitude

                    -- Smoothly move towards target
                    if distance > 1 then
                        bodyVelocity.Velocity = direction.Unit * math.min(distance * 4, autoFarmSpeed)
                    else
                        bodyVelocity.Velocity = Vector3.new(0,0,0)
                    end
                else
                    -- Mob died or healthbar gone, clear and move to next
                    if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
                    currentMob = nil
                end
            else
                -- No mobs found, clear velocity
                if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
                currentMob = nil
            end
        else
            -- Not enabled, cleanup
            if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end
            currentMob = nil
        end
        task.wait(autoFarmCheckInterval)
    end
end), "AutoFarmLoop")

--// Auto Mini Boss Loop
trackTask(task.spawn(function()
    local miniBossBodyVelocity = nil
    local currentMob = nil
    local isWaitingForMiniBoss = false
    local currentMiniBossName = nil
    local miniBossNoclipConnection = nil
    
    -- List of mini bosses to search for
    local miniBossList = {
        "Ursolare","Okurio", "Sea Serpent"
        -- Add more mini boss names here as needed
        -- "AnotherMiniBoss",
        -- "YetAnotherMiniBoss"
    }

    while true do
        if config.autoMiniBossEnabled and Character and HRP then
            -- Enable noclip for auto mini boss
            if not miniBossNoclipConnection then
                miniBossNoclipConnection = trackConnection(game:GetService("RunService").Stepped:Connect(function()
                    if Character then
                        for _, part in ipairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end), "AutoMiniBossNoclip")
            end

            -- First priority: Move to any mob in Workspace > Mobs
            if not currentMob then
                -- Find any mob to tween to
                for _, mob in ipairs(mobFolder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
                        -- Skip mobs that have PetHealthbar or PetIItemRef
                        if mob:FindFirstChild("PetHealthbar") or mob:FindFirstChild("PetIItemRef") then
                            continue
                        end
                        -- Skip TargetDummy mobs
                        if mob.Name == "TargetDummy" then
                            continue
                        end
                        local mobHRP = mob.HumanoidRootPart
                        local healthbar = mob:FindFirstChild("Healthbar")
                        if healthbar and mobHRP then
                            currentMob = mob
                            break
                        end
                    end
                end
            end

            -- Move to current mob using BodyVelocity
            if currentMob then
                local mobHRP = currentMob:FindFirstChild("HumanoidRootPart")
                local healthbar = currentMob:FindFirstChild("Healthbar")
                
                if mobHRP and healthbar then
                    -- Create BodyVelocity if not exists
                    if not miniBossBodyVelocity or miniBossBodyVelocity.Parent ~= HRP then
                        if miniBossBodyVelocity then pcall(function() miniBossBodyVelocity:Destroy() end) end
                        miniBossBodyVelocity = Instance.new("BodyVelocity")
                        miniBossBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                        miniBossBodyVelocity.P = 1e4
                        miniBossBodyVelocity.Parent = HRP
                    end

                    -- Calculate target position (above mob)
                    local targetPos = mobHRP.Position + Vector3.new(0, 50, 0)
                    local direction = (targetPos - HRP.Position)
                    local distance = direction.Magnitude

                    -- Smoothly move towards target
                    if distance > 1 then
                        miniBossBodyVelocity.Velocity = direction.Unit * math.min(distance * 4, 80)
                    else
                        miniBossBodyVelocity.Velocity = Vector3.new(0,0,0)
                    end
                else
                    -- Mob died or healthbar gone, find next mob
                    if miniBossBodyVelocity then pcall(function() miniBossBodyVelocity:Destroy() end) miniBossBodyVelocity = nil end
                    currentMob = nil
                end
            end

            -- Check for any mini boss in Mobs
            local foundMiniBoss = nil
            local foundMiniBossName = nil
            
            for _, miniBossName in ipairs(miniBossList) do
                local miniBossInMobs = mobFolder:FindFirstChild(miniBossName)
                if miniBossInMobs then
                    foundMiniBoss = miniBossInMobs
                    foundMiniBossName = miniBossName
                    break
                end
            end
            
            if foundMiniBoss then
                -- Mini boss is alive in mobs
                currentMob = foundMiniBoss
                isWaitingForMiniBoss = true
                currentMiniBossName = foundMiniBossName
            else
                -- No mini boss found in mobs
                if isWaitingForMiniBoss and currentMiniBossName then
                    -- We were waiting and now it's gone - it died!
                    
                    -- Clean up
                    if miniBossBodyVelocity then pcall(function() miniBossBodyVelocity:Destroy() end) miniBossBodyVelocity = nil end
                    currentMob = nil
                    isWaitingForMiniBoss = false
                    currentMiniBossName = nil
                    
                    task.wait(3)
                    
                    -- Bypass Method 1: Set the attribute directly (bypasses UI requirement)
                    local success1 = pcall(function()
                        game.Players.LocalPlayer:SetAttribute("ExitChoice", "GoAgain")
                    end)
                    
                    task.wait(0.1)
                    
                    -- Bypass Method 2: Use the SetExitChoice remote event
                    local success2 = pcall(function()
                        local args = { [1] = "GoAgain" }
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Systems", 9e9)
                            :WaitForChild("Dungeons", 9e9)
                            :WaitForChild("SetExitChoice", 9e9)
                            :FireServer(unpack(args))
                    end)
                    
                    task.wait(0.1)
                    
                    -- Bypass Method 3: Use InstantChoice as backup (true = GoAgain)
                    local success3 = pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Systems", 9e9)
                            :WaitForChild("Dungeons", 9e9)
                            :WaitForChild("InstantChoice", 9e9)
                            :FireServer(true)
                    end)
                else
                    -- No mini boss found
                end
            end

        else
            -- Not enabled, cleanup
            if miniBossBodyVelocity then pcall(function() miniBossBodyVelocity:Destroy() end) miniBossBodyVelocity = nil end
            currentMob = nil
            isWaitingForMiniBoss = false
            currentMiniBossName = nil
            
            -- Disable noclip and restore CanCollide
            if miniBossNoclipConnection then
                miniBossNoclipConnection:Disconnect()
                miniBossNoclipConnection = nil
                -- Restore CanCollide when disabling
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
        task.wait(0.2) -- Check frequently for smooth movement
    end
end), "AutoMiniBossLoop")

-- Add Kill Aura toggle
local KillAuraToggle = FeaturesBox:AddToggle("KillAura", {
    Text = "Kill Aura",
    Default = config.killAuraEnabled,
    Tooltip = "Automatically attacks nearby mobs",
    Callback = function(Value)
        _G.killAuraEnabled = Value
        config.killAuraEnabled = Value
        saveConfig()
        Library:Notify({Title = "Kill Aura", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})

-- Add Auto Skill toggle
local AutoSkillToggle = AutoSkillBox:AddToggle("AutoSkill", {
    Text = "Enable Auto Skill",
    Default = false,
    Tooltip = "Automatically uses selected skills on nearby mobs",
    Callback = function(Value)
        RuntimeState.autoSkillEnabled = Value
        config.autoSkillEnabled = Value
        saveConfig()
        Library:Notify({Title = "Auto Skill", Description = Value and "Enabled" or "Disabled", Time = 2})
        if Value then
            local selectedSkills = {}
            for skillName, enabled in pairs(RuntimeState.skillToggles) do
                if enabled then
                    table.insert(selectedSkills, skillName)
                end
            end
        end
    end
})

-- Add skill checkboxes
-- ...existing code...

-- Add skill checkboxes with alphabetical order and search
local skillToggles = {}
local skillNames = {}
for skillName in pairs(RuntimeState.skillData) do
    table.insert(skillNames, skillName)
end
table.sort(skillNames, function(a, b)
    return RuntimeState.skillData[a].DisplayName:lower() < RuntimeState.skillData[b].DisplayName:lower()
end)

local searchTerm = ""
local searchBox = AutoSkillBox:AddInput("SkillSearch", {
    Default = "",
    Placeholder = "Search skill...",
    Tooltip = "Type to filter skills",
    Callback = function(Value)
        searchTerm = Value:lower()
        for skillName, toggle in pairs(skillToggles) do
            local displayName = RuntimeState.skillData[skillName].DisplayName:lower()
            -- Use SetVisible if available, fallback to .Object.Visible
            if toggle.SetVisible then
                toggle:SetVisible(searchTerm == "" or displayName:find(searchTerm, 1, true))
            elseif toggle.Object and toggle.Object.Visible ~= nil then
                toggle.Object.Visible = (searchTerm == "" or displayName:find(searchTerm, 1, true))
            end
        end
    end
})

for _, skillName in ipairs(skillNames) do
    local skillData = RuntimeState.skillData[skillName]
    skillToggles[skillName] = AutoSkillBox:AddToggle(skillName, {
        Text = skillData.DisplayName,
        Default = false,
        Tooltip = "Use " .. skillData.DisplayName .. " (Cooldown: " .. (skillData.Cooldown or "?") .. "s)",
        Callback = function(Value)
            RuntimeState.skillToggles[skillName] = Value
            config.skillToggles[skillName] = Value
            saveConfig()
        end
    })
end

-- Restore skill toggles state from config
for skillName, toggle in pairs(skillToggles) do
    if config.skillToggles and config.skillToggles[skillName] ~= nil then
        toggle:SetValue(config.skillToggles[skillName])
    end
end

-- Add Auto Start/Reply Dungeon toggles
local autoStartDungeon = false
local autoReplyDungeon = false

local AutoStartDungeonToggle = FeaturesBox:AddToggle("AutoStartDungeon", {
    Text = "Auto Start Dungeon",
    Default = config.autoStartDungeon,
    Tooltip = "Automatically starts the dungeon when possible",
    Callback = function(Value)
        autoStartDungeon = Value
        config.autoStartDungeon = Value
        saveConfig()
        Library:Notify({Title = "Auto Start Dungeon", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})

local AutoReplyDungeonToggle = FeaturesBox:AddToggle("AutoReplyDungeon", {
    Text = "Auto Replay Dungeon",
    Default = config.autoReplyDungeon,
    Tooltip = "Automatically replies 'GoAgain' to dungeon exit prompt",
    Callback = function(Value)
        autoReplyDungeon = Value
        config.autoReplyDungeon = Value
        saveConfig()
        Library:Notify({Title = "Auto Reply Dungeon", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})

trackTask(task.spawn(function()
    while true do
        if autoReplyDungeon then
            local args = {
                [1] = "GoAgain";
            }
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Systems", 9e9)
                    :WaitForChild("Dungeons", 9e9)
                    :WaitForChild("SetExitChoice", 9e9)
                    :FireServer(unpack(args))
            end)
        end
        task.wait(1.5) -- Check every 1.5 seconds
    end
end), "AutoReplyDungeonLoop")

-- Add Auto Next Dungeon toggle and settings
local autoNextDungeon = false
-- Replace your current dungeonSequence with this:
local dungeonSequence = {
    {name = "ForestDungeon", difficulty = 1}, -- Normal
    {name = "ForestDungeon", difficulty = 2}, -- Medium
    {name = "ForestDungeon", difficulty = 3}, -- Hard
    {name = "ForestDungeon", difficulty = 4}, -- Insane
    {name = "MountainDungeon", difficulty = 1}, -- Normal
    {name = "MountainDungeon", difficulty = 2}, -- Medium
    {name = "MountainDungeon", difficulty = 3}, -- Hard
    {name = "MountainDungeon", difficulty = 4}, -- Insane
    {name = "CoveDungeon", difficulty = 1}, -- Normal
    {name = "CoveDungeon", difficulty = 2}, -- Medium
    {name = "CoveDungeon", difficulty = 3}, -- Hard
    {name = "CoveDungeon", difficulty = 4}, -- Insane
    {name = "CastleDungeon", difficulty = 1}, -- Normal
    {name = "CastleDungeon", difficulty = 2}, -- Medium
    {name = "CastleDungeon", difficulty = 3}, -- Hard
    {name = "CastleDungeon", difficulty = 4}, -- Insane
    {name = "JungleDungeon", difficulty = 1}, -- Normal
    {name = "JungleDungeon", difficulty = 2}, -- Medium
    {name = "JungleDungeon", difficulty = 3}, -- Hard
    {name = "JungleDungeon", difficulty = 4}, -- Insane
    {name = "AstralDungeon", difficulty = 1}, -- Normal
    {name = "AstralDungeon", difficulty = 2}, -- Medium
    {name = "AstralDungeon", difficulty = 3}, -- Hard
    {name = "AstralDungeon", difficulty = 4}, -- Insane
    {name = "DesertDungeon", difficulty = 1}, -- Normal
    {name = "DesertDungeon", difficulty = 2}, -- Medium
    {name = "DesertDungeon", difficulty = 3}, -- Hard
    {name = "DesertDungeon", difficulty = 4}, -- Insane
    {name = "CaveDungeon", difficulty = 1}, -- Normal
    {name = "CaveDungeon", difficulty = 2}, -- Medium
    {name = "CaveDungeon", difficulty = 3}, -- Hard
    {name = "CaveDungeon", difficulty = 4}, -- Insane
    {name = "MushroomDungeon", difficulty = 1}, -- Normal
    {name = "MushroomDungeon", difficulty = 2}, -- Medium
    {name = "MushroomDungeon", difficulty = 3}, -- Hard
    {name = "MushroomDungeon", difficulty = 4}, -- Insane
    {name = "GoldDungeon", difficulty = 1}, -- Normal
    {name = "GoldDungeon", difficulty = 2}, -- Medium
    {name = "GoldDungeon", difficulty = 3}, -- Hard
    {name = "GoldDungeon", difficulty = 4}, -- Insane
}
local dungeonSequenceIndex = 1
local autoClaimDailyQuest = false

local AutoClaimDailyQuestToggle = FeaturesBox:AddToggle("AutoClaimDailyQuest", {
    Text = "Auto Claim Daily Quest",
    Default = config.autoClaimDailyQuest,
    Tooltip = "Automatically claims all available daily quest rewards",
    Callback = function(Value)
        autoClaimDailyQuest = Value
        config.autoClaimDailyQuest = Value
        saveConfig()
        Library:Notify({Title = "Auto Claim Daily Quest", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})


trackTask(task.spawn(function()
    while true do
        if autoClaimDailyQuest then
            local profile = nil
            pcall(function()
                local profileSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Profile", 9e9))
                profile = profileSystem:GetProfile(game.Players.LocalPlayer)
            end)
            if profile and profile.DailyQuests and profile.DailyQuests.QuestProgress then
                for _, quest in ipairs(profile.DailyQuests.QuestProgress:GetChildren()) do
                    local questId = tonumber(quest.Name)
                    if questId and not profile.DailyQuests.ClaimedRewards:FindFirstChild(quest.Name) then
                        -- Check if quest is complete
                        local goal = quest:GetAttribute("Goal") or 1
                        if quest.Value >= goal then
                            -- Try to claim
                            pcall(function()
                                game:GetService("ReplicatedStorage")
                                    :WaitForChild("Systems", 9e9)
                                    :WaitForChild("Quests", 9e9)
                                    :WaitForChild("ClaimDailyQuestReward", 9e9)
                                    :FireServer(questId)
                            end)
                            task.wait(0.5) -- Small delay between claims
                        end
                    end
                end
            end
        end
        task.wait(3)
    end
end), "AutoClaimDailyQuestLoop")


local autoEquipHighestWeapon = false

local AutoEquipHighestWeaponToggle = FeaturesBox:AddToggle("AutoEquipHighestWeapon", {
    Text = "Auto Equip Highest Equipment",
    Default = config.autoEquipHighestWeapon,
    Tooltip = "Automatically equips your highest attack weapon",
    Callback = function(Value)
        autoEquipHighestWeapon = Value
        config.autoEquipHighestWeapon = Value
        saveConfig()
        Library:Notify({Title = "Auto Equip Highest Weapon", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})


-- Add slider for Auto Farm Height
local AutoFarmHeightSlider = FeaturesBox:AddSlider("AutoFarmHeight", {
    Text = "Auto Farm Height",
    Min = 10,
    Max = 80,
    Default = autoFarmHeight,
    Suffix = " studs",
    Tooltip = "How high above the mob to farm",
    Rounding = 0,
    Callback = function(Value)
        autoFarmHeight = Value
        config.autoFarmHeight = Value
        saveConfig()
    end
})


-- Auto Equip Highest Equipment Logic (Improved)
trackTask(task.spawn(function()
    while true do
        if autoEquipHighestWeapon then
            local profile = nil
            pcall(function()
                local profileSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Profile", 9e9))
                profile = profileSystem:GetProfile(game.Players.LocalPlayer)
            end)
            if profile and profile.Inventory and profile.Equipped then
                local itemsModule = nil
                pcall(function()
                    itemsModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Items", 9e9))
                end)

                -- Helper to calculate item power with level priority
                local function getItemPower(item, showDebug)
                    if not item or not itemsModule then return -math.huge, "No item or module" end
                    local itemData = nil
                    local rarity = 0
                    local level = 1
                    
                    pcall(function()
                        itemData = itemsModule:GetItemData(item.Name)
                        rarity = itemsModule:GetRarity(item) or 0
                        level = itemData and itemData.Level or 1
                    end)
                    
                    local power = (level * 1000) + rarity
                    
                    return power, string.format("L%d R%d", level, rarity)
                end

                local function getEquippedItemAndPower(slot, typeName)
                    local equippedFolder = profile.Equipped:FindFirstChild(slot)
                    if equippedFolder then
                        for _, equippedItem in ipairs(equippedFolder:GetChildren()) do
                            local itemData = nil
                            pcall(function()
                                itemData = itemsModule:GetItemData(equippedItem.Name)
                            end)
                            if itemData and (not typeName or itemData.Type == typeName) then
                                local power, info = getItemPower(equippedItem, false)
                                return equippedItem, power, info
                            end
                        end
                    end
                    return nil, -math.huge, "None"
                end

                local function findBestInInventory(category, typeName, equippedItem)
                    local bestItem = nil
                    local bestPower = -math.huge
                    local bestInfo = "None"
                    
                    for _, item in ipairs(profile.Inventory:GetChildren()) do
                        if not equippedItem or item ~= equippedItem then
                            local itemData = nil
                            pcall(function()
                                itemData = itemsModule:GetItemData(item.Name)
                            end)
                            if itemData and itemData.Category == category and (not typeName or itemData.Type == typeName) then
                                local power, info = getItemPower(item, false)
                                if power > bestPower then
                                    bestPower = power
                                    bestItem = item
                                    bestInfo = info
                                end
                            end
                        end
                    end
                    return bestItem, bestPower, bestInfo
                end

                local function equipWeapon(item, equippedInfo, newInfo)
                    if not item then return end
                    task.wait(0.2)
                    pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Systems", 9e9)
                            :WaitForChild("Equipment", 9e9)
                            :WaitForChild("Equip", 9e9)
                            :FireServer("Right", item)
                    end)
                    Library:Notify({
                        Title = "Auto Equip Weapon", 
                        Description = string.format("Upgraded: %s → %s (%s)", 
                            equippedInfo, item.Name or "Unknown", newInfo),
                        Time = 4
                    })
                end

                local function equipArmor(item, equippedInfo, newInfo)
                    if not item then return end
                    task.wait(0.2)
                    pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Systems", 9e9)
                            :WaitForChild("Equipment", 9e9)
                            :WaitForChild("EquipArmor", 9e9)
                            :FireServer(item)
                    end)
                    Library:Notify({
                        Title = "Auto Equip Armor", 
                        Description = string.format("Upgraded: %s → %s (%s)", 
                            equippedInfo, item.Name or "Unknown", newInfo),
                        Time = 4
                    })
                end

                local equippedWeapon, equippedWeaponPower, equippedWeaponInfo = getEquippedItemAndPower("Right")
                local bestWeaponItem, bestWeaponPower, bestWeaponInfo = findBestInInventory("Weapon", nil, equippedWeapon)
                
                if bestWeaponItem and bestWeaponPower > equippedWeaponPower then
                    equipWeapon(bestWeaponItem, equippedWeaponInfo, bestWeaponInfo)
                end

                local equippedShirt, equippedShirtPower, equippedShirtInfo = getEquippedItemAndPower("Shirt", "Shirt")
                local bestShirtItem, bestShirtPower, bestShirtInfo = findBestInInventory("Armor", "Shirt", equippedShirt)
                
                if bestShirtItem and bestShirtPower > equippedShirtPower then
                    equipArmor(bestShirtItem, equippedShirtInfo, bestShirtInfo)
                end

                local equippedPants, equippedPantsPower, equippedPantsInfo = getEquippedItemAndPower("Pants", "Pants")
                local bestPantsItem, bestPantsPower, bestPantsInfo = findBestInInventory("Armor", "Pants", equippedPants)
                
                if bestPantsItem and bestPantsPower > equippedPantsPower then
                    equipArmor(bestPantsItem, equippedPantsInfo, bestPantsInfo)
                end

                --[[
                local equippedHelmet, equippedHelmetPower = getEquippedItemAndPower("Helmet", "Helmet")
                local bestHelmetItem, bestHelmetPower = findBestInInventory("Armor", "Helmet", equippedHelmet)
                
                if bestHelmetItem and bestHelmetPower > equippedHelmetPower then
                    equipArmor(bestHelmetItem)
                end
                
                local equippedGloves, equippedGlovesPower = getEquippedItemAndPower("Gloves", "Gloves")
                local bestGlovesItem, bestGlovesPower = findBestInInventory("Armor", "Gloves", equippedGloves)
                
                if bestGlovesItem and bestGlovesPower > equippedGlovesPower then
                    equipArmor(bestGlovesItem)
                end
                
                local equippedBoots, equippedBootsPower = getEquippedItemAndPower("Boots", "Boots")
                local bestBootsItem, bestBootsPower = findBestInInventory("Armor", "Boots", equippedBoots)
                
                if bestBootsItem and bestBootsPower > equippedBootsPower then
                    equipArmor(bestBootsItem)
                end
                ]]
            end
        end
        task.wait(1)
    end
end), "AutoEquipLoop")


local rarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
local rarityIndexMap = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5}

local autoSellEnabled = false
local selectedRarity = "Common"



local AutoSellToggle = FeaturesBox:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = config.autoSellEnabled,
    Tooltip = "Automatically sells items of selected rarity and below (except skills)",
    Callback = function(Value)
        autoSellEnabled = Value
        config.autoSellEnabled = Value
        saveConfig()
        Library:Notify({Title = "Auto Sell", Description = Value and "Enabled" or "Disabled", Time = 2})
    end
})

local AutoSellRarityDropdown = FeaturesBox:AddDropdown("AutoSellRarity", {
    Text = "Auto Sell Rarity",
    Values = rarityList,
    Default = config.autoSellRarity or selectedRarity,
    Tooltip = "Sell items of this rarity and below",
    Callback = function(Value)
        selectedRarity = Value
        config.autoSellRarity = Value
        saveConfig()
    end
})


-- Restore state from config
if config.autoSellRarity then
    AutoSellRarityDropdown:SetValue(config.autoSellRarity)
    selectedRarity = config.autoSellRarity
end
if config.autoSellEnabled ~= nil then
    AutoSellToggle:SetValue(config.autoSellEnabled)
    autoSellEnabled = config.autoSellEnabled
end

-- Auto Sell logic
trackTask(task.spawn(function()
    while true do
        if autoSellEnabled then
            local profile = nil
            local itemsModule = nil
            pcall(function()
                itemsModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Items", 9e9))
                local profileSystem = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Profile", 9e9))
                profile = profileSystem:GetProfile(game.Players.LocalPlayer)
            end)
            if profile and profile.Inventory then
                local toSell = {}
                -- Always use the latest selectedRarity value
                local rarityLimit = rarityIndexMap[selectedRarity]
                for _, item in ipairs(profile.Inventory:GetChildren()) do
                    local itemData = nil
                    pcall(function()
                        itemData = itemsModule:GetItemData(item.Name)
                    end)
                    local rarity = itemsModule:GetRarity(item)
                    -- Only sell equipment (Weapon or Armor), not Skill, Chest, Animal, Monster, etc.
                    if itemData and (itemData.Category == "Weapon" or itemData.Category == "Armor") and rarity <= rarityLimit then
                        table.insert(toSell, item)
                    end
                end
                if #toSell > 0 then
                    local args = {
                        [1] = toSell,
                        [2] = {}
                    }
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("ItemSelling", 9e9):WaitForChild("SellItem", 9e9):FireServer(unpack(args))
                    end)
                end
            end
        end
        task.wait(1)
    end
end), "AutoSellLoop")

-- Add Dungeon tab and groupboxes

local NormalDungeonBox = DungeonTab:AddLeftGroupbox("Normal Dungeon")
local RaidDungeonBox = DungeonTab:AddRightGroupbox("Raid Dungeon")
local EventDungeonBox = DungeonTab:AddLeftGroupbox("Event Dungeon")

-- Dungeon name display-to-code mapping
local normalDungeonNameMap = {
    ["Shattered Forest lvl 1+"] = "ForestDungeon",
    ["Orion's Peak lvl 15+"] = "MountainDungeon",
    ["Deadman's Cove lvl 30+"] = "CoveDungeon",
    ["Flaming Depths lvl 45+"] = "CastleDungeon",
    ["Mosscrown Jungle lvl 60+"] = "JungleDungeon",
    ["Astral Abyss lvl 75+"] = "AstralDungeon",
    ["Shifting Sands lvl 90+"] = "VolcanoDungeon",
    ["Shimmering Caves lvl 105+"] = "CaveDungeon",
    ["Mushroom Forest lvl 120+"] = "MushroomDungeon",
    ["Golden ream lvl 135+"] = "GoldDungeon"
}
local raidDungeonNameMap = {
    ["Abyssal Depths"] = "AbyssDungeon",
    ["Sky Citadel"] = "SkyDungeon",
    ["Molten Volcano"] = "VolcanoDungeon"
}
local eventDungeonNameMap = {
    ["The Gauntlet"] = "Gauntlet",
    ["Halloween Dungeon"] = "HalloweenDungeon",
    ["Christmas Dungeon"] = "ChristmasDungeon"
}

-- Normal Dungeon variables and UI
local normalDungeonName = "Shattered Forest lvl 1+"
local normalDungeonPlayerLimit = 1
local normalDungeonDifficulty = "Normal"

local AutoNextDungeonToggle = NormalDungeonBox:AddToggle("AutoNextDungeon", {
    Text = "Auto Next Dungeon Sequence",
    Default = config.autoNextDungeon or false,
    Tooltip = "Automatically cycles through a dungeon/difficulty list",
    Callback = function(Value)
        config.autoNextDungeon = Value
        saveConfig()
        Library:Notify({Title = "Auto Next Dungeon", Description = Value and "Enabled" or "Disabled", Time = 2})
        autoNextDungeon = config.autoNextDungeon
    end
})


-- Auto Next Dungeon queue logic
trackTask(task.spawn(function()
    while true do
        if autoNextDungeon then
            -- Your queue logic for next dungeon goes here
            print("[SeisenHub] Queuing for next dungeon...")
            -- ...existing queue logic...
        end
        task.wait(1.5) -- Adjust interval as needed
    end
end), "AutoNextDungeonQueue")


NormalDungeonBox:AddDropdown("NormalDungeonName", {
    Text = "Dungeon Name",
    Values = {
        "Shattered Forest lvl 1+",
        "Orion's Peak lvl 15+",
        "Deadman's Cove lvl 30+",
        "Flaming Depths lvl 45+",
        "Mosscrown Jungle lvl 60+",
        "Astral Abyss lvl 75+",
        "Shifting Sands lvl 90+",
        "Shimmering Caves lvl 105+",
        "Mushroom Forest lvl 120+",
        "Golden ream lvl 135+"
    },
    Default = config.normalDungeonName,
    Callback = function(Value)
        normalDungeonName = Value
        config.normalDungeonName = Value
        saveConfig()
    end
})

NormalDungeonBox:AddDropdown("NormalDungeonDifficulty", {
    Text = "Difficulty",
    Values = {"Normal", "Medium", "Hard", "Insane", "Extreme"},
    Default = config.normalDungeonDifficulty,
    Callback = function(Value)
        normalDungeonDifficulty = Value
        config.normalDungeonDifficulty = Value
        saveConfig()
    end
})
NormalDungeonBox:AddDropdown("NormalDungeonPlayerLimit", {
    Text = "Player Limit",
    Values = {"1","2","3","4","5","6","7"},
    Default = tostring(config.normalDungeonPlayerLimit),
    Callback = function(Value)
        normalDungeonPlayerLimit = tonumber(Value)
        config.normalDungeonPlayerLimit = normalDungeonPlayerLimit
        saveConfig()
    end
})
NormalDungeonBox:AddButton({
    Text = "Start Dungeon",
    Func = function()
        local difficultyIndexMap = {Normal=1, Medium=2, Hard=3, Insane=4, Extreme=5}
        local args = {
            [1] = normalDungeonNameMap[normalDungeonName] or "ForestDungeon",
            [2] = difficultyIndexMap[normalDungeonDifficulty] or 1,
            [3] = normalDungeonPlayerLimit,
            [4] = false,
            [5] = true
        }
        lastDungeonArgs = args
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Parties", 9e9):WaitForChild("SetSettings", 9e9):FireServer(unpack(args))
        end)
    end
})

-- Raid Dungeon variables and UI
local raidDungeonName = "Abyssal Depths"
local raidDungeonPlayerLimit = 7
local raidDungeonDifficulty = "RAID"

RaidDungeonBox:AddDropdown("RaidDungeonName", {
    Text = "Dungeon Name",
    Values = {"Abyssal Depths", "Sky Citadel", "Molten Volcano"},
    Default = config.raidDungeonName,
    Callback = function(Value)
        raidDungeonName = Value
        config.raidDungeonName = Value
        saveConfig()
    end
})
RaidDungeonBox:AddDropdown("RaidDungeonDifficulty", {
    Text = "Difficulty",
    Values = {"RAID"},
    Default = config.raidDungeonDifficulty,
    Callback = function(Value)
        raidDungeonDifficulty = Value
        config.raidDungeonDifficulty = Value
        saveConfig()
    end
})
RaidDungeonBox:AddDropdown("RaidDungeonPlayerLimit", {
    Text = "Player Limit",
    Values = {"5","6","7"},
    Default = tostring(config.raidDungeonPlayerLimit),
    Callback = function(Value)
        raidDungeonPlayerLimit = tonumber(Value)
        config.raidDungeonPlayerLimit = raidDungeonPlayerLimit
        saveConfig()
    end
})

RaidDungeonBox:AddButton({
    Text = "Start Raid Dungeon",
    Func = function()
        local difficultyIndex = {RAID=7}
        local args = {
            [1] = raidDungeonNameMap[raidDungeonName] or "AbyssDungeon",
            [2] = raidDungeonPlayerLimit,
            [3] = difficultyIndex[raidDungeonDifficulty] or 7,
            [4] = false,
            [5] = false
        }
        lastDungeonArgs = args
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Parties", 9e9):WaitForChild("SetSettings", 9e9):FireServer(unpack(args))
        end)
    end
})

-- Event Dungeon variables and UI
local eventDungeonName = "Event Dungeon"
local eventDungeonPlayerLimit = 4
local eventDungeonDifficulty = "Normal"

EventDungeonBox:AddDropdown("EventDungeonName", {
    Text = "Dungeon Name",
    Values = {"Gauntlet", "Halloween Dungeon", "Christmas Dungeon"},
    Default = config.eventDungeonName,
    Callback = function(Value)
        eventDungeonName = Value
        config.eventDungeonName = Value
        saveConfig()
    end
})
EventDungeonBox:AddDropdown("EventDungeonDifficulty", {
    Text = "Difficulty",
    Values = {"Normal", "Hard", "Insane"},
    Default = config.eventDungeonDifficulty,
    Callback = function(Value)
        eventDungeonDifficulty = Value
        config.eventDungeonDifficulty = Value
        saveConfig()
    end
})
EventDungeonBox:AddDropdown("EventDungeonPlayerLimit", {
    Text = "Player Limit",
    Values = {"1","2","3","4","5"},
    Default = tostring(config.eventDungeonPlayerLimit),
    Callback = function(Value)
        eventDungeonPlayerLimit = tonumber(Value)
        config.eventDungeonPlayerLimit = eventDungeonPlayerLimit
        saveConfig()
    end
})
EventDungeonBox:AddButton({
    Text = "Start Event Dungeon",
    Func = function()
        local difficultyIndexMap = {Normal=1, Hard=3, Insane=4}
        local args = {
            [1] = eventDungeonNameMap[eventDungeonName] or "Gauntlet",
            [2] = eventDungeonPlayerLimit,
            [3] = difficultyIndexMap[eventDungeonDifficulty] or 1,
            [4] = True
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Parties", 9e9):WaitForChild("SetSettings", 9e9):FireServer(unpack(args))
    end
})

local SettingsTabbox = SettingsTab:AddLeftTabbox("Settings")
local ThemeTab = SettingsTabbox:AddTab("Theme")
local UICustomGroup = SettingsTab:AddRightGroupbox("UI Customization", "paintbrush")
local InfoGroup = SettingsTab:AddRightGroupbox("Script Information", "info")

-- Mobile detection and UI adjustments
if Library.IsMobile then
    UICustomGroup:AddLabel("📱 Mobile Device Detected")
    UICustomGroup:AddLabel("UI optimized for mobile")
else
    UICustomGroup:AddLabel("🖥️ Desktop Device Detected")
end

-- Custom Cursor Toggle
UICustomGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Tooltip = "Enable/disable the custom cursor design",
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

-- UI Scale dropdown for mobile compatibility
UICustomGroup:AddDropdown("UIScale", {
    Text = "UI Scale",
    Values = {"75%", "100%", "125%", "150%"},
    Default = 2, -- 100%
    Tooltip = "Adjust UI size for better mobile experience",
    Callback = function(value)
        local scaleMap = {
            ["75%"] = 75,
            ["100%"] = 100,
            ["125%"] = 125,
            ["150%"] = 150
        }
        
        -- Disable the library's watermark before scaling
        Library:SetWatermarkVisibility(false)
        
        -- Apply DPI scale to UI only
        Library:SetDPIScale(scaleMap[value])
        
        -- Don't re-enable the library watermark - we'll use our custom one
    end
})

-- Custom Watermark setup (independent of UI scaling)
local CoreGui = game:GetService("CoreGui")

-- Create independent watermark ScreenGui
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "SeisenWatermark"
WatermarkGui.DisplayOrder = 999999
WatermarkGui.IgnoreGuiInset = true
WatermarkGui.ResetOnSpawn = false
WatermarkGui.Parent = CoreGui

-- Create watermark frame (main container)
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "WatermarkFrame"
WatermarkFrame.Size = UDim2.new(0, 100, 0, 120) -- Taller container for vertical layout
WatermarkFrame.Position = UDim2.new(0, 10, 0, 100) -- Top-left position
WatermarkFrame.BackgroundTransparency = 1 -- Transparent container
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Parent = WatermarkGui

-- Create perfect circular logo frame
local CircleFrame = Instance.new("Frame")
CircleFrame.Name = "CircleFrame"
CircleFrame.Size = UDim2.new(0, 60, 0, 60) -- Perfect square = perfect circle
CircleFrame.Position = UDim2.new(0.5, -30, 0, 0) -- Centered horizontally at top
CircleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CircleFrame.BorderSizePixel = 0
CircleFrame.Parent = WatermarkFrame

-- Create circular corner (makes it a perfect circle)
local WatermarkCorner = Instance.new("UICorner")
WatermarkCorner.CornerRadius = UDim.new(0.5, 0) -- 50% radius = perfect circle
WatermarkCorner.Parent = CircleFrame

-- Create custom logo/image
local WatermarkImage = Instance.new("ImageLabel")
WatermarkImage.Name = "WatermarkImage"
WatermarkImage.Size = UDim2.new(1, 0, 1, 0) -- Fill the entire circle frame
WatermarkImage.Position = UDim2.new(0, 0, 0, 0) -- Cover the entire circle
WatermarkImage.BackgroundTransparency = 1
WatermarkImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- White tint
WatermarkImage.ScaleType = Enum.ScaleType.Crop -- Crop to fill the circle
WatermarkImage.Parent = CircleFrame

-- Make the image circular to match the frame
local ImageCorner = Instance.new("UICorner")
ImageCorner.CornerRadius = UDim.new(0.5, 0) -- Same circular radius as the frame
ImageCorner.Parent = WatermarkImage

-- Try multiple image formats for better compatibility
local imageFormats = {
    "rbxassetid://121631680891470",
    "http://www.roblox.com/asset/?id=121631680891470",
    "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Fallback image
}

-- Function to try loading the image
local function tryLoadImage()
    for i, imageId in ipairs(imageFormats) do
        WatermarkImage.Image = imageId
        
        -- Wait a bit to see if image loads
        task.wait(0.5)
        
        -- Check if image loaded (non-zero size means it loaded)
        if WatermarkImage.AbsoluteSize.X > 0 and WatermarkImage.AbsoluteSize.Y > 0 then
            break
        elseif i == #imageFormats then
            -- If all formats fail, use a text fallback
            WatermarkImage.Image = ""
            
            -- Create text fallback
            local FallbackText = Instance.new("TextLabel")
            FallbackText.Size = UDim2.new(1, 0, 1, 0)
            FallbackText.Position = UDim2.new(0, 0, 0, 0)
            FallbackText.BackgroundTransparency = 1
            FallbackText.Text = "S"
            FallbackText.TextColor3 = Color3.fromRGB(125, 85, 255) -- Accent color
            FallbackText.TextSize = 24
            FallbackText.Font = Enum.Font.GothamBold
            FallbackText.TextXAlignment = Enum.TextXAlignment.Center
            FallbackText.TextYAlignment = Enum.TextYAlignment.Center
            FallbackText.Parent = CircleFrame
        end
    end
end

-- Try loading the image
task.spawn(tryLoadImage)

-- Create Hub Name text
local HubNameText = Instance.new("TextLabel")
HubNameText.Name = "HubNameText"
HubNameText.Size = UDim2.new(1, 0, 0, 20)
HubNameText.Position = UDim2.new(0, 0, 0, 65) -- Below the circle
HubNameText.BackgroundTransparency = 1
HubNameText.Text = "Seisenhub"
HubNameText.TextColor3 = Color3.fromRGB(255, 255, 255)
HubNameText.TextSize = 14
HubNameText.Font = Enum.Font.GothamBold
HubNameText.TextXAlignment = Enum.TextXAlignment.Center
HubNameText.TextYAlignment = Enum.TextYAlignment.Center
HubNameText.TextStrokeTransparency = 0.5
HubNameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
HubNameText.Parent = WatermarkFrame

-- Create FPS text
local FPSText = Instance.new("TextLabel")
FPSText.Name = "FPSText"
FPSText.Size = UDim2.new(1, 0, 0, 16)
FPSText.Position = UDim2.new(0, 0, 0, 85) -- Below hub name
FPSText.BackgroundTransparency = 1
FPSText.Text = "60 fps"
FPSText.TextColor3 = Color3.fromRGB(200, 200, 200)
FPSText.TextSize = 12
FPSText.Font = Enum.Font.Code
FPSText.TextXAlignment = Enum.TextXAlignment.Center
FPSText.TextYAlignment = Enum.TextYAlignment.Center
FPSText.TextStrokeTransparency = 0.5
FPSText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
FPSText.Parent = WatermarkFrame

-- Create Ping text
local PingText = Instance.new("TextLabel")
PingText.Name = "PingText"
PingText.Size = UDim2.new(1, 0, 0, 16)
PingText.Position = UDim2.new(0, 0, 0, 101) -- Below FPS
PingText.BackgroundTransparency = 1
PingText.Text = "60 ms"
PingText.TextColor3 = Color3.fromRGB(200, 200, 200)
PingText.TextSize = 12
PingText.Font = Enum.Font.Code
PingText.TextXAlignment = Enum.TextXAlignment.Center
PingText.TextYAlignment = Enum.TextYAlignment.Center
PingText.TextStrokeTransparency = 0.5
PingText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
PingText.Parent = WatermarkFrame

-- Make watermark draggable
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local dragging = false
local dragStart = nil
local startPos = nil

-- Mouse/touch input for dragging and UI toggle
local dragThreshold = 5 -- Pixels moved before considering it a drag
local clickStartPos = nil

-- Global input connections for better drag handling
local inputBeganConnection = nil
local inputChangedConnection = nil
local inputEndedConnection = nil

local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false -- Reset dragging state
        dragStart = input.Position
        clickStartPos = input.Position
        startPos = WatermarkFrame.Position
        
        -- Visual feedback - slightly fade the circle frame
        local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(CircleFrame, fadeInfo, {BackgroundTransparency = 0.3})
        fadeTween:Play()
        
        -- Connect global input events for smooth dragging
        if inputChangedConnection then inputChangedConnection:Disconnect() end
        if inputEndedConnection then inputEndedConnection:Disconnect() end
        
        inputChangedConnection = UserInputService.InputChanged:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseMovement or globalInput.UserInputType == Enum.UserInputType.Touch then
                if dragStart then
                    local delta = globalInput.Position - dragStart
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    
                    -- Only start dragging if moved beyond threshold
                    if distance > dragThreshold then
                        dragging = true
                        WatermarkFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end
            end
        end)
        
        inputEndedConnection = UserInputService.InputEnded:Connect(function(globalInput)
            if globalInput.UserInputType == Enum.UserInputType.MouseButton1 or globalInput.UserInputType == Enum.UserInputType.Touch then
                -- Restore original transparency
                local restoreInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local restoreTween = TweenService:Create(CircleFrame, restoreInfo, {BackgroundTransparency = 0})
                restoreTween:Play()
                
                -- If it wasn't a drag, treat it as a click to toggle UI
                if not dragging and clickStartPos then
                    local delta = globalInput.Position - clickStartPos
                    local distance = math.sqrt(delta.X^2 + delta.Y^2)
                    
                    if distance <= dragThreshold then
                        -- Toggle UI visibility
                        Library:Toggle()
                    end
                end
                
                -- Reset states and disconnect global events
                dragging = false
                dragStart = nil
                clickStartPos = nil
                
                if inputChangedConnection then inputChangedConnection:Disconnect() end
                if inputEndedConnection then inputEndedConnection:Disconnect() end
            end
        end)
    end
end

-- Connect only the initial input event to the watermark frame
WatermarkFrame.InputBegan:Connect(onInputBegan)

-- Dynamic watermark with FPS and Ping (completely independent)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    -- Update custom watermark text
    pcall(function()
        local pingValue = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
        
        -- Update individual text elements
        FPSText.Text = math.floor(FPS) .. " fps"
        PingText.Text = math.floor(pingValue) .. " ms"
        
        -- No need to resize frame - it's now fixed size for vertical layout
    end)
end)

-- FPS Boost Utilities
local Services = setmetatable({}, {
    __index = function(_, k)
        return game:GetService(k)
    end
})
local PlayerData = {player = Players.LocalPlayer}

local maxFpsBoostConn, superMaxFpsBoostConn
local originalFpsCastShadows = {}
local originalFpsTransparency = {}
local originalFpsParticleStates = {}
local originalFpsMaterial = {}

local function enableCustomFpsBoost()
    -- Basic FPS boost: lower quality, remove textures, disable shadows
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.TextureQuality = Enum.TextureQuality.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Low
        game:GetService("Lighting").GlobalShadows = false
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then
                v.Transparency = 1
            end
        end
    end)
end

local function disableCustomFpsBoost()
    -- Restore some settings (optional, not all can be restored)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        settings().Rendering.TextureQuality = Enum.TextureQuality.Automatic
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Automatic
        game:GetService("Lighting").GlobalShadows = true
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then
                v.Transparency = 0
            end
        end
    end)
end

function enableMaxFpsBoost()
    enableCustomFpsBoost()
    -- Disable all shadows, all particles/trails/smokes, and set BasePart.Material to a darker material (e.g., Slate) for less brightness
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if originalFpsCastShadows[obj] == nil then
                    originalFpsCastShadows[obj] = obj.CastShadow
                    obj.Destroying:Connect(function() originalFpsCastShadows[obj] = nil end)
                end
                if originalFpsMaterial[obj] == nil then
                    originalFpsMaterial[obj] = obj.Material
                    obj.Destroying:Connect(function() originalFpsMaterial[obj] = nil end)
                end
                pcall(function()
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Slate -- Darker than SmoothPlastic
                    obj.Color = Color3.fromRGB(60, 60, 60)
                end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                if originalFpsParticleStates[obj] == nil then
                    originalFpsParticleStates[obj] = obj.Enabled
                    obj.Destroying:Connect(function() originalFpsParticleStates[obj] = nil end)
                end
                pcall(function() obj.Enabled = false end)
            end
        end
    end
    if maxFpsBoostConn then maxFpsBoostConn:Disconnect() end
    maxFpsBoostConn = trackConnection(Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if originalFpsCastShadows[obj] == nil then
                    originalFpsCastShadows[obj] = obj.CastShadow
                    obj.Destroying:Connect(function() originalFpsCastShadows[obj] = nil end)
                end
                if originalFpsMaterial[obj] == nil then
                    originalFpsMaterial[obj] = obj.Material
                    obj.Destroying:Connect(function() originalFpsMaterial[obj] = nil end)
                end
                pcall(function()
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Slate
                    obj.Color = Color3.fromRGB(60, 60, 60)
                end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                if originalFpsParticleStates[obj] == nil then
                    originalFpsParticleStates[obj] = obj.Enabled
                    obj.Destroying:Connect(function() originalFpsParticleStates[obj] = nil end)
                end
                pcall(function() obj.Enabled = false end)
            end
        end
    end), "MaxFpsBoost")
end

function disableMaxFpsBoost()
    disableCustomFpsBoost()
    for obj, val in pairs(originalFpsCastShadows) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.CastShadow = val end)
        end
    end
    originalFpsCastShadows = {}
    for obj, val in pairs(originalFpsMaterial) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.Material = val end)
        end
    end
    originalFpsMaterial = {}
    for obj, val in pairs(originalFpsParticleStates) do
        if obj and typeof(obj) == "Instance" and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")) then
            pcall(function() obj.Enabled = val end)
        end
    end
    originalFpsParticleStates = {}
    if maxFpsBoostConn then maxFpsBoostConn:Disconnect() maxFpsBoostConn = nil end
end

function enableSuperMaxFpsBoost()
    enableMaxFpsBoost()
    -- Set all BaseParts (except player's character and except whitelisted folders) to Transparency = 1, disable SurfaceGuis, BillboardGuis, Adornments
    local playerChar = PlayerData.player and PlayerData.player.Character
    local whitelist = {
        "Mobs", "QuestNPCs", "Ores", "MobPortals", "FishingSpots", "Dungeon", "Drops", "CraftingStations", "Characters", "BossRoom", "BossArenas"
    }
    local whitelistFolders = {}
    for _, name in ipairs(whitelist) do
        local folder = Services.Workspace:FindFirstChild(name)
        if folder then
            table.insert(whitelistFolders, folder)
        end
    end
    local function isWhitelisted(obj)
        for _, folder in ipairs(whitelistFolders) do
            if obj:IsDescendantOf(folder) then return true end
        end
        return false
    end
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent and (not playerChar or not obj:IsDescendantOf(playerChar)) then
                if not isWhitelisted(obj) then
                    if originalFpsTransparency[obj] == nil then
                        originalFpsTransparency[obj] = obj.Transparency
                        obj.Destroying:Connect(function() originalFpsTransparency[obj] = nil end)
                    end
                    pcall(function() obj.Transparency = 1 end)
                else
                    -- For whitelisted, enable noclip
                    pcall(function() obj.CanCollide = false end)
                end
            elseif (obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Adornment")) and not isWhitelisted(obj) then
                pcall(function() obj.Enabled = false end)
            end
        end
    end
    if superMaxFpsBoostConn then superMaxFpsBoostConn:Disconnect() end
    superMaxFpsBoostConn = trackConnection(Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent and (not playerChar or not obj:IsDescendantOf(playerChar)) then
                if not isWhitelisted(obj) then
                    if originalFpsTransparency[obj] == nil then
                        originalFpsTransparency[obj] = obj.Transparency
                        obj.Destroying:Connect(function() originalFpsTransparency[obj] = nil end)
                    end
                    pcall(function() obj.Transparency = 1 end)
                else
                    pcall(function() obj.CanCollide = false end)
                end
            elseif (obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Adornment")) and not isWhitelisted(obj) then
                pcall(function() obj.Enabled = false end)
            end
        end
    end), "SuperMaxFpsBoost")
end

function disableSuperMaxFpsBoost()
    disableMaxFpsBoost()
    for obj, val in pairs(originalFpsTransparency) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.Transparency = val end)
        end
    end
    originalFpsTransparency = {}
    if superMaxFpsBoostConn then superMaxFpsBoostConn:Disconnect() superMaxFpsBoostConn = nil end
end

-- Place the config FPS boost block here!
if config.supermaxfpsBoostenabled then
    enableSuperMaxFpsBoost()
elseif config.maxfpsBoostenabled then
    enableMaxFpsBoost()
elseif config.fpsBoostEnabled then
    enableCustomFpsBoost()
else
    disableSuperMaxFpsBoost()
    disableMaxFpsBoost()
    disableCustomFpsBoost()
end

local fpsBoostEnabled = false
local maxFpsBoostEnabled = false
local superMaxFpsBoostEnabled = false

local FpsBoostToggle = ThemeTab:AddToggle("FpsBoost", {
    Text = "FPS Boost",
    Default = config.fpsBoostEnabled,
    Tooltip = "Reduces graphics for better performance",
    Callback = function(Value)
        fpsBoostEnabled = Value
        config.fpsBoostEnabled = Value
        saveConfig()
        if Value then
            enableCustomFpsBoost()
        else
            disableCustomFpsBoost()
        end
    end
})

local MaxFpsBoostToggle = ThemeTab:AddToggle("MaxFpsBoost", {
    Text = "Max FPS Boost",
    Default = config.maxfpsBoostenabled,
    Tooltip = "Disables most effects for maximum FPS (also sets all parts to SmoothPlastic)",
    Callback = function(Value)
        maxFpsBoostEnabled = Value
        config.maxfpsBoostenabled = Value
        saveConfig()
        if Value then
            enableMaxFpsBoost()
        else
            disableMaxFpsBoost()
        end
    end
})

local SuperMaxFpsBoostToggle = ThemeTab:AddToggle("SuperMaxFpsBoost", {
    Text = "Super Max FPS Boost",
    Default = config.supermaxfpsBoostenabled,
    Tooltip = "Hides almost everything except mobs and some objects for ultimate FPS",
    Callback = function(Value)
        supermaxfpsBoostenabled = Value
        config.supermaxfpsBoostenabled = Value
        saveConfig()
        if Value then
            enableSuperMaxFpsBoost()
        else
            disableSuperMaxFpsBoost()
        end
    end
})

local CustomCursorToggle = ThemeTab:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = config.customCursorEnabled or true,
    Tooltip = "Enable/disable the custom cursor",
    Callback = function(Value)
        Library.ShowCustomCursor = Value
        config.customCursorEnabled = Value
        saveConfig()
    end
})


InfoGroup:AddLabel("Script by: Seisen")
InfoGroup:AddLabel("Version: 2.0.0")
InfoGroup:AddLabel("Game: Dungeon Heroes")

InfoGroup:AddButton("Join Discord", function()
    setclipboard("https://discord.gg/F4sAf6z8Ph")
end)

-- Enhanced cleanup function
local function performCompleteCleanup()
    if _CLEANUP_COMPLETED then return end
    _CLEANUP_COMPLETED = true
    
    -- Stop watermark connection
    if WatermarkConnection then
        WatermarkConnection:Disconnect()
    end
    
    -- Disconnect any remaining global input connections
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
    end
    if inputEndedConnection then
        inputEndedConnection:Disconnect()
    end
    
    -- Remove custom watermark
    if WatermarkGui then
        WatermarkGui:Destroy()
    end
    
    -- 1. Disconnect all tracked connections
    for name, connection in pairs(_SCRIPT_CONNECTIONS) do
        pcall(function()
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end)
    end
    _SCRIPT_CONNECTIONS = {}
    
    -- 2. Disconnect specific connections that might not be tracked
    local connectionsToClean = {
        noclipConnection,
        maxFpsBoostConn,
        superMaxFpsBoostConn
    }
    
    for _, conn in ipairs(connectionsToClean) do
        pcall(function()
            if conn and typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end)
    end
    
    -- 3. Stop all script loops by setting flags to false
    _G.killAuraEnabled = false
    if RuntimeState then
        RuntimeState.autoSkillEnabled = false
        RuntimeState.skillToggles = {}
    end
    autoFarmEnabled = false
    autoMiniBossEnabled = false
    autoStartDungeon = false
    autoReplyDungeon = false
    autoNextDungeon = false
    autoClaimDailyQuest = false
    autoEquipHighestWeapon = false
    autoSellEnabled = false
    fpsBoostEnabled = false
    maxFpsBoostEnabled = false
    superMaxFpsBoostEnabled = false
    config.autoMiniBossEnabled = false
    config.autoFarmEnabled = false
    config.killAuraEnabled = false
    config.autoSkillEnabled = false
    
    -- 4. Clean up BodyVelocity objects from character
    pcall(function()
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            for _, obj in ipairs(Character.HumanoidRootPart:GetChildren()) do
                if obj:IsA("BodyVelocity") then
                    obj:Destroy()
                end
            end
        end
    end)
    
    -- 5. Restore character collision
    pcall(function()
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
    
    -- 6. Restore FPS boost settings
    disableCustomFpsBoost()
    disableMaxFpsBoost()
    disableSuperMaxFpsBoost()
    
    -- 7. Clean up AntiAFK system
    if AntiAfkSystem and AntiAfkSystem.cleanup then
        pcall(function() AntiAfkSystem.cleanup() end)
    end
    
    -- 8. Clear global variables
    for k in pairs(_G) do
        if tostring(k):lower():find("killaura") or 
           tostring(k):lower():find("autoskill") or 
           tostring(k):lower():find("autofarm") or
           tostring(k):lower():find("dungeonheroes") then
            _G[k] = nil
        end
    end
    
    -- 9. Destroy UI
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and (
                gui.Name:lower():find("obsidian") or
                gui.Name:lower():find("dungeonheroes") or
                gui.Name:lower():find("dungeon_heroes") or
                gui.Name:lower():find("dhui") or
                gui.Name:lower():find("seisen")
            ) then
                pcall(function() gui:Destroy() end)
            end
        end
    end
    
    -- 10. Call Library unload
    if Library and Library.Unload then 
        pcall(function() Library:Unload() end)
    end
end

-- Move Unload UI button to ThemeTab in Settings
ThemeTab:AddButton({
    Text = "Unload UI",
    Func = performCompleteCleanup
})

-- At the top of the file (after Library is defined)
local pendingDPIScale = 100

ThemeTab:AddDropdown("UIScaleDropdown", {
    Text = "UI Scale",
    Values = {"75%", "100%", "125%", "150%"},
    Default = "100%",
    Callback = function(Value)
        local scale = tonumber(Value:match("%d+"))
        if scale then
            pendingDPIScale = scale
            Library:SetDPIScale(pendingDPIScale)
        end
    end
})

trackConnection(game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Library:SetDPIScale(pendingDPIScale)
    end
end), "UIScaleInput")



ThemeTab:AddLabel("Press Left-Alt to toggle the UI")

-- Show the UI
Library:Toggle(true)

--// Kill Aura Configuration
local attackInterval = 0.35 -- Much slower (very safe)
local attackRange = 100 -- Increased range for better mob detection
local maxMobsToAttack = 3 -- Maximum number of mobs to attack per cycle
local attackDelayBetweenMobs = 0.05 -- Delay between attacking each mob (in seconds)
local mobIndex = 1

--// Kill Aura Loop
trackTask(task.spawn(function()
    while true do
        if _G.killAuraEnabled and Character and HRP then
            -- Find all mobs within range and sort by distance
            local mobsInRange = {}
            for _, mob in ipairs(mobFolder:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Healthbar") then
                    -- Skip mobs that have PetHealthbar or PetIItemRef (pets)
                    if mob:FindFirstChild("PetHealthbar") or mob:FindFirstChild("PetIItemRef") then
                        continue
                    end
                    -- Skip TargetDummy mobs
                    if mob.Name == "TargetDummy" then
                        continue
                    end
                    
                    local mobHRP = mob.HumanoidRootPart
                    local dist = (HRP.Position - mobHRP.Position).Magnitude
                    if dist <= attackRange then
                        table.insert(mobsInRange, {mob = mob, distance = dist, hrp = mobHRP})
                    end
                end
            end
            
            -- Sort mobs by distance (closest first)
            table.sort(mobsInRange, function(a, b)
                return a.distance < b.distance
            end)
            
            -- Attack multiple mobs (up to maxMobsToAttack)
            local mobsAttacked = 0
            for _, mobData in ipairs(mobsInRange) do
                if mobsAttacked >= maxMobsToAttack then
                    break
                end
                
                local mob = mobData.mob
                local mobHRP = mobData.hrp
                
                -- Verify mob still exists and has healthbar
                if mob and mob.Parent and mobHRP and mobHRP.Parent and mob:FindFirstChild("Healthbar") then
                    -- DoEffect
                    local effectArgs = {
                        [1] = "SlashHit",
                        [2] = mobHRP.Position,
                        [3] = { mobHRP.CFrame }
                    }
                    pcall(function()
                        Effects:FireServer(unpack(effectArgs))
                    end)

                    -- PlayerAttack
                    local attackArgs = {
                        [1] = { mob }
                    }
                    pcall(function()
                        Combat:FireServer(unpack(attackArgs))
                    end)
                    
                    mobsAttacked = mobsAttacked + 1
                    
                    -- Small delay between attacking each mob
                    if mobsAttacked < maxMobsToAttack and attackDelayBetweenMobs > 0 then
                        task.wait(attackDelayBetweenMobs)
                    end
                end
            end
            
            -- Debug info removed for cleaner output
        end
        
        task.wait(attackInterval)
    end
end), "KillAuraLoop")



--// Auto Start Dungeon Loop
trackTask(task.spawn(function()
    while true do
        if autoStartDungeon then
            -- Try to start the dungeon using the correct remote event
            local success, err = pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Systems", 9e9)
                    :WaitForChild("Dungeons", 9e9)
                    :WaitForChild("TriggerStartDungeon", 9e9)
                    :FireServer()
            end)
            if not success then
                -- Error handling removed for cleaner output
            end
        end
        task.wait(0.5) -- Try every 2 seconds
    end
end), "AutoStartDungeonLoop")


local function getLastRoom()
    local DungeonRooms = workspace:FindFirstChild("DungeonRooms")
    if not DungeonRooms then return nil end
    local lastRoom = nil
    local maxNum = -math.huge
    for _, room in ipairs(DungeonRooms:GetChildren()) do
        local num = tonumber(room.Name)
        if num and num > maxNum then
            maxNum = num
            lastRoom = room
        end
    end
    return lastRoom
end

local function getLastRoomBossName()
    local lastRoom = getLastRoom()
    if not lastRoom then return nil end
    local mobSpawns = lastRoom:FindFirstChild("MobSpawns")
    if mobSpawns then
        local spawns = mobSpawns:FindFirstChild("Spawns")
        if spawns then
            -- If there is only one child, it's likely the boss
            for _, boss in ipairs(spawns:GetChildren()) do
                return boss.Name
            end
        end
    end
    return nil
end

local function bossInMobs(bossName)
    local Mobs = workspace:FindFirstChild("Mobs")
    if not Mobs then return false end
    return Mobs:FindFirstChild(bossName) ~= nil
end

-- Track completed dungeons (persistent)
local completedDungeons = config.completedDungeons or {}

local function getDungeonKey(entry)
    return tostring(entry.name) .. "_" .. tostring(entry.difficulty)
end

trackTask(task.spawn(function()
    while true do
        if autoNextDungeon then
            local nextIndex = nil
            local nextEntry = nil
            for i = 1, #dungeonSequence do
                local idx = ((dungeonSequenceIndex + i - 2) % #dungeonSequence) + 1
                local entry = dungeonSequence[idx]
                local key = getDungeonKey(entry)
                if not completedDungeons[key] then
                    nextIndex = idx
                    nextEntry = entry
                    break
                end
            end

            if nextEntry then
                local nextDisplayName = nextEntry.name
                for k, v in pairs(normalDungeonNameMap) do
                    if v == nextEntry.name then
                        nextDisplayName = k
                        break
                    end
                end
                local nextDifficultyText = ({
                    [1] = "Normal",
                    [2] = "Medium",
                    [3] = "Hard",
                    [4] = "Insane",
                    [5] = "Extreme",
                    [6] = "Nightmare",
                    [7] = "RAID"
                })[nextEntry.difficulty] or tostring(nextEntry.difficulty)

                Library:Notify({
                    Title = "Auto Next Dungeon Queue",
                    Description = "Next in queue: " .. nextDisplayName .. " [" .. nextDifficultyText .. "]",
                    Time = 4
                })
            end

            -- Find the next uncompleted dungeon in the sequence
            local nextIndex = nil
            for i = 1, #dungeonSequence do
                local idx = ((dungeonSequenceIndex + i - 2) % #dungeonSequence) + 1
                local entry = dungeonSequence[idx]
                local key = getDungeonKey(entry)
                if not completedDungeons[key] then
                    nextIndex = idx
                    break
                end
            end

            if not nextIndex then
                autoNextDungeon = false
                config.autoNextDungeon = false
                saveConfig()
                break
            end

            dungeonSequenceIndex = nextIndex
            local entry = dungeonSequence[dungeonSequenceIndex]
            local key = getDungeonKey(entry)

            -- Wait for boss in last room to be defeated (as before)
            local bossName = nil
            for i = 1, 600 do -- 5 minutes
                bossName = getLastRoomBossName()
                if bossName then
                    break
                end
                task.wait(1)
            end

            if bossName then
                local appeared = false
                for i = 1, 600 do -- 5 minutes for boss to appear
                    if bossInMobs(bossName) then
                        appeared = true
                        break
                    end
                    task.wait(1)
                end
                if appeared then
                    for i = 1, 60 do -- 5 minutes for boss to be defeated
                        if not bossInMobs(bossName) then
                            break
                        end
                        task.wait(1)
                    end
                    task.wait(math.random(2,4))
                else
                    task.wait(math.random(2,4))
                end
            else
                -- Boss not found handling
            end

            -- Start next dungeon in sequence
            local args = {
                [1] = entry.name,
                [2] = entry.difficulty,
                [3] = 1,
                [4] = false,
                [5] = false
            }
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Parties", 9e9):WaitForChild("SetSettings", 9e9):FireServer(unpack(args))
            end)
            task.wait(0.5)
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Systems", 9e9):WaitForChild("Dungeons", 9e9):WaitForChild("TriggerStartDungeon", 9e9):FireServer()
            end)

            -- Mark as completed and save
            completedDungeons[key] = true
            config.completedDungeons = completedDungeons
            saveConfig()

            -- Move to next in sequence for next loop
            dungeonSequenceIndex = dungeonSequenceIndex + 1
            if dungeonSequenceIndex > #dungeonSequence then
                dungeonSequenceIndex = 1
            end
        end
        task.wait(2)
    end
end), "AutoNextDungeonLoop")


-- Load config if file exists
if isfile(configFile) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            config[k] = v
        end
    end
end

-- Helper to save config
local function saveConfig()
    writefile(configFile, HttpService:JSONEncode(config))
end

KillAuraToggle:SetValue(config.killAuraEnabled)
AutoSkillToggle:SetValue(config.autoSkillEnabled)
AutoStartDungeonToggle:SetValue(config.autoStartDungeon)
AutoNextDungeonToggle:SetValue(config.autoNextDungeon)
AutoFarmToggle:SetValue(config.autoFarmEnabled)
AutoMiniBossToggle:SetValue(config.autoMiniBossEnabled)
FpsBoostToggle:SetValue(config.fpsBoostEnabled)
MaxFpsBoostToggle:SetValue(config.maxFpsBoostEnabled)
SuperMaxFpsBoostToggle:SetValue(config.supermaxfpsBoostenabled)
AutoReplyDungeonToggle:SetValue(config.autoReplyDungeon)
AutoClaimDailyQuestToggle:SetValue(config.autoClaimDailyQuest)
AutoEquipHighestWeaponToggle:SetValue(config.autoEquipHighestWeapon)
AutoFarmHeightSlider:SetValue(config.autoFarmHeight or autoFarmHeight)
AutoSellToggle:SetValue(config.autoSellEnabled)
AutoSellRarityDropdown:SetValue(config.autoSellRarity or selectedRarity)
