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

# 1. Ejecutar la compilación y el hack de copia TARGETED en una sola instrucción para asegurar
#    que la ruta '/code/build/server/src/app/api' exista justo antes de que el escaneo comience.
#    Secuencia: mkdir -p (asegura la ruta base) -> cp -r (copia el contenido API) -> npm run build
RUN mkdir -p build/server/src/app/ && \
    cp -r ./src/app/api ./build/server/src/app/ && \
    echo "--- DIAGNÓSTICO DE RUTA API INYECTADA ---" && \
    ls -l build/server/src/app/api && \
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

# Copiar los resultados de la compilación (build/client y build/server)
COPY --from=builder /code/build ./build
# Eliminamos la copia de 'dist' ya que la salida principal parece estar en 'build'.

EXPOSE 4000 

# Comando de inicio
CMD ["npm", "start"]
