-- client/main.lua

ESX = nil -- Initialise la variable ESX à nil.
local PlayerData = {} -- Table pour stocker les données du joueur (argent liquide, banque).
local IsNuiOpen = false -- Variable pour suivre l'état de l'interface NUI.
local HasLoaded = false --Suit le chargement de PlayerData

-- !!! NOUVEAU BLOC D'INITIALISATION D'ESX PLUS ROBUSTE !!!
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100) -- Attend un court instant pour éviter de surcharger le CPU
    end
    print('[CLIENT] ESX a été chargé avec succès !')
    -- Une fois ESX chargé, nous pouvons potentiellement récupérer les données initiales du joueur.
    -- Les événements esx:playerLoaded, etc., continueront de les mettre à jour par la suite.
    -- Ce n'est pas essentiel pour le SetNuiFocus, mais bonne pratique.
    -- ESX.TriggerServerCallback('esx:getPlayerInventory', function(inventory)
    --     PlayerData = inventory -- Ou une structure similaire à celle de esx:playerLoaded
    -- end)
end)
-- !!! FIN DU NOUVEAU BLOC !!!


-- Événements ESX qui se déclenchent lorsque les données du joueur sont mises à jour.
-- Ces blocs sont corrects et devraient rester tels quels après le bloc d'initialisation d'ESX.
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    HasLoaded = true -- NOUVEAU : PlayerData est maintenant disponible
    print('[CLIENT] esx:playerLoaded déclenché pour ' .. xPlayer.name)
    print('[CLIENT] PlayerData loaded for ' .. xPlayer.name)
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


--- FONCTIONS NUI ---

-- Fonction pour ouvrir l'interface NUI.
-- Prend en paramètre le type de lieu (bank/atm) pour que la NUI puisse s'adapter.

function OpenNUI(locationType)
    -- Ancien : if ESX == nil or not PlayerData.accounts then
    if not HasLoaded then -- NOUVEAU : Vérifie HasLoaded au lieu de ESX ou PlayerData.accounts
        print('[ESX_BANK_ADVANCED] PlayerData non disponibles, impossible d\'ouvrir la NUI.')
        ESX.ShowNotification('Vos données ne sont pas encore chargées. Veuillez patienter.') -- Notification au joueur
        return
    end

    IsNuiOpen = true
    SetNuiFocus(true, true)

    ESX.TriggerServerCallback('esx_eaulmesse_banking:getAccountBalance', function(bankBalance)
        SendNuiMessage(json.encode({
            type        = "openBank",
            locationType= locationType,
            playerMoney = PlayerData.money,
            bankBalance = bankBalance,
            config      = Config.Locale
        }))
    end)
end

-- Et dans tes commandes de test (pour être encore plus sûr) :
RegisterCommand('testopenbank', function(source, args)
    if not HasLoaded then -- NOUVEAU : Vérifie HasLoaded
        ESX.ShowNotification('Vos données ne sont pas encore chargées. Veuillez patienter.')
        print('[BANK TEST] PlayerData non chargé, impossible d\'ouvrir la banque.')
        return
    end
    local type = args[1] or 'bank'
    OpenNUI(type)
    ESX.ShowNotification('Ouverture simulée de la banque (' .. type .. ')')
end, false)

-- Fonction pour fermer l'interface NUI.
function CloseNUI()
    IsNuiOpen = false
    SetNuiFocus(false, false) -- Rend le focus au jeu.
    -- Envoie un message à l'interface React pour la fermer.
    SendNuiMessage(json.encode({
        type = "closeBank"
    }))
end

--- GESTION DES TOUCHES ET INTERACTIONS EN JEU ---

-- Thread pour vérifier si le joueur est proche d'une banque/ATM et pour gérer l'ouverture/fermeture de la NUI.
Citizen.CreateThread(function()
    while true do
        -- RÉDUCTION DE LA FRÉQUENCE DE LA BOUCLE POUR LA PERFORMANCE
        Citizen.Wait(500) -- Attendre 500ms (0.5 seconde) pour ne pas saturer le CPU.

        if ESX == nil then Citizen.Wait(100); goto continue end -- S'assure qu'ESX est chargé

        local playerPed = PlayerPedId() -- Récupère le Ped du joueur.
        local playerCoords = GetEntityCoords(playerPed) -- Récupère les coordonnées du joueur.
        local inRangeOfATM = false
        local currentLocationType = nil -- Pour stocker si c'est une 'bank' ou un 'atm'

        -- Parcours TOUTES les locations définies dans Config.BankLocations (nouvelle structure)
        for i, v in ipairs(Config.BankLocations) do
            -- Utilisation de l'opérateur de soustraction vectorielle et de la longueur pour la distance
            local dist = #(playerCoords - v.coords)

            if dist < 2.0 then -- Si le joueur est à moins de 2 mètres de l'emplacement
                inRangeOfATM = true
                currentLocationType = v.type -- Récupère le type (bank ou atm)
                local promptText = (v.type == 'bank' and Config.Locale.OpenBankPrompt or Config.Locale.OpenAtmPrompt)
                ESX.ShowHelpNotification(promptText)

                -- Si la touche configurée (par défaut 'E', code 38) est pressée et que l'interface n'est pas ouverte.
                -- Utilise Config.OpenBankKey si tu l'as définie dans ton config.lua
                if IsControlJustReleased(0, 38) and not IsNuiOpen then -- 38 est la touche 'E'
                    OpenNUI(currentLocationType) -- Ouvre l'interface bancaire, en passant le type
                end
                break -- On a trouvé l'ATM le plus proche, pas besoin de vérifier les autres pour le prompt
            end
        end

        -- Si la NUI est ouverte et que la touche d'échappement (INPUT_FRONTEND_CANCEL = 177) est pressée.
        if IsNuiOpen and IsControlJustReleased(0, 177) then -- 177 est le code pour ESC
            CloseNUI() -- Ferme l'interface.
        end

        ::continue:: -- Étiquette pour le goto, si utilisé.
    end
end)


--- GESTION DES MESSAGES NUI ---

-- Ce handler reçoit les messages envoyés depuis ton interface React (NUI).
-- NOM DE L'ÉVÉNEMENT CORRIGÉ POUR CORRESPONDRE À LA RESSOURCE (si esx_bank_advanced)
RegisterNetEvent('__cfx_nui:esx_eaulmesse_banking:nui_callback')
AddEventHandler('__cfx_nui:esx_eaulmesse_banking:nui_callback', function(data, cb) -- Ajout de 'cb' pour les réponses aux fetch de la NUI
    local action = data.action
    local amount = tonumber(data.amount) -- Toujours convertir les montants en nombres
    local targetId = tonumber(data.targetId) -- Toujours convertir les IDs en nombres

    if action == 'deposit' then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:depositMoney', function(success, message)
            -- Envoie la réponse directement à la NUI via la callback 'cb'
            cb({ success = success, message = message })
            if success then
                ESX.ShowNotification(message)
            else
                ESX.ShowNotification(message)
            end
            -- Optionnel: Rafraîchir le solde après l'opération (si non géré par esx:setAccountMoney/setMoney)
            -- Dans ton cas, ces événements ESX devraient suffire à mettre à jour PlayerData.
            -- La NUI peut ensuite demander le solde ou le mettre à jour via d'autres messages.
        end, amount)

    elseif action == 'withdraw' then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:withdrawMoney', function(success, message)
            cb({ success = success, message = message })
            if success then
                ESX.ShowNotification(message)
            else
                ESX.ShowNotification(message)
            end
        end, amount)

    elseif action == 'transfer' then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:transferMoney', function(success, message)
            cb({ success = success, message = message })
            if success then
                ESX.ShowNotification(message)
            else
                ESX.ShowNotification(message)
            end
        end, targetId, amount)

    elseif action == 'getHistory' then -- Ajout d'une action pour l'historique
        ESX.TriggerServerCallback('esx_eaulmesse_banking:getTransactionHistory', function(history)
            cb({ history = history }) -- Renvoie l'historique à la NUI
        end)

    elseif action == 'close' then
        CloseNUI() -- Ferme l'interface si l'action 'close' est reçue de la NUI.
        cb(true) -- Confirme la fermeture à la NUI
    end
end)


--- COMMANDES DE TEST TEMPORAIRES (À RETIRER EN PRODUCTION) ---

-- Commande pour simuler l'ouverture de la banque (équivalent à appuyer sur E)
RegisterCommand('testopenbank', function(source, args)
    local type = args[1] or 'bank' -- Permet de spécifier 'bank' ou 'atm', par défaut 'bank'
    OpenNUI(type) -- Appelle directement ta fonction OpenNUI
    ESX.ShowNotification('Ouverture simulée de la banque (' .. type .. ')')
end, false) -- 'false' rend la commande accessible à tous les joueurs

-- Commande pour simuler la fermeture de la banque (équivalent à appuyer sur ESC)
RegisterCommand('testclosebank', function(source, args)
    CloseNUI() -- Appelle directement ta fonction CloseNUI
    ESX.ShowNotification('Fermeture simulée de la banque')
end, false)

-- Commande pour simuler un dépôt sans NUI
RegisterCommand('testdeposit', function(source, args)
    if ESX == nil then print('[BANK TEST] ESX non chargé.'); return end
    local amount = tonumber(args[1])
    if amount and amount > 0 then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:depositMoney', function(success, message)
            if success then
                print(('[BANK TEST] Dépôt réussi : %s'):format(message))
                ESX.ShowNotification(message)
                -- Pas besoin de SendNuiMessage ici car c'est un test sans NUI
            else
                print(('[BANK TEST] Erreur dépôt : %s'):format(message))
                ESX.ShowNotification(message)
            end
        end, amount)
    else
        print('[BANK TEST] Utilisation: /testdeposit <montant_positif>')
        ESX.ShowNotification('[BANK TEST] Montant de dépôt invalide.')
    end
end, false)

-- Commande pour simuler un retrait sans NUI
RegisterCommand('testwithdraw', function(source, args)
    if ESX == nil then print('[BANK TEST] ESX non chargé.'); return end
    local amount = tonumber(args[1])
    if amount and amount > 0 then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:withdrawMoney', function(success, message)
            if success then
                print(('[BANK TEST] Retrait réussi : %s'):format(message))
                ESX.ShowNotification(message)
            else
                print(('[BANK TEST] Erreur retrait : %s'):format(message))
                ESX.ShowNotification(message)
            end
        end, amount)
    else
        print('[BANK TEST] Utilisation: /testwithdraw <montant_positif>')
        ESX.ShowNotification('[BANK TEST] Montant de retrait invalide.')
    end
end, false)

-- Commande pour simuler un transfert sans NUI
RegisterCommand('testtransfer', function(source, args)
    if ESX == nil then print('[BANK TEST] ESX non chargé.'); return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    if targetId and amount and amount > 0 then
        ESX.TriggerServerCallback('esx_eaulmesse_banking:transferMoney', function(success, message)
            if success then
                print(('[BANK TEST] Transfert réussi : %s'):format(message))
                ESX.ShowNotification(message)
            else
                print(('[BANK TEST] Erreur transfert : %s'):format(message))
                ESX.ShowNotification(message)
            end
        end, targetId, amount)
    else
        print('[BANK TEST] Utilisation: /testtransfer <ID_Joueur_Cible> <montant_positif>')
        ESX.ShowNotification('[BANK TEST] Paramètres de transfert invalides.')
    end
end, false)

-- Commande pour simuler la demande d'historique (le résultat sera dans la console F8)
RegisterCommand('testhistory', function(source, args)
    if ESX == nil then print('[BANK TEST] ESX non chargé.'); return end
    ESX.TriggerServerCallback('esx_eaulmesse_banking:getTransactionHistory', function(history)
        print('[BANK TEST] Historique des transactions reçu:')
        if history and #history > 0 then
            for i, transaction in ipairs(history) do
                print(('[BANK TEST] Transaction %s: Type: %s, Montant: %s, Date: %s, Description: %s'):format(
                    transaction.id, transaction.type, transaction.amount, transaction.date, transaction.description))
            end
        else
            print('[BANK TEST] Aucun historique disponible.')
        end
    end)
end, false)