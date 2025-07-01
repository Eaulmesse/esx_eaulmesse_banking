// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: './', // <--- TRÈS IMPORTANT : Rend les chemins relatifs
  build: {
    outDir: 'dist', // Le dossier de sortie de ton build
  }
})