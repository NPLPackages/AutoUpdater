--[[
Title: 
Author(s): leio
Date: 2017/10/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/AutoUpdater/AssetsManager.lua");
local AssetsManager = commonlib.gettable("Mod.AutoUpdater.AssetsManager");
local a = AssetsManager:new();
a:loadConfig("Mod/AutoUpdater/configs/paracraft.xml");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/XPath.lua");

local AssetsManager = commonlib.inherit(nil,commonlib.gettable("Mod.AutoUpdater.AssetsManager"));

function AssetsManager:ctor()
    self.configs = {
        versions = {},
        hosts = {},
        cmdline = nil,
        exename = nil,
        imageexename = nil,
    }
end
function AssetsManager:loadConfig(filename)
    if(not filename)then return end
    local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(not xmlRoot) then 
	    LOG.std(nil, "error", "AssetsManager", "file %s does not exist",filename);
		return 
	end
    local node;
    -- Getting versions
	for node in commonlib.XPath.eachNode(xmlRoot, "/configs/versions/url") do
        self.configs.versions[#self.configs.versions+1] = node[1];
	end
    -- Getting patch hosts
	for node in commonlib.XPath.eachNode(xmlRoot, "/configs/hosts/host") do
        self.configs.hosts[#self.configs.hosts+1] = node[1];
	end
    -- Getting command line
	for node in commonlib.XPath.eachNode(xmlRoot, "/configs/cmdline") do
        self.configs.cmdline = node[1];
        break;
	end
    -- Getting exename
    for node in commonlib.XPath.eachNode(xmlRoot, "/configs/exename") do
        self.configs.exename= node[1];
        break;
	end
    -- Getting image exe name
    for node in commonlib.XPath.eachNode(xmlRoot, "/configs/imageexename") do
        self.configs.imageexename= node[1];
        break;
	end
    log(self.configs);
end
function AssetsManager:check(version)
end
function AssetsManager:downloadVersion()
end