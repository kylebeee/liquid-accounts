import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { nodePolyfills } from 'vite-plugin-node-polyfills'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), nodePolyfills({ include: ['buffer'], globals: { process: false } })],
  resolve: {
    dedupe: ['react', 'react-dom', '@txnlab/use-wallet-react'],
  },
})
