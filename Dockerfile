FROM node:22-slim 
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# 1. Ejecutar la compilación.
# Esto genera la carpeta 'dist/' que contiene el servidor de producción (e.g., dist/server.js).
RUN npm run build 

EXPOSE 4000 
# NOTA: Tu vite.config.ts usa el puerto 4000 en la sección 'server.port'. Es más seguro usar este puerto aquí.

# 2. Comando de inicio: Ejecutar directamente el archivo de servidor compilado
# Reemplaza 'dist/server.js' por la ruta real si es diferente. 
# Si tu build crea el archivo de servidor en la raíz (ej: server.js), ajústalo.
CMD ["node", "dist/server.js"]
