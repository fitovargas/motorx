# --- ETAPA 1: DEPENDENCIAS (caché optimizado) ---
FROM node:22-slim AS deps
WORKDIR /code
COPY package*.json ./
RUN npm ci

# --- ETAPA 2: BUILDER (compilación) ---
FROM node:22-slim AS builder
WORKDIR /code
COPY --from=deps /code/node_modules ./node_modules
COPY --from=deps /code/package*.json ./
COPY . .
RUN npm run build

# --- ETAPA 3: PRODUCTION (imagen final ligera) ---
FROM node:22-slim AS production
WORKDIR /code

# Instalar SOLO producción (crítico para tamaño)
COPY package*.json ./
RUN npm ci --omit=dev

# Copiar build y preparar server.js flexiblemente
COPY --from=builder /code/build ./build
RUN mkdir -p dist && \
    if [ -f build/server/index.js ]; then \
      cp build/server/index.js dist/server.js; \
    elif [ -f .next/standalone/server.js ]; then \
      cp .next/standalone/server.js dist/server.js; \
    elif [ -f dist/server.js ]; then \
      true; \
    else \
      echo "ERROR: server.js no encontrado" && ls -la build/ || exit 1; \
    fi && \
    test -f dist/server.js

# start.sh si existe
COPY start.sh* ./
RUN chmod +x start.sh || true

EXPOSE 4000
CMD ["npm", "start"]
