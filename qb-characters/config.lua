Config = {}
Config.Interior = vector4(947.48919, 5.6392703, 116.16413, 335.52224) -- Interior to load where characters are previewed
Config.DefaultSpawn = vector4(-309.34, -1041.81, 66.52, 71.01) -- Default spawn coords if you have start apartments disabled
Config.PedCoords = vector4(947.48919, 5.6392703, 116.16413, 335.52224)       -- Create preview ped at these coordinates
Config.HiddenCoords = vector4(947.48919, 5.6392703, 116.16413, 335.52224)  -- Hides your actual ped Ma-cro guapo while you are in selection
Config.CamCoords = vector4(943.45104, 8.0688285, 117.31713 - 1.5, 190.22268) -- Camera coordinates for character preview screen Config.EnableDeleteButton = true -- Define if the player can delete the character or not
Config.EnableDeleteButton = true                                             -- Define if the player can delete the character or not
Config.customNationality = true                                             -- Defines if Nationality input is custom of blocked to the list of Countries
Config.ServerName = 'LCStore-Free'
Config.DefaultNumberOfCharacters = 4                                         -- Define maximum amount of default characters (maximum 5 characters defined by default)
Config.PlayersNumberOfCharacters = {                                         -- Define maximum amount of player characters by rockstar license (you can find this license in your server's database in the player table)
    { license = "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", numberOfChars = 2 },
}

Config.PedPos = {
    [1] = vector4(944.526, 1.9580096, 116.16411, 347.88085),
    [2] = vector4(943.81433, -0.538171, 116.16407, 358.42205),
    [3] = vector4(945.12115, -0.573394, 116.16411, 357.77169),
    [4] = vector4(942.5733, -0.068109, 116.16413, 238.00076)
}

