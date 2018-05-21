if _G.Auto_Loaded then
	return 
end

local osclock			= os.clock;
local open               = io.open
local concat             = table.concat
local rep                = string.rep 
local format             = string.format

local AUTO_PATH			= 	COMMON_PATH.."Auto/"
local dotlua			= 	".lua" 
local coreName			=	"Core.lua"
local charName			= 	myHero.charName

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
		
		local startTime = osclock()
		DownloadFileAsync(from..filename, to..filename, function() end)		
		repeat until osclock() - startTime > 5 or FileExist(to..filename)
		--print("Downloading: " .. from.. filename)
		--print("To: " .. to.. filename)
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
		local f = assert(open(AUTO_PATH..oldVersion, "w"))
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
		
		--Load all dependencies
		local currentData = dofile(AUTO_PATH..oldVersion)		
		for k,v in pairs(currentData.Dependencies) do
			if FileExist(AUTO_PATH..k..dotlua) then
				dofile(AUTO_PATH..k..dotlua) 
			end
		end		
		
		--Write the core module
		writeModule(readAll(AUTO_PATH..coreName))
		writeModule(readAll(CHAMP_PATH..charName..dotlua))
				
		--Load the active module
		dofile(AUTO_PATH.."dynamicScript"..dotlua) 
    end	    
	
	local function CheckUpdate()
		local currentData, latestData = dofile(AUTO_PATH..oldVersion), dofile(AUTO_PATH..newVersion)
		if currentData.Loader.Version < latestData.Loader.Version then
			DownloadFile(SCRIPT_URL, SCRIPT_PATH, "A.lua")        
			currentData.Loader.Version = latestData.Loader.Version
		end
		
		for k,v in pairs(latestData.Dependencies) do
			if not FileExist(AUTO_PATH..k..dotlua) or not currentData.Dependencies[k] or currentData.Dependencies[k].Version < v.Version then
				DownloadFile(AUTO_URL, AUTO_PATH, k..dotlua)				
				if not currentData.Dependencies[k] then
					currentData.Dependencies[k] = v
				else
					currentData.Dependencies[k].Version = v.Version
				end
			end
		end
		
		for k,v in pairs(latestData.Champions) do
			if not FileExist(CHAMP_PATH..k..dotlua) or not currentData.Champions[k] or currentData.Champions[k].Version < v.Version then
				print("Downloading Champion Script: " .. k)
				DownloadFile(CHAMP_URL, CHAMP_PATH, k..dotlua)
				if not currentData.Champions[k] then
					currentData.Champions[k] = v
				else
					currentData.Champions[k].Version = v.Version
				end
			end
		end
		
		if currentData.Core.Version < latestData.Core.Version or not FileExist(AUTO_PATH.."Core.lua") then
			DownloadFile(AUTO_URL, AUTO_PATH, "Core.lua")        
			currentData.Core.Version = latestData.Core.Version
		end
		
		UpdateVersionControl(currentData)
		
		if CheckSupported() then
			InitializeScript()
		else
			print("Champion not supported: ".. myHero.charName)
		end
	end
	
	GetVersionControl()
	CheckUpdate()
end
	
function OnLoad()
	_G.Auto_Loaded = true
	AutoUpdate()
end