Config = {}
Config.Framework = 'ESX' -- ESX, or QB, or Default FOR OKOK notify
Config.Notify = 'ESX'  -- ESX, or QB or OKOK

Translations = {
    --cd draw text ui
    Notification = "Notificação",
    Garage = "Garagem",
    Enter_Garage = "<b>Garagem</b></p>[E] Entrar na garagem",
    Save_Vehicle = "<b>Garagem</b></p>[E] Guardar veículo </p>[H] Entrar na garagem",
    Out_Garage = "<b>Garagem</b></p>[E] Sair da garagem",
    Cam_Disable = "<b>Garagem</b></p>[BACKSPACE] Cancelar câmera", -- I didnt added the drawtext but if you want ...
    --okok notify
    No_Slot = "Sem espaço na garagem",
    Cannot_Store = "Não podes guardar este veículo",
}

GarageConfig = {
    RestrictActions = true, -- Disallows running, jumping and pvp while inside a garage
    GroupMapBlips = false, -- Groups all map blips under a single name   //  if true ,all have the save name,  if false, they have the name specified on locations

    BlacklistedVehicles = { -- A table of vehicles that should not be stored inside a garage
        "DUMP",
        "THRUSTER",
    },

    StoreCar_Distance = 30.0,  -- distance to save car in metres


    PrintGarageName = false, -- Debug option, prints the garages you enter into your console

    locations = {
        ["Garage A"] = {
        	inLocation = {213.8, -809.4, 31.0, 334.76}, -- get car

        	spawnOutLocation = {230.84, -800.08, 30.16, 157.68}, -- save car and store vehicle

            saveCar = {219.88, -800.6, 30.32, 162.44},

        },
        ["Garage B"] = {
        	inLocation = {842.108,-567.497437,56.7079239,99.1134338},

        	spawnOutLocation = {852.2358,-565.5245,56.7079239,-79.3211746},

            saveCar = {852.2358,-565.5245,56.7079239,-79.3211746},

        },
    },
}
