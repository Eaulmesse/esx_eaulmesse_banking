-- server/main.lua

ESX = nil -- Initialise la variable ESX à nil. Elle sera remplie par le framework.

-- Événement déclenché lorsque la ressource ESX est chargée et prête à être utilisée.
-- Permet de récupérer l'instance d'ESX.
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- [[ FONCTIONS UTILITAIRES ESX ]] --

-- Fonction pour obtenir le solde bancaire d'un joueur.
-- ESX Legacy gère le solde bancaire dans la table 'accounts' de la base de données, type 'bank'.
function GetPlayerBankBalance(source)
    local xPlayer = ESX.GetPlayerFromId(source) -- Récupère l'objet joueur ESX à partir de son ID.

    if xPlayer then
        -- ESX.GetAccount est la fonction pour récupérer un compte spécifique d'un joueur.
        -- 'bank' est le type de compte bancaire par défaut.
        local bankAccount = xPlayer.getAccount('bank')
        if bankAccount then
            return bankAccount.money -- Retourne le solde actuel du compte bancaire.
        end
    end
    return 0 -- Retourne 0 si le joueur ou le compte bancaire n'est pas trouvé.
end

-- Fonction pour déposer de l'argent.
-- L'argent est retiré du 'money' (argent liquide) et ajouté au 'bank' (compte bancaire).
ESX.RegisterServerCallback('esx_eaulmesse_banking:depositMoney', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source) -- Récupère l'objet joueur.
    local playerMoney = xPlayer.getMoney()      -- Récupère l'argent liquide du joueur.

    -- Validation : S'assurer que le montant est valide et que le joueur a assez d'argent liquide.
    if amount <= 0 or amount > Config.MaxDepositAmount or playerMoney < amount then
        cb(false) -- Rappelle la fonction de callback avec 'false' pour indiquer l'échec.
        Config.ShowNotification(source, 'Montant de dépôt invalide ou fonds insuffisants.')
        return
    end

    -- Ajoute l'argent au compte bancaire et retire l'argent liquide.
    xPlayer.addAccountMoney('bank', amount)
    xPlayer.removeMoney(amount)

    -- TODO: Enregistrer la transaction dans un système d'historique (plus tard).
    Config.ShowNotification(source, 'Vous avez déposé ~g~$' .. amount .. '~s~.')
    cb(true) -- Rappelle la fonction de callback avec 'true' pour indiquer le succès.
end)

-- Fonction pour retirer de l'argent.
-- L'argent est retiré du 'bank' (compte bancaire) et ajouté au 'money' (argent liquide).
ESX.RegisterServerCallback('esx_eaulmesse_banking:withdrawMoney', function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)       -- Récupère l'objet joueur.
    local bankBalance = xPlayer.getAccount('bank').money -- Récupère le solde bancaire.

    -- Validation : S'assurer que le montant est valide et que le joueur a assez d'argent à la banque.
    if amount <= 0 or amount > Config.MaxWithdrawAmount or bankBalance < amount then
        cb(false) -- Rappelle la fonction de callback avec 'false' pour indiquer l'échec.
        Config.ShowNotification(source, 'Montant de retrait invalide ou fonds insuffisants à la banque.')
        return
    end

    -- Retire l'argent du compte bancaire et ajoute l'argent liquide.
    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)

    -- TODO: Enregistrer la transaction dans un système d'historique (plus tard).
    Config.ShowNotification(source, 'Vous avez retiré ~r~$' .. amount .. '~s~.')
    cb(true) -- Rappelle la fonction de callback avec 'true' pour indiquer le succès.
end)

-- Fonction pour transférer de l'argent à un autre joueur.
ESX.RegisterServerCallback('esx_eaulmesse_banking', function(source, cb, targetId, amount)
    local xPlayer = ESX.GetPlayerFromId(source)         -- Joueur qui envoie l'argent.
    local xTarget = ESX.GetPlayerFromId(targetId)       -- Joueur qui reçoit l'argent.
    local bankBalance = xPlayer.getAccount('bank').money -- Solde de l'envoyeur.

    -- Validation : Vérifier si le destinataire existe et si le montant est valide.
    if not xTarget then
        cb(false)
        Config.ShowNotification(source, 'Le joueur destinataire n\'existe pas.')
        return
    end

    if amount <= 0 or bankBalance < amount then
        cb(false)
        Config.ShowNotification(source, 'Montant de transfert invalide ou fonds insuffisants.')
        return
    end

    -- Effectue le transfert
    xPlayer.removeAccountMoney('bank', amount)
    xTarget.addAccountMoney('bank', amount)

    -- Notifications aux deux joueurs.
    Config.ShowNotification(source, 'Vous avez transféré ~g~$' .. amount .. '~s~ à ' .. GetPlayerName(targetId) .. '.')
    Config.ShowNotification(targetId, 'Vous avez reçu ~g~$' .. amount .. '~s~ de ' .. GetPlayerName(source) .. '.')

    -- TODO: Enregistrer la transaction dans un système d'historique.
    cb(true)
end)

-- [[ EVENTS ]] --

-- Événement appelé par le client pour obtenir le solde bancaire actuel.
RegisterNetEvent('esx_eaulmesse_banking:getBankBalance')
AddEventHandler('esx_eaulmesse_banking:getBankBalance', function(cb)
    local _source = source
    local balance = GetPlayerBankBalance(_source)
    -- Le callback est utilisé pour renvoyer des données du serveur au client.
    cb(balance, ESX.GetPlayerFromId(_source).getMoney()) -- Renvoie solde bancaire et argent liquide.
end)

-- Événement déclenché lors de la première connexion d'un joueur.
-- Initialise le solde bancaire si le joueur n'en a pas.
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Vérifie si le compte bancaire est déjà initialisé.
    -- Par défaut, ESX crée un compte bancaire à 0, donc cela peut ne pas être strictement nécessaire
    -- si tu veux toujours commencer à 0. Cependant, si tu veux un solde initial spécifique, c'est ici.
    if xPlayer.getAccount('bank').money == 0 then
        xPlayer.addAccountMoney('bank', Config.DefaultBankBalance)
        Config.ShowNotification(playerId, 'Votre compte bancaire a été initialisé avec ~g~$' .. Config.DefaultBankBalance .. '~s~.')
    end
end)


-- Fonction utilitaire pour obtenir le nom d'un joueur (utile pour les notifications de transfert).
-- Ceci est un exemple simple, pour un système de vente tu voudrais quelque chose de plus robuste.
function GetPlayerName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.name then
        return xPlayer.name
    elseif xPlayer then
        -- Fallback si le nom n'est pas directement disponible (ex: Steam ID)
        return 'Joueur ID: ' .. source
    end
    return 'Inconnu'
end