# -----------------------------------------------------------------
# ETAPA 1: BUILDER - Para compilar la aplicación
# -----------------------------------------------------------------
FROM node:22-slim AS builder
WORKDIR /code

# Instalar dependencias
COPY package.json package-lock.json ./
RUN npm ci

# Copiar el código fuente
COPY . .



# Compilar la aplicación (genera build/client y build/server)
# Esto debería pasar ahora que 'src' está en build/server
RUN npm run build


# -----------------------------------------------------------------
# ETAPA 2: PRODUCTION - Imagen final liviana
# -----------------------------------------------------------------
FROM node:22-slim AS production
WORKDIR /code

# Copiar solo las dependencias de producción de la etapa builder
COPY --from=builder /code/package.json ./
RUN npm ci --omit=dev

# Copiar los resultados de la compilación
COPY --from=builder /code/build ./build
COPY --from=builder /code/dist ./dist

EXPOSE 4000 

# Comando de inicio
CMD ["npm", "start"]
