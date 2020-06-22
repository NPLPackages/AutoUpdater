# AutoUpdater
Using npl to implement the logic of update
```lua
NPL.load("(gl)script/ide/timer.lua");
local redist_root = "test/";
ParaIO.CreateDirectory(redist_root);

local AutoUpdater = NPL.load("AutoUpdater");
local a = AutoUpdater:new();
local timer;
a:onInit(redist_root,"npl_mod/AutoUpdater/configs/paracraft.xml",function(state)

    if(state)then
        if(state == AutoUpdater.State.PREDOWNLOAD_VERSION)then
            echo("=========PREDOWNLOAD_VERSION");
        elseif(state == AutoUpdater.State.DOWNLOADING_VERSION)then
            echo("=========DOWNLOADING_VERSION");
        elseif(state == AutoUpdater.State.VERSION_CHECKED)then
            echo("=========VERSION_CHECKED");
        elseif(state == AutoUpdater.State.VERSION_ERROR)then
            echo("=========VERSION_ERROR");
        elseif(state == AutoUpdater.State.PREDOWNLOAD_MANIFEST)then
            echo("=========PREDOWNLOAD_MANIFEST");
        elseif(state == AutoUpdater.State.DOWNLOADING_MANIFEST)then
            echo("=========DOWNLOADING_MANIFEST");
        elseif(state == AutoUpdater.State.MANIFEST_DOWNLOADED)then
            echo("=========MANIFEST_DOWNLOADED");
        elseif(state == AutoUpdater.State.MANIFEST_ERROR)then
            echo("=========MANIFEST_ERROR");
        elseif(state == AutoUpdater.State.PREDOWNLOAD_ASSETS)then
            echo("=========PREDOWNLOAD_ASSETS");
            timer = commonlib.Timer:new({callbackFunc = function(timer)
                echo(a:getPercent());
            end})
            timer:Change(0, 100)
        elseif(state == AutoUpdater.State.DOWNLOADING_ASSETS)then
            echo("=========DOWNLOADING_ASSETS");
        elseif(state == AutoUpdater.State.ASSETS_DOWNLOADED)then
            echo("=========ASSETS_DOWNLOADED");
            echo(a:getPercent());
            if(timer)then
                timer:Change();
            end
            a:apply();
        elseif(state == AutoUpdater.State.ASSETS_ERROR)then
            echo("=========ASSETS_ERROR");
        elseif(state == AutoUpdater.State.PREUPDATE)then
            echo("=========PREUPDATE");
        elseif(state == AutoUpdater.State.UPDATING)then
            echo("=========UPDATING");
        elseif(state == AutoUpdater.State.UPDATED)then
            echo("=========UPDATED");
        elseif(state == AutoUpdater.State.FAIL_TO_UPDATED)then
            echo("=========FAIL_TO_UPDATED");
        end    
    end
end);
a:check(nil,function()
    local cur_version = a:getCurVersion();
    local latest_version = a:getLatestVersion();
    echo("=========version");
    echo({cur_version = cur_version, latest_version = latest_version});
    if(a:isNeedUpdate())then
        a:download();
    else
        echo("=========is latest version");
    end
end);
```
