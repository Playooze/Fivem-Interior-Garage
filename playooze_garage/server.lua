
local resourceName = tostring(GetCurrentResourceName())
local function savePlayerFile(player, data)
    local fileName = GetPlayerIdentifiers(player)[2]
    local ret = SaveResourceFile(resourceName, "saves/"..fileName..".json", data, -1)
    return ret
end
local function loadPlayerFile(player)
    local fileName = GetPlayerIdentifiers(player)[2]
    local ret = LoadResourceFile(resourceName, "saves/"..fileName..".json")
    if ret then return ret else return "[]" end
end

local carLocations = {
    {223.4,-1001,-100,-60},
    {223.4,-996,-100,-60},
    {223.4,-991,-100,-60},
    {223.4,-986,-100,-60},
    {223.4,-981,-100,-60},
    {232.7,-1001,-100,60},
    {232.7,-996,-100,60},
    {232.7,-991,-100,60},
    {232.7,-986,-100,60},
    {232.7,-981,-100,60},
}

RegisterServerEvent("playooze_garage:reqVehicles")
AddEventHandler("playooze_garage:reqVehicles", function(player)
    local ply = player or source
    local data = json.decode(loadPlayerFile(ply)) or {}
    TriggerClientEvent("playooze_garage:recVehicles",source,data)
end)

RegisterServerEvent("playooze_garage:saveVehicle")
AddEventHandler("playooze_garage:saveVehicle", function(vehicleData, location, position, oldLocation)
    local player = source
    local data = json.decode(loadPlayerFile(player)) or {}
    if not data[location] then data[location] = {} end
    local oldLocation = oldLocation or location
    if not data[oldLocation] then data[oldLocation] = {} end

    if location == oldLocation then
        if not position then
            local found = false
            for i=1,#carLocations do
                if data[location][i] == nil or data[location][i] == "none" then
                    data[location][i] = vehicleData
                    found = true
                    break
                end
            end
            if not found then TriggerClientEvent("playooze_garage:savecallback", source, "no_slot") return end
        else
            data[location][position] = vehicleData
        end
    else
        if data[oldLocation] then
            data[oldLocation][position] = "none"
        end

        local found = false
        for i=1,#carLocations do
            if data[location][i] == nil or data[location][i] == "none" then
                data[location][i] = vehicleData
                found = true
                break
            end
        end
        if not found then TriggerClientEvent("playooze_garage:savecallback", source, "no_slot") return end
    end
    savePlayerFile(player, json.encode(data))

    TriggerClientEvent("playooze_garage:savecallback", source, "success")
end)
