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
	local CHAMP_PATH			= AUTO_PATH..'Champions/'
	local SCRIPT_URL			= "https://raw.githubusercontent.com/Sikaka/GOSExternal/"
	local AUTO_URL				= "https://raw.githubusercontent.com/Sikaka/GOSExternal/master/Auto/"
	local CHAMP_URL				= "https://raw.githubusercontent.com/Sikaka/GOSExternal/master/Auto/Champions/"
	local oldVersion			= "currentVersion.lua"
	local newVersion			= "newVersion.lua"
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
	local function DownloadFile(from, to, filename)
		DownloadFileAsync(from..filename, to..filename, function() end)
		repeat until FileExist(to..filename)
		print("Downloading: " .. from.. filename)
		print("To: " .. to.. filename)
	end	
	
	local function GetVersionControl()
		if not FileExist(AUTO_PATH..oldVersion) then 
			DownloadFile(AUTO_URL, AUTO_PATH, oldVersion) 
		end
		DownloadFile(AUTO_URL, AUTO_PATH, newVersion)
	end    
			
	local function CheckSupported()
		local Data = dofile(AUTO_PATH..newVersion)
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
	
	local function CheckUpdate()
		print("1")
		local currentData, latestData = dofile(AUTO_PATH..oldVersion), dofile(AUTO_PATH..newVersion)
		if currentData.Loader.Version < latestData.Loader.Version then
			DownloadFile(SCRIPT_URL, SCRIPT_PATH, "A.lua")        
			currentData.Loader.Version = latestData.Loader.Version
		end
		print("2")
		
		for k,v in pairs(latestData.Dependencies) do
			if not currentData.Dependencies[k] or currentData.Dependencies[k].Version < v.Version then
				DownloadFile(AUTO_URL, AUTO_PATH, k..dotlua)
				currentData.Dependencies[k].Version = v.Version
			end
		end
		
		print("3")
		for k,v in pairs(latestData.Champions) do
			if not currentData.Champions[k] or currentData.Champions[k].Version < v.Version then
				DownloadFile(CHAMP_URL, CHAMP_PATH, k..dotlua)
				currentData.Champions[k].Version = v.Version
			end
		end
		
		print("4")
		if currentData.Core.Version < latestData.Core.Version or not FileExist(AUTO_PATH.."Core.lua") then
			DownloadFile(AUTO_URL, AUTO_PATH, "Core.lua")        
			currentData.Core.Version = latestData.Core.Version
		end
		
		print("5")
		UpdateVersionControl(currentData)
		
		print("6")
		if CheckSupported() then
			print("loading script")
			InitializeScript()
		else
			print("Champion not supported")
		end
		print("7")
	end
	
	GetVersionControl()
	CheckUpdate()
end
	
function OnLoad()
	_G.Auto_Loaded = true
	AutoUpdate()
end