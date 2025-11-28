FROM node:20-slim AS builder

WORKDIR /code

# Paso 1: Copiar archivos de definición de dependencias
COPY package.json package-lock.json ./

# Paso 2 (NUEVO): Limpiar caché para prevenir "idealTree" y otros errores de caché
# Esto asegura un estado limpio antes de la instalación.
RUN npm cache clean --force

# Paso 3: Instalar todas las dependencias (incluyendo las de desarrollo para la compilación)
RUN npm ci

# Paso 4: Copiar código fuente
COPY . .

# Paso 5: Compilación del código
RUN mkdir -p build/server/src/app/ && \
    cp -r ./src/app/api ./build/server/src/app/ && \
    echo "--- Inicia la compilación react-router build ---" && \
    npm run build

FROM node:20-slim AS production

WORKDIR /code

# Paso 6: Copiar solo los archivos necesarios para producción
COPY --from=builder /code/package.json ./
# Asegúrate de usar 'npm ci' si el 'package-lock.json' fue copiado y quieres ser estricto, 
# o 'npm install --omit=dev' para una instalación limpia de producción.
RUN npm install --omit=dev

COPY --from=builder /code/build ./build
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4000

# El comando de inicio principal (CMD) es correcto y llama a 'npm start'
CMD ["npm", "start"]
