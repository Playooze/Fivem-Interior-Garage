if Config.Framework == 'QB' then QBCore = exports['qb-core']:GetCoreObject() end
if Config.Framework == 'ESX' then ESX = exports["es_extended"]:getSharedObject() end

Citizen.CreateThread(function()
    while not GarageConfig do Citizen.Wait(0) end
        
    xnGarage_default = {
        vehicleTaken = false,
        vehicleTakenPos = false,
        curGarage = false,
        curGarageName = false,
        vehicles = {},
    } playoozeGarage = playoozeGarage or xnGarage_default
    
    
    local vehicleTable
    
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
    
    local camCoord = {235.76, -1005.16, -100.0, 81.08}
    local outMarker = {239.08, -1004.8, -100.0}
    
    local spawnInLocation = {228.08, -1004.56, -99.0,349.64}
    local shell_coords = GetEntityCoords(ped)-vector3(0,0,30)
    local shell_door_coords = vector3(shell_coords.x+7, shell_coords.y-19, shell_coords.z)
    
    
    function GetVehicle(ply,doesNotNeedToBeDriver)
        local found = false
        local ped = GetPlayerPed((ply and ply or -1))
        local veh = 0
        if IsPedInAnyVehicle(ped) then
            veh = GetVehiclePedIsIn(ped, false)
        end
        if veh ~= 0 then
            if GetPedInVehicleSeat(veh, -1) == ped or doesNotNeedToBeDriver then
                found = true
            end
        end
        return found, veh, (veh ~= 0 and GetEntityModel(veh) or 0)
    end

    
    RegisterNetEvent('playooze_garage:CancelCamOption')
    AddEventHandler('playooze_garage:CancelCamOption', function()
        --DrawTextUI('show', '<b>'..Locales[Config.Language]['garage']..'<b/></p>'..Locales[Config.Language]['cancel_cam'])
        while cam ~= nil do
            Wait(5)
            if IsControlJustReleased(0, 18) then
                cam = nil
                DisableCam()
            end
        end
        --DrawTextUI('hide')
    end)
    

    RegisterNetEvent('playooze_garage:cam')
    AddEventHandler('playooze_garage:cam', function()
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", false)
        SetCamActive(cam, true)
        SetCamParams(cam, camCoord[1]-7, camCoord[2]+1, camCoord[3]+1,     5.27, 0.5186, 300.0,    70.0,       0, 1, 1, 2) --start cam location
        SetCamParams(cam, camCoord[1]-8, camCoord[2]+27, camCoord[3]+1,     5.27, 0.5186, 200.0,   70.0,      6000, 0, 0, 2) --end cam location
        RenderScriptCams(true, false, 3000, 1, 1)
        if cam == nil then return end
        Wait(5500)
        if cam == nil then return end
        DoScreenFadeOut(500)
        Wait(500)
        if cam == nil then return end
        stage2()
    end)

    
    function stage2()
        DoScreenFadeIn(500)
        if cam == nil then return end
        SetCamParams(cam, camCoord[1]-9, camCoord[2]+27, camCoord[3]+1,     5.27, 0.5186, 100.0,       70.0,       0, 1, 1, 2) --start cam location
        SetCamParams(cam, camCoord[1]-8, camCoord[2]+1, outMarker[3]+1,    5.27, 0.5186, 0.0,         70.0,      6000, 0, 0, 2) --end cam location
        RenderScriptCams(true, false, 3000, 1, 1)
        if cam == nil then return end
        Wait(7000)
        DisableCam()
    end
    
    function DisableCam()
        in_cam = false
        SetCamActive(cam, false)
        DestroyCam(cam, false)
        RenderScriptCams(false, true, 500, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
    end

    local lock_fancyteleport = false
    local function FancyTeleport(ent,x,y,z,h,fOut,hold,fIn,resetCam)
        if not lock_fancyteleport then
            lock_fancyteleport = true
            Citizen.CreateThread(function() Citizen.Wait(6000) DoScreenFadeIn(500) end)
            Citizen.CreateThread(function()
                FreezeEntityPosition(ent, true)
                
                DoScreenFadeOut(fOut or 500)
                while IsScreenFadingOut() do Citizen.Wait(0) end
                
                SetEntityCoords(ent, x, y, z)
                if h then SetEntityHeading(ent, h) SetGameplayCamRelativeHeading(0) end
                if GetVehicle() then SetVehicleOnGroundProperly(ent) end
                FreezeEntityPosition(ent, false)
                
                Citizen.Wait(hold or 2500)
                
                DoScreenFadeIn(fIn or 500)
                while IsScreenFadingIn() do Citizen.Wait(0) end
                
                lock_fancyteleport = false
                
            end)
        end
    end
    
    local function ToCoord(t,withHeading)
        if withHeading == true then
            local h = (t[4]+0.0) or 0.0
            return (t[1]+0.0),(t[2]+0.0),(t[3]+0.0),h
        elseif withHeading == "only" then
            local h = (t[4]+0.0) or 0.0
            return h
        else
            return (t[1]+0.0),(t[2]+0.0),(t[3]+0.0)
        end
    end
    
    -- These vehicle functions are not /fully/ mine.
    -- I forgot where I took the originals from but I *did* modify them for my own use.
    -- Credit to whoever actually made the original functions.
    local function DoesVehicleHaveExtras( veh )
        for i = 1, 30 do
            if ( DoesExtraExist( veh, i ) ) then
                return true
            end
        end
        
        return false
    end

    local function VehicleToData(veh)
        local vehicleTableData = {}
        
        local model = GetEntityModel( veh )
        local primaryColour, secondaryColour = GetVehicleColours( veh )
        local pearlColour, wheelColour = GetVehicleExtraColours( veh )
        local mod1a, mod1b, mod1c = GetVehicleModColor_1( veh )
        local mod2a, mod2b = GetVehicleModColor_2( veh )
        local custR1, custG2, custB3, custR2, custG2, custB2
        
        if ( GetIsVehiclePrimaryColourCustom( veh ) ) then
            custR1, custG1, custB1 = GetVehicleCustomPrimaryColour( veh )
        end
        
        if ( GetIsVehicleSecondaryColourCustom( veh ) ) then
            custR2, custG2, custB2 = GetVehicleCustomSecondaryColour( veh )
        end
        
        vehicleTableData[ "model" ] = tostring( model )
        vehicleTableData[ "primaryColour" ] = primaryColour
        vehicleTableData[ "secondaryColour" ] = secondaryColour
        vehicleTableData[ "pearlColour" ] = pearlColour
        vehicleTableData[ "wheelColour" ] = wheelColour
        vehicleTableData[ "mod1Colour" ] = { mod1a, mod1b, mod1c }
        vehicleTableData[ "mod2Colour" ] = { mod2a, mod2b }
        vehicleTableData[ "custPrimaryColour" ] =  { custR1, custG1, custB1 }
        vehicleTableData[ "custSecondaryColour" ] = { custR2, custG2, custB2 }
        
        local livery = GetVehicleLivery( veh )
        local plateText = GetVehicleNumberPlateText( veh )
        local plateType = GetVehicleNumberPlateTextIndex( veh )
        local wheelType = GetVehicleWheelType( veh )
        local windowTint = GetVehicleWindowTint( veh )
        local burstableTyres = GetVehicleTyresCanBurst( veh )
        local customTyres = GetVehicleModVariation( veh, 23 )
        
        vehicleTableData[ "livery" ] = livery
        vehicleTableData[ "plateText" ] = plateText
        vehicleTableData[ "plateType" ] = plateType
        vehicleTableData[ "wheelType" ] = wheelType
        vehicleTableData[ "windowTint" ] = windowTint
        vehicleTableData[ "burstableTyres" ] = burstableTyres
        vehicleTableData[ "customTyres" ] = customTyres
        
        local neonR, neonG, neonB = GetVehicleNeonLightsColour( veh )
        local smokeR, smokeG, smokeB = GetVehicleTyreSmokeColor( veh )
        
        local neonToggles = {}
        
        for i = 0, 3 do
            if ( IsVehicleNeonLightEnabled( veh, i ) ) then
                table.insert( neonToggles, i )
            end
        end
        
        vehicleTableData[ "neonColour" ] = { neonR, neonG, neonB }
        vehicleTableData[ "smokeColour" ] = { smokeR, smokeG, smokeB }
        vehicleTableData[ "neonToggles" ] = neonToggles
        
        local extras = {}
        
        
        if ( DoesVehicleHaveExtras( veh ) ) then
            for i = 1, 30 do
                if ( DoesExtraExist( veh, i ) ) then
                    if ( IsVehicleExtraTurnedOn( veh, i ) ) then
                        table.insert( extras, i )
                    end
                end
            end
        end
        
        vehicleTableData[ "extras" ] = extras
        
        local mods = {}
        
        for i = 0, 49 do
            local isToggle = ( i >= 17 ) and ( i <= 22 )
            
            if ( isToggle ) then
                mods[i] = IsToggleModOn( veh, i )
            else
                mods[i] = GetVehicleMod( veh, i )
            end
        end
        
        vehicleTableData[ "mods" ] = mods
        
        local ret = vehicleTableData
        
        return ret
    end

    local function CreateVehicleFromData(data, x,y,z,h, dontnetwork)
        
        local model = data[ "model" ]
        local primaryColour = data[ "primaryColour" ]
        local secondaryColour = data[ "secondaryColour" ]
        local pearlColour = data[ "pearlColour" ]
        local wheelColour = data[ "wheelColour" ]
        local mod1Colour = data[ "mod1Colour" ]
        local mod2Colour = data[ "mod2Colour" ]
        local custPrimaryColour = data[ "custPrimaryColour" ]
        local custSecondaryColour = data[ "custSecondaryColour" ]
        local livery = data[ "livery" ]
        local plateText = data[ "plateText" ]
        local plateType = data[ "plateType" ]
        local wheelType = data[ "wheelType" ]
        local windowTint = data[ "windowTint" ]
        local burstableTyres = data[ "burstableTyres" ]
        local customTyres = data[ "customTyres" ]
        local neonColour = data[ "neonColour" ]
        local smokeColour = data[ "smokeColour" ]
        local neonToggles = data[ "neonToggles" ]
        local extras = data[ "extras" ]
        local mods = data[ "mods" ]
        
        local veh = CreateVehicle(tonumber(model), x,y,z,h,not dontnetwork)
        
        -- Set the mod kit to 0, this is so we can do shit to the car
        SetVehicleModKit( veh, 0 )
        
        SetVehicleTyresCanBurst( veh, burstableTyres )
        SetVehicleNumberPlateTextIndex( veh,  plateType )
        SetVehicleNumberPlateText( veh, plateText )
        SetVehicleWindowTint( veh, windowTint )
        SetVehicleWheelType( veh, wheelType )
        
        for i = 1, 30 do
            if ( DoesExtraExist( veh, i ) ) then
                SetVehicleExtra( veh, i, true )
            end
        end
        
        for k, v in pairs( extras ) do
            local extra = tonumber( v )
            SetVehicleExtra( veh, extra, false )
        end
        
        for k, v in pairs( mods ) do
            local k = tonumber( k )
            local isToggle = ( k >= 17 ) and ( k <= 22 )
            
            if ( isToggle ) then
                ToggleVehicleMod( veh, k, v )
            else
                SetVehicleMod( veh, k, v, 0 )
            end
        end
        
        local currentMod = GetVehicleMod( veh, 23 )
        SetVehicleMod( veh, 23, currentMod, customTyres )
        SetVehicleMod( veh, 24, currentMod, customTyres )
        
        if ( livery ~= -1 ) then
            SetVehicleLivery( veh, livery )
        end
        
        SetVehicleExtraColours( veh, pearlColour, wheelColour )
        SetVehicleModColor_1( veh, mod1Colour[1], mod1Colour[2], mod1Colour[3] )
        SetVehicleModColor_2( veh, mod2Colour[1], mod2Colour[2] )
        
        SetVehicleColours( veh, primaryColour, secondaryColour )
        
        if ( custPrimaryColour[1] ~= nil and custPrimaryColour[2] ~= nil and custPrimaryColour[3] ~= nil ) then
            SetVehicleCustomPrimaryColour( veh, custPrimaryColour[1], custPrimaryColour[2], custPrimaryColour[3] )
        end
        
        if ( custSecondaryColour[1] ~= nil and custSecondaryColour[2] ~= nil and custSecondaryColour[3] ~= nil ) then
            SetVehicleCustomPrimaryColour( veh, custSecondaryColour[1], custSecondaryColour[2], custSecondaryColour[3] )
        end
        
        SetVehicleNeonLightsColour( veh, neonColour[1], neonColour[2], neonColour[3] )
        
        for i = 0, 3 do
            SetVehicleNeonLightEnabled( veh, i, false )
        end
        
        for k, v in pairs( neonToggles ) do
            local index = tonumber( v )
            SetVehicleNeonLightEnabled( veh, index, true )
        end
        
        SetVehicleDirtLevel(veh, 0.0)
        
        return veh
    end

    --Map Blips
    Citizen.CreateThread(function()
        local blips = {}
        for ln,loc in pairs(GarageConfig.locations) do
            local x,y,z = ToCoord(loc.inLocation,false) -- Get coords
            local blip = AddBlipForCoord(x,y,z) -- Create blip
            
            -- Set blip option
            SetBlipSprite(blip, 357)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, 26)
            SetBlipAsShortRange(blip, true)
            SetBlipCategory(blip, 9)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(GarageConfig.GroupMapBlips and "Garage" or ln)
            EndTextCommandSetBlipName(blip)
            
            -- Save handle to blip table
            blips[#blips+1] = blip
        end
    end)

    local vehicleTable = {}
    RegisterNetEvent("playooze_garage:recVehicles")
    AddEventHandler("playooze_garage:recVehicles", function(data)
        vehicleTable = data
    end)

    RegisterNetEvent("playooze_garage:message")
    AddEventHandler("playooze_garage:message", function(content,time)
        SetNotificationTextEntry("STRING")
        SetNotificationColorNext(0)
        AddTextComponentSubstringPlayerName(content)
        DrawNotification(0,1)
    end)
    
    RegisterCommand("testnot", function(_,args)
        
        
    end, false)
    
    local saveCallbackResponse = false
    RegisterNetEvent("playooze_garage:savecallback")
    AddEventHandler("playooze_garage:savecallback", function(response) saveCallbackResponse = response end)
    
    -- Load Garage
    function LoadGarage(wait)
        Citizen.CreateThread(function()
            local x,y,z = ToCoord(playoozeGarage.curGarage.inLocation, false)
            local int = GetInteriorAtCoords(x, y, z)
            if int then RefreshInterior(int) end
            
            if wait then
                BeginTextCommandBusyString("STRING")
                AddTextComponentSubstringPlayerName("Loading Garage")
                EndTextCommandBusyString(4)
                Citizen.Wait(wait)
                RemoveLoadingPrompt()
            end
            
            vehicleTable = false
            TriggerServerEvent("playooze_garage:reqVehicles")
            while not vehicleTable do Citizen.Wait(0) end
            local vt = vehicleTable
            
            for _,oldVeh in pairs(playoozeGarage.vehicles) do
                SetEntityAsMissionEntity(oldVeh)
                DeleteVehicle(oldVeh)
            end
            playoozeGarage.vehicles = {}
            
            if vehicleTable and vehicleTable[playoozeGarage.curGarageName] then
                for pos=1,#carLocations do -- Something weird with JSON causes something to be stupid with null keys
                    local vehData = vehicleTable[playoozeGarage.curGarageName][pos]
                    if vehData and vehData ~= "none" then
                        Citizen.CreateThread(function()
                            local isInVehicle, veh, vehModel = GetVehicle()
                            local x,y,z,h = ToCoord(carLocations[pos], true)
                            local model = tonumber(vehData["model"])
                            if playoozeGarage.vehicleTakenLoc == playoozeGarage.curGarageName and playoozeGarage.vehicleTaken and pos == playoozeGarage.vehicleTakenPos and not IsEntityDead(playoozeGarage.vehicleTaken) then
                            else
                                -- Load
                                RequestModel(model)
                                while not HasModelLoaded(model) do Citizen.Wait(0) end
                                
                                -- Create
                                playoozeGarage.vehicles[pos] = CreateVehicleFromData(vehData, x,y,z+1.0,h,true)
                                
                                -- Godmode
                                SetEntityInvincible(playoozeGarage.vehicles[pos], true)
                                SetEntityProofs(playoozeGarage.vehicles[pos], true, true, true, true, true, true, 1, true)
                                SetVehicleTyresCanBurst(playoozeGarage.vehicles[pos], false)
                                SetVehicleCanBreak(playoozeGarage.vehicles[pos], false)
                                SetVehicleCanBeVisiblyDamaged(playoozeGarage.vehicles[pos], false)
                                SetEntityCanBeDamaged(playoozeGarage.vehicles[pos], false)
                                SetVehicleExplodesOnHighExplosionDamage(playoozeGarage.vehicles[pos], false)
                            end
                            Citizen.CreateThread(function()
                                while true do
                                    Citizen.Wait(0)
                                    local isInVehicle, veh = GetVehicle()
                                    if isInVehicle and veh == playoozeGarage.vehicles[pos] then
                                        local x,y,z = table.unpack(GetEntityVelocity(veh))
                                        if (x > 0.5 or y > 0.5 or z > 0.5) or (x < -0.5 or y < -0.5 or z < -0.5) then
                                            Citizen.CreateThread(function()
                                                playoozeGarage.vehicleTakenPos = pos
                                                playoozeGarage.vehicleTakenLoc = playoozeGarage.curGarageName
                                                
                                                local ent = GetPlayerPed(-1)
                                                local x,y,z,h = ToCoord(playoozeGarage.curGarage.spawnOutLocation, true)
                                                
                                                DoScreenFadeOut(500)
                                                while IsScreenFadingOut() do Citizen.Wait(0) end
                                                FreezeEntityPosition(ent, true)
                                                SetEntityCoords(ent, x, y, z)
                                                
                                                -- Delete All Prev Vehicles
                                                for i,veh in ipairs(playoozeGarage.vehicles) do
                                                    SetEntityAsMissionEntity(veh)
                                                    DeleteVehicle(veh)
                                                    Citizen.Wait(10)
                                                end
                                                if playoozeGarage.vehicleTaken then DeleteVehicle(playoozeGarage.vehicleTaken) end -- Delete the last vehicle taken out if there is one
                                                
                                                -- Create new vehicle
                                                playoozeGarage.vehicleTaken = CreateVehicleFromData(vehData, x,y,z+1.0,h)
                                                FreezeEntityPosition(playoozeGarage.vehicleTaken, true)
                                                Citizen.Wait(1000)
                                                SetEntityAsMissionEntity(playoozeGarage.vehicleTaken)
                                                
                                                SetPedIntoVehicle(ent, playoozeGarage.vehicleTaken, -1) -- Put the ped into the new vehicle
                                                Citizen.Wait(1000)
                                                
                                                FreezeEntityPosition(ent, false)
                                                FreezeEntityPosition(playoozeGarage.vehicleTaken, false)
                                                Citizen.Wait(1000)
                                                
                                                DoScreenFadeIn(500)
                                                while IsScreenFadingIn() do Citizen.Wait(0) end
                                                
                                                playoozeGarage.curGarage = false
                                                playoozeGarage.curGarageName = false
                                            end)
                                            break
                                        end
                                    end
                                end
                            end)
                        end)
                    end
                end
            end
        end)
    end
    
    -- Main
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local isInVehicle, veh, vehModel = GetVehicle()
            local onSavecar = false
            local onCoord = false
            local onOutMarker = false
            if not playoozeGarage.curGarage then
                for ln,location in pairs(GarageConfig.locations) do
                    local ent = isInVehicle and veh or GetPlayerPed(-1)
                    local ix,iy,iz = ToCoord(location.inLocation,false)
                    local ox,oy,oz = ToCoord(location.saveCar, true)
                    local ex,ey,ez = spawnInLocation.x,spawnInLocation.y,spawnInLocation.z
                                        
                    local allowed = true
                    if IsThisModelABoat(vehModel) then allowed = false end
                    if IsThisModelAPlane(vehModel) then allowed = false end
                    if IsThisModelAHeli(vehModel) then allowed = false end
                    for _,blockedModel in ipairs(GarageConfig.BlacklistedVehicles) do
                        if GetHashKey(blockedModel) == vehModel then allowed = false end
                    end
                    -- With ped
                    if Vdist2(GetEntityCoords(ent),ix,iy,iz) < 5 and not isInVehicle then
                        onCoord = true
                        onOutMarker = false
                        if IsControlJustReleased(0, 51) then
                            playoozeGarage.curGarage = location
                            playoozeGarage.curGarageName = ln
                            if GarageConfig.PrintGarageName then print("[DEBUG] Entered Garage: "..tostring(ln)) end
                            LoadGarage()
                            local x,y,z,h = ToCoord(spawnInLocation, true)
                            FancyTeleport(ent, x,y,z,h)
                            Citizen.Wait(500)
                            
                            saveCallbackResponse = false
                            Citizen.Wait(2000)
                            TriggerEvent('playooze_garage:cam')
                            TriggerEvent('playooze_garage:CancelCamOption')
                        end

                        
                    else 
                        onCoord = false
                    end

                    -- with car
                    if Vdist2(GetEntityCoords(ent),ox,oy,oz) < GarageConfig.StoreCar_Distance and isInVehicle then
                        onSavecar = true
                        
                        if IsControlJustReleased(0, 51) then  --- save car but dont enter garage
                            if allowed then
                                SetVehicleHalt(veh,1.0,1) -- Nice Native!
                                playoozeGarage.curGarage = location
                                playoozeGarage.curGarageName = ln
                                if GarageConfig.PrintGarageName then print("[DEBUG] Entered Garage: "..tostring(ln)) end

                                saveCallbackResponse = false
                                if playoozeGarage.vehicleTaken ~= veh then
                                    TriggerServerEvent("playooze_garage:saveVehicle",VehicleToData(veh),ln)
                                else
                                    TriggerServerEvent("playooze_garage:saveVehicle",VehicleToData(veh),ln,playoozeGarage.vehicleTakenPos,playoozeGarage.vehicleTakenLoc)
                                end

                                while not saveCallbackResponse do Citizen.Wait(0) end

                                if saveCallbackResponse == "no_slot" then
                                    playoozeGarage.curGarage = false
                                    playoozeGarage.curGarageName = false
                                    if Config.Framework == 'ESX' and Config.Notify == 'ESX' then
                                        
                                        ESX.ShowNotification(Translations.No_Slot)
                                    elseif Config.Framework == 'QB' and Config.Notify == 'QB' then
                                        
                                        QBCore.Functions.Notify(Translations.No_Slot, "error", 1500, {showDuration = false, fadeIn = 500, fadeOut = 500})
                                    elseif Config.Framework == 'Default' and Config.Notify == 'OKOK' then
                                        exports['okokNotify']:Alert(Translations.Garage, Translations.No_Slot, 1500, 'error')
                                    end
                                end

                                Citizen.Wait(1000)

                                if saveCallbackResponse == "success" then
                                    local lastVeh = veh
                                    playoozeGarage.vehicleTaken = false
                                    playoozeGarage.vehicleTakenPos = false
                                    playoozeGarage.vehicleTakenLoc = false

                                    Citizen.Wait(1000)
                                    SetEntityAsMissionEntity(lastVeh)
                                    DeleteVehicle(lastVeh)
                                    playoozeGarage.curGarage = false
                                    playoozeGarage.curGarageName = false
                                end
                                
                            elseif not allowed then
                                if Config.Framework == 'ESX' and Config.Notify == 'ESX' then
                                    
                                   ESX.ShowNotification(Translations.Cannot_Store)
                                elseif Config.Framework == 'QB' and Config.Notify == 'QB' then
                                    
                                    QBCore.Functions.Notify(Translations.Cannot_Store, "error", 1500, {showDuration = false, fadeIn = 500, fadeOut = 500})
                                elseif Config.Framework == 'Default' and Config.Notify == 'OKOK' then
                                    exports['okokNotify']:Alert(Translations.Garage, Translations.Cannot_Store, 1500, 'error')
                                end
                            end

                            saveCallbackResponse = false

                        elseif IsControlJustReleased(0, 304) then  ---  save car and enter inside garage
                            if allowed then
                                SetVehicleHalt(veh,1.0,1) -- Nice Native!
                                playoozeGarage.curGarage = location
                                playoozeGarage.curGarageName = ln
                                if GarageConfig.PrintGarageName then print("[DEBUG] Entered Garage: "..tostring(ln)) end

                                saveCallbackResponse = false
                                if playoozeGarage.vehicleTaken ~= veh then
                                    TriggerServerEvent("playooze_garage:saveVehicle",VehicleToData(veh),ln)
                                else
                                    TriggerServerEvent("playooze_garage:saveVehicle",VehicleToData(veh),ln,playoozeGarage.vehicleTakenPos,playoozeGarage.vehicleTakenLoc)
                                end

                                while not saveCallbackResponse do Citizen.Wait(0) end

                                if saveCallbackResponse == "no_slot" then
                                    playoozeGarage.curGarage = false
                                    playoozeGarage.curGarageName = false
                                    if Config.Framework == 'ESX' and Config.Notify == 'ESX' then
                                        
                                        ESX.ShowNotification(Translations.No_Slot)
                                    elseif Config.Framework == 'QB' and Config.Notify == 'QB' then
                                        
                                        QBCore.Functions.Notify(Translations.No_Slot, "error", 1500, {showDuration = false, fadeIn = 500, fadeOut = 500})
                                    elseif Config.Framework == 'Default' and Config.Notify == 'OKOK' then
                                        exports['okokNotify']:Alert(Translations.Garage, Translations.No_Slot, 1500, 'error')
                                    end
                                end

                                Citizen.Wait(1000)

                                if saveCallbackResponse == "success" then
                                    local lastVeh = veh
                                    playoozeGarage.vehicleTaken = false
                                    playoozeGarage.vehicleTakenPos = false
                                    playoozeGarage.vehicleTakenLoc = false
                                    LoadGarage()
                                    local x,y,z,h = ToCoord(spawnInLocation, true)
                                    FancyTeleport(GetPlayerPed(-1), x,y,z,h)
                                    Citizen.Wait(1000)
                                    SetEntityAsMissionEntity(lastVeh)
                                    DeleteVehicle(lastVeh)
                                    Citizen.Wait(2000)
                                    TriggerEvent('playooze_garage:cam')
                                    TriggerEvent('playooze_garage:CancelCamOption')
                                end

                                saveCallbackResponse = false
                                
                            elseif not allowed then
                                if Config.Framework == 'ESX' and Config.Notify == 'ESX' then
                                    
                                   ESX.ShowNotification(Translations.Cannot_Store)
                                elseif Config.Framework == 'QB' and Config.Notify == 'QB' then
                                    
                                    QBCore.Functions.Notify(Translations.Cannot_Store, "error", 1500, {showDuration = false, fadeIn = 500, fadeOut = 500})
                                elseif Config.Framework == 'Default' and Config.Notify == 'OKOK' then
                                    exports['okokNotify']:Alert(Translations.Garage, Translations.Cannot_Store, 1500, 'error')
                                end
                            end
                        end
                        
                    else
                        onSavecar = false
                    end
                    
                end
            else
                local gr = playoozeGarage.curGarage
                local ent = isInVehicle and veh or GetPlayerPed(-1)
                -- Exit Marker
                local ox,oy,oz = ToCoord(outMarker)
                if Vdist2(GetEntityCoords(ent),ToCoord(outMarker)) <= 4.5 then
                    onOutMarker = true
                    if IsControlJustReleased(0, 51) then
                        local x,y,z,h = ToCoord(playoozeGarage.curGarage.inLocation,true)
                        local ix,iy,iz = ToCoord(gr.inLocation,false)
                        local rad = 5
                        FancyTeleport(ent, x,y,z,h, 500,2000,500, true)
                        Citizen.Wait(3000)
                        playoozeGarage.curGarage = false
                        playoozeGarage.curGarageName = false
                        playoozeGarage = playoozeGarage or xnGarage_default
                        Citizen.Wait(500)
                        while Vdist2(GetEntityCoords(ent),ix,iy,iz) < rad*2.5 do Citizen.Wait(0) end
                    end
                end
                
            end
            
            if onCoord then
                TriggerEvent('cd_drawtextui:ShowUI', 'show', Translations.Enter_Garage)
            elseif onSavecar then
                TriggerEvent('cd_drawtextui:ShowUI', 'show', Translations.Save_Vehicle)
            elseif onOutMarker then
                TriggerEvent('cd_drawtextui:ShowUI', 'show', Translations.Out_Garage)
            else
                TriggerEvent('cd_drawtextui:HideUI')
            end
            
        end
    end)
    
    
    -- Slow walk loop
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if playoozeGarage.curGarage and GarageConfig.RestrictActions then
                DisableControlAction(0, 22, true)
                DisablePlayerFiring(PlayerId(), true)
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while true do
            if GarageConfig.RestrictActions then
                local curGarage = playoozeGarage.curGarage
                while playoozeGarage.curGarage == curGarage do Citizen.Wait(0) end
                
                if playoozeGarage.curGarage then
                    SetCanAttackFriendly(GetPlayerPed(-1), false, false)
                    NetworkSetFriendlyFireOption(false)
                else
                    SetCanAttackFriendly(GetPlayerPed(-1), true, false)
                    NetworkSetFriendlyFireOption(true)
                end
            end
            Citizen.Wait(0)
        end
    end)
    
    
    -- Personal vehicle blip
    Citizen.CreateThread(function()
        local blip = false
        while true do
            Citizen.Wait(0)
            local prevEntId = playoozeGarage.vehicleTaken
            while not playoozeGarage.vehicleTaken or prevEntId == playoozeGarage.vehicleTaken do Citizen.Wait(0) end
            
            blip = AddBlipForEntity(playoozeGarage.vehicleTaken)
            
            SetBlipSprite(blip, 225)
            
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringTextLabel("PVEHICLE")
            EndTextCommandSetBlipName(blip)
            
            Citizen.CreateThread(function() -- I could probably make this better but eh
                local myBlip = blip
                while myBlip == blip do
                    Citizen.Wait(0)
                    local isInVehicle, veh = GetVehicle(_,true)
                    if isInVehicle and veh == playoozeGarage.vehicleTaken then
                        if GetBlipInfoIdDisplay(myBlip) ~= 3 then
                            SetBlipDisplay(myBlip, 3)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentSubstringTextLabel("PVEHICLE")
                            EndTextCommandSetBlipName(myBlip)
                        end
                    else
                        if GetBlipInfoIdDisplay(myBlip) ~= 2 then
                            SetBlipDisplay(myBlip, 2)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentSubstringTextLabel("PVEHICLE")
                            EndTextCommandSetBlipName(myBlip)
                        end
                    end
                    if IsEntityDead(playoozeGarage.vehicleTaken) then
                        RemoveBlip(myBlip)
                        break
                    end
                end
            end)
        end
    end)
    
    -- Hide players in garage
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if playoozeGarage.curGarage then
                for i=0,63 do
                    if i ~= GetPlayerServerId(PlayerId()) then
                        SetPlayerInvisibleLocally(GetPlayerFromServerId(i))
                    end
                end
            end
        end
    end)
    
end) -- no, this is not mismatched
