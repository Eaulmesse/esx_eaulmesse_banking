-- fxmanifest.lua

fx_version 'cerulean' -- Version de l'API FiveM, 'cerulean' est la plus récente et recommandée
game 'gta5'          -- Le jeu pour lequel ce script est conçu

author 'Eaulmesse' -- Ton nom ou le nom de ta marque
description 'Un script bancaire complet pour ESX Legacy' -- Une brève description de ton script
version '1.0.0'      -- La version actuelle de ton script

-- Dépendances requises. 'es_extended' est nécessaire pour utiliser ESX Legacy.
-- Assure-toi que cette ressource est bien démarrée sur ton serveur.
dependencies {
    'es_extended'
}

-- Fichiers côté client
-- Ces scripts sont exécutés sur chaque client connecté au serveur.
client_scripts {
    '@es_extended/locale.lua', -- Inclut le fichier de locale d'ESX pour les traductions
    'config.lua',              -- Charge le fichier de configuration côté client (pour les paramètres visuels, etc.)
    'client/main.lua'          -- Le script principal côté client
}

-- Fichiers côté serveur
-- Ces scripts sont exécutés une seule fois côté serveur.
server_scripts {
    '@es_extended/locale.lua', -- Inclut le fichier de locale d'ESX pour les traductions
    'config.lua',              -- Charge le fichier de configuration côté serveur (pour les paramètres de base de données, etc.)
    'server/main.lua'          -- Le script principal côté serveur
}

-- Fichiers pour l'interface utilisateur (NUI)
-- Les fichiers listés ici seront disponibles pour l'interface web.
ui_page 'nui/index.html' -- Le point d'entrée de ton interface NUI (ton fichier React)

files {
    'nui/index.html',    -- Le fichier HTML principal de ton interface
    'nui/script.js',     -- Ton fichier JavaScript (ton bundle React)
    'nui/style.css'      -- Ton fichier CSS
}

-- Ressource locale (pour les traductions si tu veux internationaliser ton script)
-- locales {
--     'en',
--     'fr'
-- }
-- data 'locale_dictionary' 'locales/en.json'
-- data 'locale_dictionary' 'locales/fr.json'