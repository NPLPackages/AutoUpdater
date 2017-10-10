--[[
Title: 
Author(s): leio
Date: 2017/10/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/AutoUpdater/Downloader.lua");
local Downloader = commonlib.gettable("Mod.AutoUpdater.Downloader");
------------------------------------------------------------
]]
local Downloader = commonlib.inherit(nil,commonlib.gettable("Mod.AutoUpdater.Downloader"));
function Downloader:ctor()
end