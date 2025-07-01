-- config.lua

Config = {}

-- [[ PARAMÈTRES BANCAIRES ]] --
Config.DefaultBankBalance = 1000
Config.MaxDepositAmount   = 1000000
Config.MaxWithdrawAmount  = 1000000

-- [[ POINTS D'INTERACTION (ATM / Guichet) ]] --
-- Ces coordonnées sont des exemples. Tu devras les ajuster pour ton serveur.
-- J'ai adapté la structure pour correspondre à celle que j'ai proposée (coords avec vector3 et type)
-- Cela rendra ton script plus flexible pour gérer banques ET ATMs avec le même système.
Config.BankLocations = {
    -- Banque principale de Legion Square
    { label = 'Banque Centrale', coords = vector3(149, -1040, 29), type = 'bank' },
    -- ATM à côté du magasin
    { label = 'ATM Paleto Bay', coords = vector3(-112.5, 6220.7, 30.5), type = 'atm' },
    { label = 'ATM LS Airport', coords = vector3(-131.06, -1498.41, 5.25), type = 'atm' }, -- Ton exemple d'ATM
    -- Tu peux ajouter d'autres emplacements ici
}

-- [[ NOTIFICATIONS / LOCALE ]] --
-- Retire la ligne 'Config.ShowNotification = ESX.ShowNotification'
-- La fonction de notification sera appelée directement depuis les scripts client/server
-- là où ESX est déjà chargé et disponible.
-- Ajoute les messages localisés si tu ne les avais pas déjà :
Config.Locale = {
    DepositSuccess   = 'Vous avez déposé %s $ sur votre compte en banque.',
    WithdrawSuccess  = 'Vous avez retiré %s $ de votre compte en banque.',
    TransferSuccess  = 'Vous avez transféré %s $ à %s.',

    NotEnoughMoneyWallet = 'Vous n\'avez pas assez d\'argent liquide sur vous.',
    NotEnoughMoneyBank   = 'Vous n\'avez pas assez d\'argent en banque.',
    InvalidAmount        = 'Montant invalide. Le montant doit être un nombre positif.',
    PlayerNotFound       = 'Le joueur avec cet identifiant n\'a pas été trouvé.',
    CannotTransferToSelf = 'Vous ne pouvez pas vous transférer de l\'argent à vous-même.',
    GenericError         = 'Une erreur est survenue. Veuillez réessayer.',

    OpenBankPrompt = '[E] Ouvrir la banque',
    OpenAtmPrompt  = '[E] Utiliser le distributeur',
}

-- [[ PARAMÈTRES NUI (Interface Utilisateur) ]] --
-- Ces paramètres sont utilisés par la NUI et le client Lua pour la communication.
Config.NUI = {
    OpenNUIEvent  = 'esx_eaulmesse_banking:openNUI',
    CloseNUIEvent = 'esx_eaulmesse_banking:closeNUI',
}

Config.OpenBankKey = 38 -- Si tu préfères une touche configurable, remets ça et utilise-le dans client/main.lua