-- config.lua

Config = {}

-- [[ PARAMÈTRES BANCAIRES ]] --
Config.DefaultBankBalance = 1000 -- Solde initial que les nouveaux joueurs reçoivent à la banque.
Config.MaxDepositAmount   = 1000000 -- Montant maximal qu'un joueur peut déposer en une seule transaction.
Config.MaxWithdrawAmount  = 1000000 -- Montant maximal qu'un joueur peut retirer en une seule transaction.

-- [[ POINTS D'INTERACTION (ATM / Guichet) ]] --
-- Ces coordonnées sont des exemples. Tu devras les ajuster pour ton serveur.
-- Tu peux utiliser des outils in-game pour trouver les coordonnées exactes (ex: /coords).
Config.ATMLocations = {
    { x = 247.91, y = 221.05, z = 106.28 }, -- Exemple de localisation d'un ATM
    { x = -131.06, y = -1498.41, z = 5.25 } -- Autre exemple
}

-- [[ NOTIFICATIONS ]] --
-- Type de notification à utiliser. ESX utilise souvent 'ESX.ShowNotification'.
-- Tu peux le remplacer par ta propre fonction de notification si tu en as une.
Config.ShowNotification = ESX.ShowNotification

-- [[ PARAMÈTRES NUI (Interface Utilisateur) ]] --
Config.OpenBankKey = 38 -- Touche par défaut pour ouvrir l'interface bancaire (par exemple, 38 = E)
                        -- Liste des codes de touches : https://docs.fivem.net/docs/game-references/controls/