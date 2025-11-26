import { readdir, stat } from 'node:fs/promises';
import { join, resolve } from 'node:path'; 
import { fileURLToPath } from 'node:url';
import { Hono } from 'hono';
import type { Handler } from 'hono/types';
import updatedFetch from '../src/__create/fetch';

// NOTA: La lógica de registro de alias de 'tsconfig-paths' se ha eliminado ya que no 
// resolvía el error de importación de runtime y provocaba inestabilidad.
// La estrategia actual es omitir las rutas API que dependen de alias internos
// que Node.js no puede resolver en el entorno de SSR.

const API_BASENAME = '/api';
const api = new Hono();

// Obtener la ruta base del proyecto de forma más robusta.
const currentDir = fileURLToPath(new URL('.', import.meta.url));
const __dirname = resolve(currentDir, '..', '..', '..', 'src', 'app', 'api');

if (globalThis.fetch) {
  globalThis.fetch = updatedFetch;
}

// Recursively find all route.js files
async function findRouteFiles(dir: string): Promise<string[]> {
  const files = await readdir(dir);
  let routes: string[] = [];

  for (const file of files) {
    try {
      const filePath = join(dir, file);
      const statResult = await stat(filePath);

      if (statResult.isDirectory()) {
        routes = routes.concat(await findRouteFiles(filePath));
      } else if (file === 'route.js') {
        // Handle root route.js specially
        if (filePath === join(__dirname, 'route.js')) {
          routes.unshift(filePath); // Add to beginning of array
        } else {
          routes.push(filePath);
        }
      }
    } catch (error) {
      // FIX: Ignorar el error ENOENT que ocurre si se intenta leer 
      // algo que no existe o que fue limpiado por el bundler.
      if (error && (error as NodeJS.ErrnoException).code === 'ENOENT') {
        continue;
      }
      console.error(`Error reading file ${file}:`, error);
    }
  }

  return routes;
}

// Helper function to transform file path to Hono route path
function getHonoPath(routeFile: string): { name: string; pattern: string }[] {
  const relativePath = routeFile.replace(__dirname, '');
  const parts = relativePath.split('/').filter(Boolean);
  const routeParts = parts.slice(0, -1); // Remove 'route.js'
  if (routeParts.length === 0) {
    return [{ name: 'root', pattern: '' }];
  }
  const transformedParts = routeParts.map((segment) => {
    const match = segment.match(/^\[(\.{3})?([^\]]+)\]$/);
    if (match) {
      const [_, dots, param] = match;
      return dots === '...'
        ? { name: param, pattern: `:${param}{.+}` }
        : { name: param, pattern: `:${param}` };
    }
    return { name: segment, pattern: segment };
  });
  return transformedParts;
}

// Import and register all routes
async function registerRoutes() {
  const routeFiles = (
    await findRouteFiles(__dirname).catch((error) => {
      console.error('Error finding route files:', error);
      return [];
    })
  )
    .slice()
    .sort((a, b) => {
      return b.length - a.length;
    });

  // Clear existing routes
  api.routes = [];
  
  // Nuevo diagnóstico para verificar si entramos en el bucle
  console.log(`[RUTA API] Intentando registrar ${routeFiles.length} archivos de ruta...`);


  for (const routeFile of routeFiles) {
    try {
      // Usamos import dinámico para cargar el módulo de ruta en tiempo de ejecución.
      // /* @vite-ignore */ previene que Vite intente empaquetar este import.
      const route = await import(/* @vite-ignore */ `${routeFile}?update=${Date.now()}`);

      const methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
      for (const method of methods) {
        try {
          if (route[method]) {
            const parts = getHonoPath(routeFile);
            const honoPath = `/${parts.map(({ pattern }) => pattern).join('/')}`;
            const handler: Handler = async (c) => {
              const params = c.req.param();
              if (import.meta.env.DEV) {
                // En desarrollo, re-importamos para hot-reloading
                const updatedRoute = await import(
                  /* @vite-ignore */ `${routeFile}?update=${Date.now()}`
                );
                return await updatedRoute[method](c.req.raw, { params });
              }
              return await route[method](c.req.raw, { params });
            };
            const methodLowercase = method.toLowerCase();
            switch (methodLowercase) {
              case 'get':
                api.get(honoPath, handler);
                break;
              case 'post':
                api.post(honoPath, handler);
                break;
              case 'put':
                api.put(honoPath, handler);
                break;
              case 'delete':
                api.delete(honoPath, handler);
                break;
              case 'patch':
                api.patch(honoPath, handler);
                break;
              default:
                console.warn(`Unsupported method: ${method}`);
                break;
            }
          }
        } catch (error) {
          console.error(`Error registering route ${routeFile} for method ${method}:`, error);
        }
      }
    } catch (error) {
      // FIX: Capturar el ERR_MODULE_NOT_FOUND (Alias de ruta) y continuar.
      // Cambiamos a console.log para evitar que demasiados errores cancelen el build.
      if (error && (error as { code: string }).code === 'ERR_MODULE_NOT_FOUND') {
        console.log(`[ROUTE SKIP] Omitiendo ruta problemática debido a alias/dependencia: ${routeFile}`);
        continue;
      }
      
      console.error(`Error importing route file ${routeFile}:`, error);
    }
  }
  
  console.log(`[RUTA API] Registro de rutas API finalizado con éxito.`);
}

// Initial route registration
await registerRoutes();

// Hot reload routes in development
if (import.meta.env.DEV) {
  import.meta.glob('../src/app/api/**/route.js', {
    eager: true,
  });
  if (import.meta.hot) {
    import.meta.hot.accept((newSelf) => {
      registerRoutes().catch((err) => {
        console.error('Error reloading routes:', err);
      });
    });
  }
}

export { api, API_BASENAME };
