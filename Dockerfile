FROM node:22-slim AS builder
WORKDIR /code

Instalar dependencias

COPY package.json package-lock.json ./
RUN npm ci

Copiar el código fuente

COPY . .

SOLUCIÓN CRÍTICA: Hack para inyectar rutas API antes de la compilación.

Se usa '&& ' para asegurar que todos los comandos se ejecuten como parte de una ÚNICA instrucción RUN.

RUN mkdir -p build/server/src/app/ && 

cp -r ./src/app/api ./build/server/src/app/ && 

echo "--- DIAGNÓSTICO DE RUTA API INYECTADA ---" && 

ls -l build/server/src/app/api && 

echo "--- Inicia la compilación react-router build ---\n" && 

npm run build

-----------------------------------------------------------------

ETAPA 2: PRODUCTION - Imagen final liviana

-----------------------------------------------------------------

FROM node:22-slim AS production
WORKDIR /code

Copiar solo las dependencias de producción de la etapa builder

COPY --from=builder /code/package.json ./
RUN npm install --omit=dev

Copiar los archivos de compilación desde la etapa builder

COPY --from=builder /code/dist ./dist

--- FIX: Copiar el script de inicio requerido por la plataforma ---

COPY start.sh /start.sh
RUN chmod +x /start.sh

-------------------------------------------------------------------

Exponer el puerto de Hono

EXPOSE 4000

El ENTRYPOINT apunta al script que acabamos de copiar.

ENTRYPOINT ["/start.sh"]
