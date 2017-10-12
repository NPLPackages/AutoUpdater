--[[
Title: 
Author(s): leio
Date: 2017/10/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/AutoUpdater/AssetsManager.lua");
local AssetsManager = commonlib.gettable("Mod.AutoUpdater.AssetsManager");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/XPath.lua");
NPL.load("(gl)script/ide/System/os/GetUrl.lua");

local AssetsManager = commonlib.inherit(nil,commonlib.gettable("Mod.AutoUpdater.AssetsManager"));
local FILE_LIST_FILE_EXT = ".p"
local next_value = 0;
local try_redownload_amx_num = 3;
AssetsManager.global_instances = {};
local function get_next_value()
    next_value = next_value + 1;
    return next_value;
end
AssetsManager.State = {
	UNCHECKED = get_next_value(),
	PREDOWNLOAD_VERSION = get_next_value(),
	DOWNLOADING_VERSION = get_next_value(),
	VERSION_CHECKED = get_next_value(),
	VERSION_ERROR = get_next_value(),
	PREDOWNLOAD_MANIFEST = get_next_value(),
	DOWNLOADING_MANIFEST = get_next_value(),
	MANIFEST_DOWNLOADED = get_next_value(),
	MANIFEST_ERROR = get_next_value(),
	PREDOWNLOAD_ASSETS = get_next_value(),
	DOWNLOADING_ASSETS = get_next_value(),
	ASSETS_DOWNLOADED = get_next_value(),
	ASSETS_ERROR = get_next_value(),
	PREUPDATE = get_next_value(),
	UPDATING = get_next_value(),
	UPDATED = get_next_value(),
	FAIL_TO_UPDATED = get_next_value()
};
AssetsManager.UpdateFailedReason = {
	MD5 = get_next_value(), 
    Uncompress = get_next_value(), 
    Move = get_next_value()
};
-- suppose version number "1.2.3", where 1 is the first(major) version, 2 is the second version, 3 is the third version.*/
AssetsManager.CheckVersionEnum = {
	CheckVersion_SameAsLast = 0, 
	CheckVersion_FirstVersionChanged = 1,
	CheckVersion_SecondVersionChanged = 2,
	CheckVersion_ThirdVersionChanged = 3,
    CheckVersion_Error = -1 
};
function AssetsManager:ctor()
    self.id = ParaGlobal.GenerateUniqueID();
    AssetsManager.global_instances[self.id] = self;
    self.configs = {
        versions = {},
        hosts = {},
        cmdline = nil,
        exename = nil,
        imageexename = nil,
    }

    self.writeablePath = nil;
    self.storagePath = nil;
    self.destStoragePath = nil;

    self.localVersionTxt = nil;
    self._cacheVersionPath = nil;
    self._cacheManifestPath = nil;

    self._curVersion = nil;
    self._latestVersion = nil;
    self._needUpdate = false;
    self._comparedVersion = nil;
    self._hasVersionFile = false;

    self._downloadUnits = {}; -- children is download_unit

    self._failedDownloadUnits = {};
    self._failedUpdateFiles = {};

    self._manifestTxt = "";

	self.validHostIndex = 1;

    self.try_num = 1;

    self._totalSize = 0;
end
function AssetsManager:onInit(writeablePath,config_filename,event_callback)
    local storagePath = writeablePath .. "caches/";
    local destStoragePath = writeablePath;
	local localVersionTxt = writeablePath .. "version.txt";

    self.writeablePath = writeablePath;
    self.storagePath = storagePath;
    self.destStoragePath = destStoragePath;

    self.localVersionTxt = localVersionTxt;
    self._cacheVersionPath = storagePath .. "version.manifest";
    self._cacheManifestPath = storagePath .. "project.manifest";
    self._asstesCachesPath = nil;

   

    self.event_callback = event_callback;
    echo("==========onInit");
    echo(self.localVersionTxt);
    echo(self._cacheVersionPath);
    echo(self._cacheManifestPath);

    self:loadConfig(config_filename)
end
function AssetsManager:callback(state)
    if(self.event_callback)then
        self.event_callback(state);
    end
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

-- step 1. check version
function AssetsManager:check(version,callback)
    self:callback(self.State.PREDOWNLOAD_VERSION);
    self._hasVersionFile = ParaIO.DoesFileExist(self.localVersionTxt);
    self._manifestTxt = "";
    self._totalSize = 0;

    if(not version or version == "")then
        self:loadLocalVersion();
    else
        self._curVersion = version;
    end
	LOG.std(nil, "debug", "AssetsManager", "local version is: %s",self._curVersion);
    self:downloadVersion(function()
	    LOG.std(nil, "debug", "AssetsManager", "remote version is: %s",self._latestVersion);
        self._comparedVersion = self:compareVersions();
	    LOG.std(nil, "debug", "AssetsManager", "compared result is: %d",self._comparedVersion);
        self._asstesCachesPath = self.storagePath .. self._latestVersion;
	    LOG.std(nil, "debug", "AssetsManager", "asstesCachesPath is: %s",self._asstesCachesPath);
	    ParaIO.CreateDirectory(self._asstesCachesPath);
        self:callback(self.State.VERSION_CHECKED);
        if(callback)then
            callback();
        end
    end);
end
function AssetsManager:loadLocalVersion()
    self._curVersion = "0";
    local file = ParaIO.open(self.localVersionTxt, "r");
	if(file:IsValid()) then
        local txt = file:GetText();
        if(txt)then
            txt = string.gsub(txt,"[%s\r\n]","");
            local __,v = string.match(txt,"(.+)=(.+)");
            self._curVersion = v;
        end
    end
end
function AssetsManager:downloadVersion(callback)
    local version_url = self.configs.versions[1];
    if(version_url)then
        System.os.GetUrl(version_url, function(err, msg, data)  
	        LOG.std(nil, "debug", "AssetsManager:downloadVersion err", err);
	        LOG.std(nil, "debug", "AssetsManager:downloadVersion msg", msg);
	        LOG.std(nil, "debug", "AssetsManager:downloadVersion data", data);
            if(err == 200)then
                if(data)then
                    local body = "<root>" .. data .. "</root>";
                    local xmlRoot = ParaXML.LuaXML_ParseString(body);
                    if(xmlRoot)then
                        local node;
	                    for node in commonlib.XPath.eachNode(xmlRoot, "//UpdateVersion") do
                            self._latestVersion = node[1];
                            break;
	                    end
                        if(callback)then
                            callback();
                        end
                    end
                end
            else
                self:callback(self.State.VERSION_ERROR);
            end
        end);
    end
end
function AssetsManager:compareVersions()
    if (self._curVersion == "0") then
		self._needUpdate = true;
		return self.CheckVersionEnum.CheckVersion_FirstVersionChanged;
	end
	if (self._curVersion == self._latestVersion) then
		self._needUpdate = false;
		return self.CheckVersionEnum.CheckVersion_SameAsLast;
    end

    local function get_versions(version_str)
        local result = {};
        local s;
        for s in string.gfind(version_str, "[^.]+") do
            table.insert(result,s);
		end
        return result; 
    end
        
    local cur_version_list = get_versions(self._curVersion);
    local latestVersion_list = get_versions(self._latestVersion);
    if(#cur_version_list < 3 or #latestVersion_list < 3)then
		return self.CheckVersionEnum.CheckVersion_Error;
    end
    if(cur_version_list[1] ~= latestVersion_list[1])then
        self._needUpdate = true;
		return self.CheckVersionEnum.CheckVersion_FirstVersionChanged;
    end
    if(cur_version_list[2] ~= latestVersion_list[2])then
        self._needUpdate = true;
		return self.CheckVersionEnum.CheckVersion_SecondVersionChanged;
    end
	self._needUpdate = true;
	return self.CheckVersionEnum.CheckVersion_ThirdVersionChanged;
end
-- step 2. download assets
function AssetsManager:download()
	if (not self._needUpdate)then
		return;
    end
	self.validHostIndex = 1;
    self.try_num = 1;
	self:downloadManifest(self._comparedVersion, self.validHostIndex);
end
function AssetsManager:downloadManifest(ret, hostServerIndex)
    local len = #self.configs.hosts;
    if (hostServerIndex > len)then
		return;
    end
	local updatePackUrl;
	if (self.CheckVersionEnum.CheckVersion_FirstVersionChanged == ret or self.CheckVersionEnum.CheckVersion_SecondVersionChanged == ret) then
		updatePackUrl = self:getPatchListUrl(true, hostServerIndex);
	elseif(self.CheckVersionEnum.CheckVersion_ThirdVersionChanged == ret)then
		updatePackUrl = self:getPatchListUrl(false, hostServerIndex);
	else
		updatePackUrl = self:getPatchListUrl(true, hostServerIndex);
	end
	self:callback(self.State.PREDOWNLOAD_MANIFEST);
	local hostServer = self.configs.hosts[hostServerIndex];
	LOG.std(nil, "debug", "AssetsManager", "checking host server: %s",hostServer);
	LOG.std(nil, "debug", "AssetsManager", "updatePackUrl is : %s",updatePackUrl);

    System.os.GetUrl(updatePackUrl, function(err, msg, data)  
        if(err == 200 and data)then
			self:callback(self.State.MANIFEST_DOWNLOADED);
            self:parseManifest(data);
            self:downloadAssets();
        else
            local len = #self.configs.hosts;
            if(self.validHostIndex >= len)then
                self:callback(self.State.MANIFEST_ERROR);
                return
            end
            self.validHostIndex = self.validHostIndex + 1;
	        self:downloadManifest(self._comparedVersion, self.validHostIndex);
        end
    end)
end
function AssetsManager:getPatchListUrl(is_full_list, nCandidate)
    local len = #self.configs.hosts;
	nCandidate = math.min(nCandidate, len);
	nCandidate = math.max(nCandidate, 1);
	local hostServer = self.configs.hosts[nCandidate];
	if (is_full_list) then
		local url;
		-- like this:"http://update.61.com/haqi/coreupdate/coredownload/0.7.272/list/full.txt"
		if (not self._latestVersion or self._latestVersion == "") then
			url = hostServer .. "coredownload/list/full" .. FILE_LIST_FILE_EXT;
		else
			url = hostServer .. "coredownload/" .. self._latestVersion .. "/list/full" .. FILE_LIST_FILE_EXT;
        end
		return url;
	else
		-- like this:"http://update.61.com/haqi/coreupdate/coredownload/0.7.272/list/patch_0.7.0.txt"
		return hostServer .. "coredownload/" .. self._latestVersion .. "/list/patch_" .. self._curVersion .. FILE_LIST_FILE_EXT;
	end
end
function AssetsManager:parseManifest(data)
    local hostServer = self.configs.hosts[self.validHostIndex];
	LOG.std(nil, "debug", "AssetsManager", "the valid host server is: %s",hostServer);
    local function split(str)
        local result = {};
        local s;
        for s in string.gfind(str, "[^,]+") do
            table.insert(result,s);
		end
        return result; 
    end
    local line;
    for line in string.gmatch(data,"([^\r\n]*)\r?\n?") do
        echo(line);
        if(line and line ~= "")then
            local arr = split(line);
            if(#arr > 2)then
                local filename = arr[1];
				local md5 = arr[2];
				local size = arr[3];
                local file_size = tonumber(size) or 0;
				self._totalSize = self._totalSize + file_size;
                local download_path = string.format("%s,%s,%s.p", filename, md5, size);
                local download_unit = {
                    srcUrl = string.format("%scoredownload/update/%s", hostServer, download_path),
                    storagePath = self._asstesCachesPath .. "/" .. filename,
                    customId = filename,
                    hasDownloaded = false,
                    totalFileSize = file_size,
                    PercentDone = 0,
                }
                if(ParaIO.DoesFileExist(download_unit.storagePath))then
                    if(self:checkMD5(download_unit.storagePath,size,md5))then
	                    LOG.std(nil, "debug", "AssetsManager", "this file has existed: %s",download_unit.storagePath);
                        download_unit.hasDownloaded = true;
                    end
                end
                table.insert(self._downloadUnits,download_unit);
            end
        end
    end
end
-- not test
function AssetsManager:checkMD5(finename,size,md5)
    local file = ParaIO.open(finename,"r");
    if(file:IsValid()) then
        local txt = file:GetText(0,-1);
        local v = ParaMisc.md5(txt);
        return v == md5;

    end
end
function AssetsManager:downloadAssets()
    self:callback(self.State.PREDOWNLOAD_ASSETS);
    self.download_next_asset_index = 1;
    self:downloadNextAsset(self.download_next_asset_index);
end
function AssetsManager:downloadNextAsset(index)
    local len = #self._downloadUnits;
    if(index > len)then
        local len = #self._failedDownloadUnits;
        if(len > 0)then
	        LOG.std(nil, "debug", "AssetsManager", "download assets uncompleted by loop:%d",self.try_num);
            if(self.try_num < try_redownload_amx_num)then
                self.try_num = self.try_num + 1;
                self._failedDownloadUnits = {};
                self:downloadAssets();
            else
                self:callback(self.State.ASSETS_ERROR);
            end
        else
            -- finished
	        LOG.std(nil, "debug", "AssetsManager", "all of assets have been downloaded");
            self:callback(self.State.ASSETS_DOWNLOADED);
        end
        return
    end
    local unit = self._downloadUnits[index];
    if(unit)then
        if(not unit.hasDownloaded)then
	        LOG.std(nil, "debug", "AssetsManager", "downloading: %s",unit.srcUrl);
	        LOG.std(nil, "debug", "AssetsManager", "temp storagePath: %s",unit.storagePath);
            local callback_str = string.format([[Mod.AutoUpdater.AssetsManager.downloadCallback("%s","%s")]],self.id,unit.customId);
	        NPL.AsyncDownload(unit.srcUrl, unit.storagePath, callback_str, unit.customId);
        else
            self:downloadNext();
        end
    end
end
function AssetsManager:downloadNext()
    self.download_next_asset_index = self.download_next_asset_index + 1;
    self:downloadNextAsset(self.download_next_asset_index);
end
function AssetsManager.downloadCallback(manager_id,id)
    local manager = AssetsManager.global_instances[manager_id];
    if(not manager)then
        return
    end
    echo("============downloading");
    echo(msg);
    if(msg)then
        local download_unit = manager._downloadUnits[manager.download_next_asset_index];
        local rcode = msg.rcode;
        if(rcode and rcode ~= 200)then
	        LOG.std(nil, "warnig", "AssetsManager", "download failed: %s",download_unit.srcUrl);
            table.insert(manager._failedDownloadUnits,download_unit);
            self:downloadNext();
            return
        end
        local PercentDone = msg.PercentDone or 0;
        local totalFileSize = msg.totalFileSize or 0;
        download_unit.PercentDone = PercentDone;
        if(PercentDone == 100)then
            download_unit.hasDownloaded = true;
            self:downloadNext();
            if(totalFileSize ~= download_unit.totalFileSize)then
	            LOG.std(nil, "warnig", "AssetsManager", "the size of this file is wrong: %s",download_unit.storagePath);
            end
        end
        manager:callback(manager.State.DOWNLOADING_ASSETS);
    end
end
function AssetsManager:getPercent()
    local size = 0;
    local k,v;
    for k,v in pairs(self._downloadUnits) do
        local totalFileSize = v.totalFileSize or 0;
        local PercentDone = v.PercentDone or 0;
        if(v.hasDownloaded)then
            size = size + totalFileSize;
        else
            size = size + totalFileSize * PercentDone;
        end
    end
    local percent;
    if(not self._totalSize or self._totalSize == 0)then
        percent = 0;
    else
        percent = size / self._totalSize;
    end
    return percent;
end
function AssetsManager.test()
    NPL.load("(gl)script/ide/timer.lua");
    local sdk_root = ParaIO.GetCurDirectory(0);
    NPL.load("(gl)Mod/AutoUpdater/AssetsManager.lua");
    local AssetsManager = commonlib.gettable("Mod.AutoUpdater.AssetsManager");
    local a = AssetsManager:new();
    a:onInit(sdk_root,"Mod/AutoUpdater/configs/paracraft.xml",function(state)
        echo("=========state");
        echo(state);
        if(state)then
            local timer;
            if(state == AssetsManager.State.PREDOWNLOAD_ASSETS)then
                local timer = commonlib.Timer:new({callbackFunc = function(timer)
                    echo(a:getPercent());
                end})
                timer:Change(0, 100)
            end
            if(state == AssetsManager.State.ASSETS_DOWNLOADED)then
                if(timer)then
                    timer:Change();
                end
            end    
        end
        
    end);
    a:check(nil,function()
        a:download();
    end);
end
