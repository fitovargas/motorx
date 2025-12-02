import type { Config } from '@react-router/dev/config';

export default {
  appDirectory: './src/app',
  ssr: true,
  // Opción 1: Prerender solo rutas principales
  prerender: ['/', '/about', '/contact'],
  
  // Opción 2: Desactiva para desarrollo rápido
  // prerender: false,
  
  // Opción 3: Prerender todo (cuidado en prod)
  // prerender: true,
} satisfies Config;
