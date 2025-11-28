FROM node:20-slim AS builder

WORKDIR /code

# Paso 1: Copiar archivos de definición de dependencias
COPY package.json package-lock.json ./

# Paso 2: Limpiar caché para prevenir errores internos (como "idealTree")
RUN npm cache clean --force

# Paso 3: Instalar todas las dependencias (incluyendo las de desarrollo para la compilación)
RUN npm ci

# Paso 4: Copiar código fuente
COPY . .

# Paso 5: Compilación del código
# Ejecutar 'npm run build' y realizar diagnósticos/ajustes de archivos.
RUN mkdir -p build/server/src/app/ && \
    cp -r ./src/app/api ./build/server/src/app/ && \
    echo "--- Inicia la compilación y diagnóstico de rutas ---" && \
    npm run build && \
    # Diagnóstico: Mostrar el contenido de la carpeta 'build' para ver dónde se generó server.js.
    echo "--- Contenido de la carpeta 'build' después de la compilación ---" && \
    ls -R build/ && \
    
    # **AJUSTE DE RUTA CRÍTICO:** # Mover el archivo de entrada del servidor (que el script 'start' espera en 'dist/server.js')
    # a la ubicación esperada. Se asume que se genera en 'build/server.js' o 'build/index.js'.
    
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
# Copiar 'dist' (que ahora debería contener server.js gracias al ajuste anterior)
COPY --from=builder /code/dist ./dist

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4000

CMD ["npm", "start"]
