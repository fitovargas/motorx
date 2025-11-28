FROM node:22-slim AS builder

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
    
    # **AJUSTE DE RUTA CRÍTICO (Definitivo):**
    # Basado en el log (build/server/index.js), copiamos directamente a la ruta esperada por 'npm start' (dist/server.js).
    
    mkdir -p dist && \
    SERVER_SOURCE="build/server/index.js" && \
    SERVER_TARGET="dist/server.js" && \
    
    if [ -f "$SERVER_SOURCE" ]; then \
        echo "ÉXITO: Copiando $SERVER_SOURCE a $SERVER_TARGET..."; \
        cp $SERVER_SOURCE $SERVER_TARGET; \
        echo "Contenido de 'dist/' después de la copia:"; \
        ls dist/; \
    else \
        echo "ERROR CRÍTICO: El archivo del servidor '$SERVER_SOURCE' no fue encontrado. El despliegue fallará."; \
        exit 1; \
    fi

FROM node:22-slim AS production

WORKDIR /code

# Paso 6: Copiar solo los archivos necesarios para producción
COPY --from=builder /code/package.json ./
RUN npm install --omit=dev

COPY --from=builder /code/build ./build
# **AJUSTE CLAVE:** Copiar la carpeta 'dist' que ahora debería contener server.js
COPY --from=builder /code/dist ./dist

# **Diagnóstico en Etapa Production (Nuevo)**
RUN echo "--- Verificación de archivos en la imagen final ---" && \
    ls -l dist/ && \
    if [ -f dist/server.js ]; then \
        echo "VERIFICACIÓN ÉXITO: dist/server.js encontrado."; \
    else \
        echo "VERIFICACIÓN FALLO: dist/server.js NO encontrado."; \
        exit 1; \
    fi

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4000

# El comando de inicio principal (CMD) vuelve a ser el original, que busca en 'dist/server.js'.
CMD ["npm", "start"]
