script_name('vehicle_regent')
script_version('1.0')
script_author('Jack')
script_description('Regenerasi kendaraan - cmd /rv')

local sampev = require('lib.samp.events')
local state = false

function main()
    while not isSampAvailable() do wait(0) end
    sampAddChatMessage('SUBSCRIBE @FirmanSamp.{FF4A4A} CMD /rv', -1)
    sampRegisterChatCommand("rv", function()
        state = not state
        if state then
            sampAddChatMessage('Vehicle Regent: ON', -1)
        else
            sampAddChatMessage('Vehicle Regent: OFF', -1)
        end
    end)
    
    while true do
        wait(1000)  -- Tunggu 1 detik (1000 milidetik)
        if state then
            local vehicle = getCarCharIsUsing(PLAYER_PED)
            if vehicle and isCharInAnyCar(PLAYER_PED) then
                local vehicleHealth = getCarHealth(vehicle)
                if vehicleHealth < 1000 then
                    vehicleHealth = math.min(1000, vehicleHealth + 1000)  -- Tambah 1000 kesehatan, maksimal 1000
                    setCarHealth(vehicle, vehicleHealth)
                end
            end
        end
    end
end

function sampev.onSendPlayerSync(data)
    if state and isCharInAnyCar(PLAYER_PED) then
        local vehicle = getCarCharIsUsing(PLAYER_PED)
        if vehicle then
            data.vehicle_health = getCarHealth(vehicle)
        end
    end
end
