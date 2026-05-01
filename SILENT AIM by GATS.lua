-- SILENT AIM by GATS
local ev = require('lib.samp.events')    
local imgui = require 'mimgui'    
local encoding = require 'encoding'    
local inicfg = require 'inicfg'    
    
encoding.default = 'CP1251'    
u8 = encoding.UTF8    
    
-- MonetLoader / MoonLoader compatibility: safe wrapper for samp_create_sync_data    
local has_samp_create_sync = (type(samp_create_sync_data) == 'function')    
    
local function make_dummy_sync()    
    local storage = {}    
    local mt = {    
        __index = function(t,k) return storage[k] end,    
        __newindex = function(t,k,v) storage[k] = v end    
    }    
    local obj = { send = function() end }    
    return setmetatable(obj, mt)    
end    
    
local function safe_create_sync_data(sync_type, copy_from_player)    
    if has_samp_create_sync then    
        return samp_create_sync_data(sync_type, copy_from_player)    
    else    
        return make_dummy_sync()    
    end    
end    
-- End compatibility wrapper    
    
local renderWindow = imgui.new.bool(false)    
local frontX, frontY, frontZ, camX, camY, camZ = 0, 0, 0, 0, 0, 0    
    
local selectedTab = 1    
local shootingAtMe = -1    
local sidebarWidth = 220    
    
local deagle = imgui.new.float(800)    
    
local settings = {    
    search = {    
        canSee = imgui.new.bool(true),    
        radius = imgui.new.float(1000),    
        ignoreCars = imgui.new.bool(true),    
        ignoreObj = imgui.new.bool(true),    
        searchMethod = imgui.new.int(0),    
        useWeaponRadius = imgui.new.bool(true),    
        obxod = imgui.new.bool(false)    
    },    
    -- render group removed completely    
    shoot = {    
        misses = imgui.new.bool(true),    
        shotsPerMiss = imgui.new.int(3),    
        removeAmmo = imgui.new.bool(true),    
        doubledamage = imgui.new.bool(true),    
        tripledamage = imgui.new.bool(false),    
        printString = imgui.new.bool(true)    
    }    
}    
    
local state = false    
local canShoot = true    
local targetId = 0    
    
local miss = false    
local toMiss = 0    
    
math.randomseed(os.time())    
    
-- Modern by GATS Gold-Black Theme (ImGui)    
function darkgreentheme()    
    imgui.SwitchContext()    
    local style = imgui.GetStyle()    
    
    style.WindowRounding = 10    
    style.FrameRounding = 8    
    style.GrabRounding = 8    
    style.ScrollbarRounding = 8    
    style.WindowBorderSize = 0    
    style.FrameBorderSize = 0    
    style.ChildBorderSize = 0    
    style.PopupRounding = 6    
    style.TabRounding = 6    
    
    local colors = style.Colors    
    local clr = imgui.Col    
    local ImVec4 = imgui.ImVec4    
    
    local bg = ImVec4(0.06, 0.06, 0.07, 1.00)    
    local panel = ImVec4(0.09, 0.09, 0.10, 1.00)    
    local gold = ImVec4(0.97, 0.78, 0.18, 1.00)    
    local goldSoft = ImVec4(0.85, 0.72, 0.12, 1.00)    
    local white = ImVec4(1.00, 1.00, 1.00, 0.95)    
    local muted = ImVec4(0.75, 0.75, 0.75, 0.7)    
    
    colors[clr.Text]                = white    
    colors[clr.TextDisabled]        = muted    
    colors[clr.WindowBg]            = bg    
    colors[clr.ChildBg]             = panel    
    colors[clr.PopupBg]             = panel    
    
    colors[clr.Button]              = gold    
    colors[clr.ButtonHovered]       = goldSoft    
    colors[clr.ButtonActive]        = goldSoft    
    
    colors[clr.Header]              = gold    
    colors[clr.HeaderHovered]       = goldSoft    
    colors[clr.HeaderActive]        = gold    
    
    colors[clr.CheckMark]           = gold    
    colors[clr.SliderGrab]          = gold    
    colors[clr.SliderGrabActive]    = goldSoft    
    
    colors[clr.Tab]                 = ImVec4(0.10,0.10,0.11,1)    
    colors[clr.TabHovered]          = ImVec4(0.16,0.14,0.12,1)    
    colors[clr.TabActive]           = ImVec4(0.14,0.12,0.10,1)    
    
    colors[clr.TextSelectedBg]      = ImVec4(0.97,0.78,0.18,0.18)    
    colors[clr.ModalWindowDimBg]    = ImVec4(0,0,0,0.5)    
end    
    
imgui.OnInitialize(function()    
    imgui.GetIO().IniFilename = nil    
    darkgreentheme()    
end)    
    
-- UI Frame (sidebar + main) — render options removed    
local newFrame = imgui.OnFrame(    
    function() return renderWindow[0] end,    
    function(player)    
        local resX, resY = getScreenResolution()    
        local sizeX, sizeY = 920, 600    
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))    
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)    
        if imgui.Begin('SILENT AIM — by GATS', renderWindow, imgui.WindowFlags.NoCollapse) then    
            -- Sidebar    
            imgui.BeginChild('##sidebar', imgui.ImVec2(sidebarWidth, -1), true)    
                imgui.SetCursorPosY(8)    
                imgui.TextWrapped(u8' AUTHOR : GATS')    
                imgui.Spacing()    
                imgui.Separator()    
                imgui.Spacing()    
                if imgui.Button(u8'  CARI TARGET', imgui.ImVec2(sidebarWidth - 20, 40)) then selectedTab = 1 end    
                imgui.Spacing()    
                if imgui.Button(u8'  KILL', imgui.ImVec2(sidebarWidth - 20, 40)) then selectedTab = 2 end    
                imgui.Spacing()    
                imgui.Separator()    
                imgui.Spacing()    
                imgui.Text(u8'Status:')    
                imgui.SameLine()    
                imgui.Text(state and u8' ON' or u8' OFF')    
                imgui.Spacing()    
                imgui.Separator()    
                imgui.Spacing()    
                imgui.TextWrapped(u8'youtube: @callmedanii6666')    
            imgui.EndChild()    
    
            imgui.SameLine()    
            -- Main area    
            imgui.BeginChild('##main', imgui.ImVec2(-1, -1), false)    
                if selectedTab == 1 then    
                    imgui.Text(u8"cari target prioritas")    
                    imgui.Spacing()    
                    imgui.RadioButtonIntPtr(u8'saat darah sedikit', settings.search.searchMethod, 0)    
                    imgui.RadioButtonIntPtr(u8'saat musuh dekat', settings.search.searchMethod, 1)    
                    imgui.RadioButtonIntPtr(u8'saat anda di serang', settings.search.searchMethod, 2)    
                    imgui.Separator()    
                    imgui.Spacing()    
                    imgui.Checkbox(u8'abaikan kendaraan', settings.search.ignoreCars)    
                    imgui.Checkbox(u8'abaikan objek', settings.search.ignoreObj)    
                    imgui.Separator()    
                    imgui.Checkbox(u8'target harus ada di layar', settings.search.canSee)    
                    imgui.Separator()    
                    imgui.Checkbox(u8'Gunakan jangkauan senjata maksimum sebagai radius.', settings.search.useWeaponRadius)    
                    if not settings.search.useWeaponRadius[0] then    
                        imgui.SliderFloat(u8'Radius pencarian target', settings.search.radius, 1, 1000)    
                    end    
                elseif selectedTab == 2 then    
                    imgui.Text(u8'Kill / Shooting settings')    
                    imgui.Separator()    
                    imgui.Checkbox(u8'MISS (aktifkan peluru meleset)', settings.shoot.misses)    
                    if settings.shoot.misses[0] then    
                        imgui.PushItemWidth(260)    
                        imgui.SliderInt(u8'Jumlah tembakan beruntun tanpa meleset', settings.shoot.shotsPerMiss, 1, 10)    
                        imgui.PopItemWidth()    
                    end    
                    imgui.Separator()    
                    imgui.Checkbox(u8'Buang peluru saat ditembakkan', settings.shoot.removeAmmo)    
                    imgui.Checkbox(u8'Damage dua kali lipat', settings.shoot.doubledamage)    
                    if settings.shoot.doubledamage[0] then    
                        imgui.Checkbox(u8'Damage tiga kali lipat', settings.shoot.tripledamage)    
                    end    
                    imgui.Separator()    
                    imgui.Checkbox(u8'Tulis di bawah ini tentang target yang diserang', settings.shoot.printString)    
                    imgui.Spacing()    
                    imgui.TextWrapped(u8'Catatan: Fitur ini akan menampilkan pesan kecil saat tembakan berhasil atau meleset.')    
                end    
            imgui.EndChild()    
        end    
        imgui.End()    
    end    
)    
    
-- Main commands    
function main()    
    while not isSampAvailable() do wait(0) end    
    sampRegisterChatCommand('silent', function() renderWindow[0] = not renderWindow[0] end)    
    sampRegisterChatCommand("son", function()    
        state = not state    
        shootingAtMe = -1    
        sendMessage(state and 'SILENT by GATS [ ON ]' or 'SILENT by GATS [ OFF ]')    
        if state then    
            lua_thread.create(function()    
                while state do    
                    wait(50)    
                    -- use safe create for compatibility    
                    local p = safe_create_sync_data("player")    
                    local a = safe_create_sync_data("aim")    
                    if p and p.send then p.send() end    
                    if a and a.send then a.send() end    
                end    
            end)    
            lua_thread.create(function()    
                while state do    
                    wait(0)    
                    local ped = findPlayer()    
                    if ped ~= nil then    
                        local ok, id = sampGetPlayerIdByCharHandle(ped)    
                        if ok then    
                            targetId = id    
                        end    
                    else    
                        targetId = -1    
                    end    
                end    
            end)    
        end    
    end)    
end    
    
-- keep onReceiveRpc / onSendPacket handlers as-is    
function onReceiveRpc(id, bitStream)    
    if state and settings.search.obxod[0] then    
        if RPC[id] then return false end    
    end    
end    
    
function onSendPacket(id, bs, priority, reliability, orderingChannel)    
    if state and settings.search.obxod[0] then    
        if id == 204 then return false end    
    end    
end    
    
-- find player logic unchanged (with nil-safe checks)    
function findPlayer()    
    local peds = getAllChars()    
    local selectedPed = nil    
    local v = 1000000    
    for k, ped in pairs(peds) do    
        if ped ~= PLAYER_PED and (settings.search.canSee[0] and isCharOnScreen(ped) or not settings.search.canSee[0]) and not isCharDead(ped) then    
            local ok, id = sampGetPlayerIdByCharHandle(ped)    
            if ok and id then    
                local ok2, x, y, z = pcall(getCharCoordinates, ped)    
                if not ok2 or x == nil then goto cont end    
                local cHp = sampGetPlayerHealth(id) + sampGetPlayerArmor(id)    
                local mx, my, mz = getCharCoordinates(PLAYER_PED)    
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))    
                local dist = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)    
                if isLineOfSightClear(mx, my, mz, x, y, z, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) and dist < ((settings.search.useWeaponRadius[0] and weapon ~= nil and weapon.distance) or settings.search.radius[0]) then    
                    if settings.search.searchMethod[0] == 0 then    
                        if cHp < v then v = cHp; selectedPed = ped end    
                    elseif settings.search.searchMethod[0] == 1 then    
                        if dist < v then v = dist; selectedPed = ped end    
                    elseif settings.search.searchMethod[0] == 2 then    
                        if shootingAtMe == id then selectedPed = ped; break end    
                        if dist < v then v = dist; selectedPed = ped end    
                    end    
                end    
            end    
        end    
        ::cont::    
    end    
    return selectedPed    
end    
    
-- sendData kept minimal and safe    
function sendData()    
    local a = safe_create_sync_data("player")    
    local b = safe_create_sync_data("aim")    
    if a and a.send then a.send() end    
    if b and b.send then b.send() end    
end    
    
-- weapons table kept unchanged    
local weapons = {    
    {    
        id = 22,    
        delay = 160,    
        dmg = 8.25,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 23,    
        delay = 120,    
        dmg = 13.2,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 24,    
        delay = deagle[0],    
        dmg = 46.2,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 25,    
        delay = 800,    
        dmg = 3.3,    
        distance = 40,    
        camMode = 53,    
        weaponState = 1    
    },    
    {    
        id = 26,    
        delay = 120,    
        dmg = 3.3,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 27,    
        delay = 120,    
        dmg = 4.95,    
        distance = 40,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 28,    
        delay = 50,    
        dmg = 6.6,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 29,    
        delay = 90,    
        dmg = 8.25,    
        distance = 45,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 30,    
        delay = 90,    
        dmg = 9.9,    
        distance = 70,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 31,    
        delay = 90,    
        dmg = 9.9,    
        distance = 90,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 32,    
        delay = 70,    
        dmg = 6.6,    
        distance = 35,    
        camMode = 53,    
        weaponState = 2    
    },    
    {    
        id = 33,    
        delay = 800,    
        dmg = 24.75,    
        distance = 100,    
        camMode = 53,    
        weaponState = 1    
    },    
    {    
        id = 34,    
        delay = 900,    
        dmg = 41.25,    
        distance = 320,    
        camMode = 7,    
        weaponState = 1    
    },    
    {    
        id = 38,    
        delay = 20,    
        dmg = 46.2,    
        distance = 75,    
        camMode = 53,    
        weaponState = 2    
    },    
}    
    
function getWeaponInfoById(id)    
    for k, weapon in pairs(weapons) do    
        if weapon.id == id then    
            return weapon    
        end    
    end    
    return nil    
end    
    
function rand() return math.random(-50, 50) / 100 end    
    
function getMyId() return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) end    
    
function ev.onBulletSync(playerId, data)    
    if data.targetId == getMyId() then    
        shootingAtMe = playerId    
    end    
end    
    
function ev.onSendTakeDamage(playerId, damage, weapon, bodypart)    
    shootingAtMe = playerId    
end    
    
-- onSendPlayerSync: kept logic but made nil-safe    
function ev.onSendPlayerSync(data)    
    if state then    
        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)    
        if not res or ped == nil or not doesCharExist(ped) or isCharDead(ped) then return end    
    
        local ok2, x, y, z = pcall(getCharCoordinates, ped)    
        if not ok2 or x == nil then return end    
    
        local mx, my, mz = getCharCoordinates(PLAYER_PED)    
    
        local aangle = getHeadingFromVector2d(x - mx, y - my) * math.pi / 360.0    
        data.quaternion[0] = math.cos(aangle)    
        data.quaternion[3] = -math.sin(aangle)    
    
        data.keys.aim = 1    
    
        if canShoot then    
            local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))    
            if weapon ~= nil then    
                data.keys.secondaryFire_shoot = 1    
                lua_thread.create(function()    
                    canShoot = false    
                    if miss or not settings.shoot.misses[0] then miss = false end    
                    if toMiss >= settings.shoot.shotsPerMiss[0] then miss = true; toMiss = 0 end    
                    if not miss and settings.shoot.misses[0] then toMiss = toMiss + 1 end    
    
                    local sync = safe_create_sync_data('bullet')    
                    if miss then    
                        sync.targetType = 0    
                        sync.targetId = 65535    
                    else    
                        sync.targetType = 1    
                        sync.targetId = targetId    
                    end    
                    sync.center = {x = rand(), y = rand(), z = rand()}    
                    sync.origin = {x = mx + rand(), y = my + rand(), z = mz + rand()}    
                    sync.target = {x = x + rand(), y = y + rand(), z = z + rand()}    
                    sync.weaponId = getCurrentCharWeapon(PLAYER_PED)    
                    if sync.send then sync.send() end    
    
                    if settings.shoot.removeAmmo[0] then    
                        addAmmoToChar(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), -1)    
                    end    
    
                    if not miss then    
                        sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)    
                        if settings.shoot.doubledamage[0] then    
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)    
                            if settings.shoot.tripledamage[0] then    
                                sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)    
                            end    
                        end    
                    end    
    
                    if settings.shoot.printString[0] then    
                        printStringNow(miss and 'Shot missed' or string.format('Player ~r~%d ~w~damaged', targetId), 500)    
                    end    
    
                    wait(weapon.delay)    
                    canShoot = true    
                end)    
            end    
        end    
    end    
end    
    
-- onSendAimSync: nil-safe and kept logic    
function ev.onSendAimSync(data)    
    if not state then return end    
    
    local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)    
    if not res or ped == nil or not doesCharExist(ped) or isCharDead(ped) then return end    
    
    local ok2, x, y, z = pcall(getCharCoordinates, ped)    
    if not ok2 or x == nil then return end    
    
    local mx, my, mz = getCharCoordinates(PLAYER_PED)    
    
    local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))    
    if not weapon then return end    
    
    data.camMode = weapon.camMode    
    data.weaponState = weapon.weaponState    
    
    data.camPos.x = mx    
    data.camPos.y = my    
    data.camPos.z = mz    
    
    local dx = x - mx    
    local dy = y - my    
    local dz = z - mz    
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)    
    if len == 0 then len = 0.0001 end    
    
    data.camFront.x = dx / len    
    data.camFront.y = dy / len    
    data.camFront.z = dz / len    
end    
    
function vect3_length(x, y, z)    
    return math.sqrt(x * x + y * y + z * z)    
end    
    
function sendMessage(message)    
    sampAddChatMessage('{FFD300}[GATSONTOP] {FFFFFF}'..message, -1)    
end