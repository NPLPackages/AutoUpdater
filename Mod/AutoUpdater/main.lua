--[[
Title: 
Author(s): leio
Date: 2017/10/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/AutoUpdater/main.lua");
------------------------------------------------------------
]]
local AutoUpdater = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.AutoUpdater"));

function AutoUpdater:ctor()
end

-- virtual function get mod name
function AutoUpdater:GetName()
	return "AutoUpdater"
end

-- virtual function get mod description 
function AutoUpdater:GetDesc()
	return "AutoUpdater is a plugin in paracraft"
end

function AutoUpdater:init()
	LOG.std(nil, "info", "AutoUpdater", "plugin initialized");

    NPL.load("(gl)Mod/AutoUpdater/AssetsManager.lua");
    local AssetsManager = commonlib.gettable("Mod.AutoUpdater.AssetsManager");
    local a = AssetsManager:new();
    a:loadConfig("Mod/AutoUpdater/configs/paracraft.xml");
end

function AutoUpdater:OnLogin()
end
-- called when a new world is loaded. 

function AutoUpdater:OnWorldLoad()
end
-- called when a world is unloaded. 

function AutoUpdater:OnLeaveWorld()
end

function AutoUpdater:OnDestroy()
end

