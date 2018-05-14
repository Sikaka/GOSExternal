if _G.Auto_Loaded then
	return 
end

local open               = io.open
local concat             = table.concat
local rep                = string.rep 
local format             = string.format

local AUTO_PATH			= 	COMMON_PATH.."Auto/"
local dotlua			= 	".lua" 
local coreName			=	"Core.lua"
local charName			= 	myHero.charName 
local shouldLoad		= 	{"Alpha"}

local function readAll(file)
	local f = assert(open(file, "r"))
	local content = f:read("*all")
	f:close()
	return content
end

local function AutoUpdate()
	local CHAMP_PATH = AUTO_PATH..'Champions/'
	local SCRIPT_URL = "https://raw.githubusercontent.com/Sikaka/GOSExternal/"
	local AUTO_URL     = "https://raw.githubusercontent.com/Sikaka/GOSExternal/master/Auto/"
	local CHAMP_URL  = "https://raw.githubusercontent.com/Sikaka/GOSExternal/master/Auto/Champions/"
	local oldVersion     = AUTO_PATH .. "currentVersion.lua"
	local newVersion    = AUTO_PATH .. "newVersion.lua"
	--
	--
	local function DownloadFile(from, to, filename)
		DownloadFileAsync(from..filename, to..filename, function() end)            
		repeat until FileExist(to..filename)
	end
	
	
	local function GetVersionControl()
		if not FileExist(oldVersion) then 
			DownloadFile(AUTO_URL, AUTO_PATH, oldVersion) 
		end
		DownloadFile(AUTO_URL, AUTO_PATH, newVersion)
	end        
	
	local function CheckUpdate()
		local currentData, latestData = dofile(versionControl), dofile(versionControl2)
		if currentData.Loader.Version < latestData.Loader.Version then
			DownloadFile(SCRIPT_URL, SCRIPT_PATH, "A.lua")        
			currentData.Loader.Version = latestData.Loader.Version
			TextOnScreen("Please Reload The Script! [F6]x2")
		end
		
		for k,v in pairs(latestData.Dependencies) do
			if not currentData.Dependencies[k] or currentData.Dependencies[k].Version < v.Version then
				DownloadFile(SCRIPT_URL, AUTO_PATH, k..dotlua)
				currentData.Dependencies[k].Version = v.Version
			end
		end
		
		for k,v in pairs(latestData.Champions) do
			if not currentData.Champions[k] or currentData.Champions[k].Version < v.Version then
				DownloadFile(SCRIPT_URL, CHAMP_PATH, k..dotlua)
				currentData.Champions[k].Version = v.Version
			end
		end
		
		if currentData.Core.Version < latestData.Core.Version then
			DownloadFile(SCRIPT_URL, AUTO_PATH, "Core.lua")        
			currentData.Core.Version = latestData.Core.Version
		end
		
		UpdateVersionControl(currentData)
		
		if CheckSupported() then
			InitializeScript()
		end
	end
			
	local function CheckSupported()
		local Data = dofile(newVersion)
		return Data.Champions[charName]
	end
	
	local function UpdateVersionControl(t)    
		local str = serializeTable(t, "Data") .. "\n\nreturn Data"    
		local f = assert(open(versionControl, "w"))
		f:write(str)
		f:close()
	end
	
	local function InitializeScript()         
        local function writeModule(content)            
            local f = assert(open(AUTO_PATH.."dynamicScript.lua", content and "a" or "w"))
            if content then
                f:write(content)
            end
            f:close()        
        end
        --        
        writeModule()
		
		--Write the core module
		writeModule(readAll(AUTO_PATH..coreName))
		writeModule(readAll(AUTO_PATH..charName..dotLua))
		
		--Load the active module
		dofile(AUTO_PATH.."dynamicScript"..dotlua) 
    end	
	
	GetVersionControl()
	CheckUpdate()
end
	
function OnLoad()
	_G.Auto_Loaded = true
	AutoUpdate()
end