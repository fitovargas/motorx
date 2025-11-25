FROM node:22-slim AS builder
WORKDIR /code

# Instalar dependencias
COPY package.json package-lock.json ./
RUN npm ci

# Copiar el código fuente
COPY . .

# SOLUCIÓN CRÍTICA para el error 'ENOENT: no such file or directory, scandir .../build/server/src/app/api'
# El compilador de react-router-hono-server busca los archivos fuente 'src' dentro del directorio
# de salida del SSR ('build/server'). Debemos forzar esta estructura de directorio antes de la compilación.

# 1. Asegurar que el directorio de salida del SSR exista
RUN mkdir -p build/server

# 2. Copiar el código fuente ('src') dentro del directorio de salida del SSR ('build/server')
# Esto permite que el escaneo de rutas (scandir) tenga éxito en la ubicación incorrecta que está buscando.
RUN cp -r ./src ./build/server/

# 3. Compilar la aplicación (genera build/client y actualiza build/server)
RUN npm run build


# -----------------------------------------------------------------
# ETAPA 2: PRODUCTION - Imagen final liviana
# -----------------------------------------------------------------
FROM node:22-slim AS production
WORKDIR /code

# Copiar solo las dependencias de producción de la etapa builder
COPY --from=builder /code/package.json ./
# Usamos 'npm install' en lugar de 'npm ci' para solo obtener dependencias de producción.
RUN npm install --omit=dev

# Copiar los resultados de la compilación (build/ y dist/)
COPY --from=builder /code/build ./build
COPY --from=builder /code/dist ./dist

EXPOSE 4000 

# Comando de inicio
CMD ["npm", "start"]
# Comando de inicio
CMD ["npm", "start"]
