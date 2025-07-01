fx_version 'cerulean'
game 'gta5'

author 'Eaulmesse'
description 'Un script bancaire complet pour ESX Legacy'
version '1.0.0'

dependencies {
    'es_extended'
}

client_scripts {
    '@es_extended/locale.lua',
    'config.lua',
    'client/main.lua'
}

server_scripts {
    '@es_extended/locale.lua',
    'config.lua',
    'server/main.lua'
}

-- Fichiers pour l'interface utilisateur (NUI)
-- Les fichiers listés ici seront disponibles pour l'interface web.

-- Le point d'entrée de ton interface NUI est l'index.html généré par Vite
-- Il est généralement situé dans le dossier 'dist' après la compilation.
ui_page 'nui/dist/index.html'

files {
    'nui/dist/index.html',         -- Ton fichier HTML principal généré par Vite
    'nui/dist/assets/*',           -- **TRÈS IMPORTANT : Inclure tous les assets générés (JS, CSS, images, etc.)**
                                   -- Le '*' est un wildcard qui inclura tous les fichiers et sous-dossiers
                                   -- à l'intérieur du dossier 'assets'.
}

-- locales {
--     'en',
--     'fr'
-- }
-- data 'locale_dictionary' 'locales/en.json'
-- data 'locale_dictionary' 'locales/fr.json'