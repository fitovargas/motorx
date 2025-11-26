import path from 'node:path';
import { reactRouter } from '@react-router/dev/vite';
import { reactRouterHonoServer } from 'react-router-hono-server/dev';
import { defineConfig } from 'vite';
import babel from 'vite-plugin-babel';
// El import de tsconfigPaths se mantiene comentado, ya que lo eliminamos como parte del intento #3.
// import tsconfigPaths from 'vite-tsconfig-paths'; 
import { addRenderIds } from './plugins/addRenderIds';
import { aliases } from './plugins/aliases';
import consoleToParent from './plugins/console-to-parent';
import { layoutWrapperPlugin } from './plugins/layouts';
import { loadFontsFromTailwindSource } from './plugins/loadFontsFromTailwindSource';
import { nextPublicProcessEnv } from './plugins/nextPublicProcessEnv';
import { restart } from './plugins/restart';
import { restartEnvFileChange } from './plugins/restartEnvFileChange';

export default defineConfig({
  // Keep them available via import.meta.env.NEXT_PUBLIC_*
  envPrefix: 'NEXT_PUBLIC_',
  optimizeDeps: {
    // Explicitly include fast-glob, since it gets dynamically imported and we
    // don't want that to cause a re-bundle.
    include: ['fast-glob', 'lucide-react'],
    exclude: [
      '@hono/auth-js/react',
      '@hono/auth-js',
      '@auth/core',
      '@hono/auth-js',
      'hono/context-storage',
      '@auth/core/errors',
      // 'fsev...' // Asumimos que esta línea estaba incompleta en el snippet original
    ],
  },
  // --- AÑADIR CONFIGURACIÓN DE TARGET PARA TOP-LEVEL AWAIT ---
  build: {
    // Establecer el target a 'esnext' para permitir el 'top-level await'
    // en el bundle SSR, que es un error reportado por esbuild.
    target: 'esnext',
  },
  plugins: [
    nextPublicProcessEnv(),
    restartEnvFileChange(),
    reactRouterHonoServer({
      serverEntryPoint: './__create/index.ts',
      runtime: 'node',
      // SOLUCIÓN PARA DOCKER: Forzar la ruta absoluta del directorio fuente
      // Usamos path.resolve(process.cwd()) para asegurar que la ruta sea /code/src/app
      // dentro del contenedor Docker, sin depender de la resolución relativa de SSR.
      appDirectory: path.resolve(process.cwd(), 'src/app'),
    }),
    babel({
      include: ['src/**/*.{js,jsx,ts,tsx}'], // or RegExp: /src\\/.*\\.[tj]sx?$/
      exclude: /node_modules/, // skip everything else
      babelConfig: {
        babelrc: false, // don’t merge other Babel files
        configFile: false,
        plugins: ['styled-jsx/babel'],
      },
    }),
    restart({
      restart: [
        'src/**/page.jsx',
        'src/**/page.tsx',
        'src/**/layout.jsx',
        'src/**/layout.tsx',
        'src/**/route.js',
        'src/**/route.ts',
      ],
    }),
    consoleToParent(),
    loadFontsFromTailwindSource(),
    addRenderIds(),
    aliases(),
    reactRouter(),
    layoutWrapperPlugin(),
  ],
  resolve: {
    // Mantenemos la prioridad de extensiones.
    extensions: ['.jsx', '.tsx', '.mjs', '.js', '.ts', '.json'],
    alias: {
      lodash: 'lodash-es',
      'npm:stripe': 'stripe',
      stripe: path.resolve(__dirname, './src/__create/stripe'),
      '@auth/create/react': '@hono/auth-js/react',
      '@auth/create': path.resolve(__dirname, './src/__create/@auth/create'),
      // Alias estándar '@/' que apunta a 'src/app'.
      '@': path.resolve(__dirname, './src/app'),

      // OCTAVA CORRECCIÓN: Revierte a la extensión .js confirmada por el usuario.
      'src/app/utils/useUser': path.resolve(__dirname, './src/app/utils/useUser.js'),
      'src/app/utils/useAuth': path.resolve(__dirname, './src/app/utils/useAuth.js'),
    }
  }
});
