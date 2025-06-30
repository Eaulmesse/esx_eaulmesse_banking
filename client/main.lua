-- client/main.lua

ESX = nil -- Initialise la variable ESX à nil.
local PlayerData = {} -- Table pour stocker les données du joueur (argent liquide, banque).
local IsNuiOpen = false -- Variable pour suivre l'état de l'interface NUI.

-- Événement déclenché lorsque la ressource ESX est chargée et prête.
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Événement ESX qui se déclenche lorsque les données du joueur sont mises à jour.
-- Très utile pour garder PlayerData à jour sans faire de requêtes constantes.
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    for i=1, #PlayerData.accounts, 1 do
        if PlayerData.accounts[i].name == account.name then
            PlayerData.accounts[i].money = account.money
            break
        end
    end
end)

RegisterNetEvent('esx:setMoney')
AddEventHandler('esx:setMoney', function(money)
    PlayerData.money = money
end)


-- [[ FONCTIONS NUI ]] --

-- Fonction pour ouvrir l'interface NUI.
function OpenNUI()
    IsNuiOpen = true
    SetNuiFocus(true, true) -- Permet à la NUI de recevoir le focus du clavier/souris.
    -- Envoie un message à l'interface React pour l'ouvrir.
    SendNuiMessage(json.encode({
        type = "openBank",
        playerMoney = PlayerData.money, -- Envoie l'argent liquide
        bankBalance = PlayerData.accounts['bank'].money -- Envoie le solde bancaire
    }))
    -- Demande aussi au serveur le solde actuel pour s'assurer que c'est à jour.
    -- Cela peut être fait via un callback si tu préfères une synchronisation plus forte à l'ouverture.
    -- ESX.TriggerServerCallback('mon_script_bancaire:getBankBalance', function(bankBalance, playerMoney)
    --     SendNuiMessage(json.encode({
    --         type = "updateBalance",
    --         bankBalance = bankBalance,
    --         playerMoney = playerMoney
    --     }))
    -- end)
end

-- Fonction pour fermer l'interface NUI.
function CloseNUI()
    IsNuiOpen = false
    SetNuiFocus(false, false) -- Rend le focus au jeu.
    -- Envoie un message à l'interface React pour la fermer.
    SendNuiMessage(json.encode({
        type = "closeBank"
    }))
end

-- [[ GESTION DES TOUCHES ]] --

-- Thread pour vérifier si le joueur est proche d'un ATM et pour gérer l'ouverture/fermeture de la NUI.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Attendre 0ms pour ne pas saturer le CPU, mais permettre des mises à jour rapides.

        local playerPed = PlayerPedId() -- Récupère le Ped du joueur.
        local playerCoords = GetEntityCoords(playerPed) -- Récupère les coordonnées du joueur.
        local closestATM = nil
        local dist = 9999.0 -- Initialise une distance très grande.

        -- Vérifie la distance avec chaque ATM configuré.
        for i, v in ipairs(Config.ATMLocations) do
            local distance = GetDistanceBetweenCoords(playerCoords, v.x, v.y, v.z, true)
            if distance < dist then
                dist = distance
                closestATM = v -- Met à jour l'ATM le plus proche.
            end
        end

        -- Si le joueur est proche d'un ATM (par exemple, moins de 1.5 mètres).
        if closestATM and dist < 1.5 then
            ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le menu de la banque.')
            -- Si la touche configurée est pressée et que l'interface n'est pas déjà ouverte.
            if IsControlJustReleased(0, Config.OpenBankKey) and not IsNuiOpen then
                OpenNUI() -- Ouvre l'interface bancaire.
            end
        end

        -- Si la NUI est ouverte et que la touche d'échappement (INPUT_FRONTEND_CANCEL = 177) est pressée.
        if IsNuiOpen and IsControlJustReleased(0, 177) then -- 177 est le code pour ESC
            CloseNUI() -- Ferme l'interface.
        end
    end
end)

-- [[ GESTION DES MESSAGES NUI ]] --

-- Ce handler reçoit les messages envoyés depuis ton interface React (NUI).
RegisterNetEvent('__cfx_nui:esx_eaulmesse_banking:nui_callback')
AddEventHandler('__cfx_nui:esx_eaulmesse_banking:nui_callback', function(data)
    local action = data.action
    local amount = data.amount
    local targetId = data.targetId

    if action == 'deposit' then
        -- Envoie une requête au serveur pour déposer de l'argent.
        ESX.TriggerServerCallback('esx_eaulmesse_banking:depositMoney', function(success)
            if success then
                -- Si le dépôt réussit, met à jour les données du joueur (sera fait par esx:setAccountMoney/setMoney)
                -- et informe l'interface React de rafraîchir son état.
                ESX.TriggerServerCallback('esx_eaulmesse_banking:getBankBalance', function(bankBalance, playerMoney)
                    SendNuiMessage(json.encode({
                        type = "updateBalance",
                        bankBalance = bankBalance,
                        playerMoney = playerMoney
                    }))
                end)
            end
        end, amount)
    elseif action == 'withdraw' then
        -- Envoie une requête au serveur pour retirer de l'argent.
        ESX.TriggerServerCallback('esx_eaulmesse_banking:withdrawMoney', function(success)
            if success then
                -- Si le retrait réussit, met à jour les données du joueur et l'interface React.
                ESX.TriggerServerCallback('esx_eaulmesse_banking:getBankBalance', function(bankBalance, playerMoney)
                    SendNuiMessage(json.encode({
                        type = "updateBalance",
                        bankBalance = bankBalance,
                        playerMoney = playerMoney
                    }))
                end)
            end
        end, amount)
    elseif action == 'transfer' then
        -- Envoie une requête au serveur pour transférer de l'argent.
        ESX.TriggerServerCallback('esx_eaulmesse_banking:transferMoney', function(success)
            if success then
                -- Si le transfert réussit, met à jour les données du joueur et l'interface React.
                ESX.TriggerServerCallback('esx_eaulmesse_banking:getBankBalance', function(bankBalance, playerMoney)
                    SendNuiMessage(json.encode({
                        type = "updateBalance",
                        bankBalance = bankBalance,
                        playerMoney = playerMoney
                    }))
                end)
            end
        end, targetId, amount)
    elseif action == 'close' then
        CloseNUI() -- Ferme l'interface si l'action 'close' est reçue de la NUI.
    end
end)