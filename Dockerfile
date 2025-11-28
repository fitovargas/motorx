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
    
    # **AJUSTE DE RUTA CRÍTICO (Restaurado y Simplificado):** # Mover el archivo de entrada del servidor (que 'npm start' espera en 'dist/server.js')
    # a la ubicación 'dist' si se encuentra en la raíz de 'build'.
    
    mkdir -p dist && \
    if [ -f build/server.js ]; then \
        echo "Copiando build/server.js a dist/server.js..."; \
        cp build/server.js dist/server.js; \
    elif [ -f build/index.js ]; then \
        echo "Copiando build/index.js a dist/server.js..."; \
        cp build/index.js dist/server.js; \
    else \
        echo "ADVERTENCIA: No se encontró server.js ni index.js en la raíz de 'build'. El despliegue fallará."; \
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
