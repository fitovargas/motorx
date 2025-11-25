import type { Config } from '@react-router/dev/config';
import path from 'node:path';

// Esta configuración se actualiza para usar una ruta absoluta para appDirectory.
// En el entorno Docker, el directorio de trabajo es /code (process.cwd()).
// Usar una ruta absoluta evita el problema donde la herramienta de compilación
// resuelve incorrectamente la ruta relativa './src/app' contra el directorio de salida SSR.
export default {
    // Resolve appDirectory absolutamente desde el working directory /code
    appDirectory: path.resolve(process.cwd(), 'src/app'),
    ssr: true,
    prerender: ['/*?'],
} satisfies Config;
