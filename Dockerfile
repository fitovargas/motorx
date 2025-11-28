FROM node:22-slim AS builder

WORKDIR /code

# Copiar archivos de dependencias primero (mejor cache)
COPY package*.json ./
RUN npm ci

# Copiar código y build
COPY . .
RUN npm run build

# Verificar y preparar archivos del servidor (flexible para diferentes frameworks)
RUN if [ -f build/server/index.js ]; then \
      mkdir -p dist && cp build/server/index.js dist/server.js; \
    elif [ -f .next/standalone/server.js ]; then \
      mkdir -p .next/standalone && cp .next/standalone/server.js dist/server.js; \
    elif [ -f dist/server.js ]; then \
      mkdir -p dist && cp dist/server.js dist/server.js; \
    else \
      echo "ERROR: No se encontró server.js en rutas esperadas" && exit 1; \
    fi

FROM node:22-slim AS production

WORKDIR /code

# Solo dependencias de producción (sin duplicar instalación)
COPY --from=builder /code/package*.json ./
RUN npm ci --omit=dev

# Copiar artifacts optimizados
COPY --from=builder /code/dist ./dist
COPY --from=builder /code/start.sh ./start.sh
RUN chmod +x start.sh

# Verificación mínima en producción
RUN test -f dist/server.js || (echo "FALLO: dist/server.js no existe" && exit 1)

EXPOSE 4000
CMD ["npm", "start"]
