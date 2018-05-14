    if _G.Auto_Loaded then
        return 
    end

    local open               = io.open
    local concat             = table.concat
    local rep                = string.rep 
    local format             = string.format

    local AUTO_PATH			= 	COMMON_PATH.."Auto/"
    local dotlua			= 	".lua" 
    local charName			= 	myHero.charName 
    local shouldLoad		= 	{"Alpha"}

    local function readAll(file)
        local f = assert(open(file, "r"))
        local content = f:read("*all")
        f:close()
        return content
    end
    
    local function AutoUpdate()
        local CHAMP_PATH = AUTO_PATH..'/Champions/'
        local SCRIPT_URL = "https://raw.githubusercontent.com/Sikaka/WinRateEXT/GOSExternal/"
        local AUTO_URL     = "https://raw.githubusercontent.com/Sikaka/WinRateEXT/GOSExternal/master/Auto/"
        local CHAMP_URL  = "https://raw.githubusercontent.com/Sikaka/WinRateEXT/GOSExternal/master/Auto/Champions/"
        local versionControl     = AUTO_PATH .. "versionControl.lua"
        local versionControl2    = AUTO_PATH .. "versionControl2.lua"
        --
        local function serializeTable(val, name, depth) --recursive function to turn a table into plain text, pls dont mess with this
            skipnewlines = false
            depth = depth or 0
            local res = rep(" ", depth)
            if name then res = res .. name .. " = " end
            if type(val) == "table" then
                res = res .. "{" .. "\n"
                for k, v in pairs(val) do
                    res =  res .. serializeTable(v, k, depth + 4) .. "," .. "\n" 
                end
                res = res .. rep(" ", depth) .. "}"
            elseif type(val) == "number" then
                res = res .. tostring(val)
            elseif type(val) == "string" then
                res = res .. format("%q", val)
            end    
            return res
        end
        --
        local function TextOnScreen(str)
            local res = Game.Resolution() 
            Callback.Add("Draw", function()                       
                Draw.Text(str, 64, res.x/2-(#str * 10), res.y/2, Draw.Color(255,255,0,0))
            end)                        
        end
        --
        local function CheckFolders()
            local f = open(CHAMP_PATH.."folderTest", "w")
            if f then
                f:close()
                return true 
            end
            TextOnScreen("Check Installation Instructions on Forum!")
        end
        --
        local function DownloadFile(from, to, filename)
            DownloadFileAsync(from.."remote_"..filename, to..filename, function() end)            
            repeat until FileExist(to..filename)
        end
        --
        local function GetVersionControl()
            --[[First Time Being Run]]
            if not FileExist(versionControl) then 
                DownloadFileAsync(AUTO_URL.."remote_versionControl0", versionControl, function() end)          
                repeat until FileExist(versionControl)
            end             
            --[[Every Load]]  
            DownloadFileAsync(AUTO_URL.."remote_versionControl.lua", versionControl2, function() end)          
            repeat until FileExist(versionControl2)
        end
        --
        local function UpdateVersionControl(t)    
            local str = serializeTable(t, "Data") .. "\n\nreturn Data"    
            local f = assert(open(versionControl, "w"))
            f:write(str)
            f:close()
        end
        --
        local function CheckUpdate()
            local currentData, latestData = dofile(versionControl), dofile(versionControl2)
            --[[Loader Version Check]]
            if currentData.Loader.Version < latestData.Loader.Version then
                DownloadFile(SCRIPT_URL, SCRIPT_PATH, "A.lua")        
                currentData.Loader.Version = latestData.Loader.Version
                TextOnScreen("Please Reload The Script! [F6]x2")
            end
            --[[Core Check]]
            if currentData.Core.Version < latestData.Core.Version then
                --DownloadFile(AUTO_URL, AUTO_PATH, "core.lua")
                currentData.Core.Version = latestData.Core.Version
                currentData.Core.Changelog = latestData.Core.Changelog
            end
            --[[Active Champ Module Check]]            
            if not currentData.Champions[charName] or currentData.Champions[charName].Version < latestData.Champions[charName].Version then
                DownloadFile(CHAMP_URL, CHAMP_PATH, "WR_"..charName..dotlua)
                currentData.Champions[charName].Version = latestData.Champions[charName].Version
                currentData.Champions[charName].Changelog = latestData.Champions[charName].Changelog
            end
            --[[Dependencies Check]]
            for k,v in pairs(latestData.Dependencies) do
                if not currentData.Dependencies[k] or currentData.Dependencies[k].Version < v.Version then
                    DownloadFile(AUTO_URL, AUTO_PATH, k..dotlua)
                    currentData.Dependencies[k].Version = v.Version
                end
                local name = tostring(k)
                if v.Version >=1 and name ~= "commonLib" then
                    shouldLoad[#shouldLoad+1] = name
                end
            end
            --[[Utilities Check]]
            for k,v in pairs(latestData.Utilities) do
                if not currentData.Utilities[k] or currentData.Utilities[k].Version < v.Version then
                    DownloadFile(AUTO_URL, AUTO_PATH, k..dotlua)
                    currentData.Utilities[k].Version = v.Version
                end
                if v.Version >=1 then
                    shouldLoad[#shouldLoad+1] = tostring(k)
                end
            end
            shouldLoad[#shouldLoad+1] = "/Champion Modules/WR_"..charName
            UpdateVersionControl(currentData)
        end
        local function CheckSupported()
            local Data = dofile(versionControl2)
            return Data.Champions[charName]
        end
        if CheckFolders() then
            GetVersionControl()
            if CheckSupported() then  
                CheckUpdate()
                return true
            end
        end
    end

    local function LoadAuto()         
        local function writeModule(content)            
            local f = assert(open(AUTO_PATH.."activeModule.lua", content and "a" or "w"))
            if content then
                f:write(content)
            end
            f:close()        
        end
        --        
        writeModule()
        for i=1, #shouldLoad do
            local dependency = readAll(concat({AUTO_PATH, shouldLoad[i], dotlua}))
            writeModule(dependency)    
        end                          
        dofile(AUTO_PATH.."activeModule"..dotlua) 
    end

    --WR--

    function OnLoad()   
        if AutoUpdate() then
            _G.Auto_Loaded = true
            LoadAuto()
        end
    end    
