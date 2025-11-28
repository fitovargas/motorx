FROM node:20-slim AS builder

WORKDIR /code

# Paso 1: Copiar archivos de definición de dependencias
COPY package.json package-lock.json ./

# Paso 1.5: Muestra los scripts del package.json para verificar el comando 'build'
RUN echo "--- Contenido del package.json para verificar scripts ---" && cat package.json

# Paso 2: Limpiar caché para prevenir errores internos
RUN npm cache clean --force

# Paso 3: Instalar todas las dependencias
RUN npm ci

# Paso 4: Copiar código fuente
COPY . .

# Paso 5: Compilación del código
RUN mkdir -p build/server/src/app/ && \
    cp -r ./src/app/api ./build/server/src/app/ && \
    echo "--- Inicia la compilación react-router build ---" && \
    npm run build && \
    
    # Diagnóstico: Mostrar el contenido de la carpeta 'build' para ver dónde se generó server.js.
    echo "--- Contenido de la carpeta 'build' después de la compilación ---" && \
    ls -R build/ && \
    
    # **AJUSTE DE RUTA CRÍTICO:** Mover el archivo de entrada del servidor (que 'npm start' espera en 'dist/server.js')
    
    mkdir -p dist && \
    SERVER_FILE_PATH="" && \
    if [ -f build/server/server.js ]; then SERVER_FILE_PATH="build/server/server.js"; \
    elif [ -f build/server.js ]; then SERVER_FILE_PATH="build/server.js"; \
    elif [ -f build/index.js ]; then SERVER_FILE_PATH="build/index.js"; \
    elif [ -f build/server/index.js ]; then SERVER_FILE_PATH="build/server/index.js"; \
    fi && \
    
    if [ -n "$SERVER_FILE_PATH" ]; then \
        echo "ÉXITO: Se encontró el archivo del servidor en $SERVER_FILE_PATH"; \
        cp $SERVER_FILE_PATH dist/server.js; \
    else \
        echo "ADVERTENCIA: No se encontró el archivo de servidor en ninguna ruta esperada. EL DESPLIEGUE FALLARÁ."; \
    fi

FROM node:20-slim AS production

WORKDIR /code

# Paso 6: Copiar solo los archivos necesarios para producción
COPY --from=builder /code/package.json ./
RUN npm install --omit=dev

COPY --from=builder /code/build ./build
# **AJUSTE CLAVE:** Copiar la carpeta 'dist' que ahora debería contener server.js
COPY --from=builder /code/dist ./dist

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4000

# El comando de inicio principal (CMD) vuelve a ser el original, que busca en 'dist/server.js'.
CMD ["npm", "start"]
