FROM node:22-slim AS builder
WORKDIR /code

# Instalar dependencias
COPY package.json package-lock.json ./
RUN npm ci

# Copiar el código fuente
COPY . .

# SOLUCIÓN CRÍTICA para el error 'ENOENT: no such file or directory, scandir .../build/server/src/app/api'
# El compilador de react-router-hono-server busca los archivos fuente 'src' dentro del directorio
# de salida del SSR ('build/server').

# 1. Ejecutar la compilación y los hacks en una sola instrucción para evitar que
#    el build limpie y elimine el enlace simbólico necesario.
#    Secuencia: mkdir -> ln -s (crea symlink) -> npm run build
RUN mkdir -p build/server && \
    ln -s /code/src /code/build/server/src && \
    echo "--- DIAGNÓSTICO (Pre-Build) ---" && \
    ls -l build/server && \
    echo "--- Inicia la compilación react-router build ---" && \
    npm run build

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
