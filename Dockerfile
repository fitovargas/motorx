FROM node:22-slim AS builder
WORKDIR /code
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN mkdir -p build/server/src/app/ && 

cp -r ./src/app/api ./build/server/src/app/ && 

echo "--- DIAGNÓSTICO DE RUTA API INYECTADA ---" && 

ls -l build/server/src/app/api && 

echo "--- Inicia la compilación react-router build ---\n" && 

npm run build

FROM node:22-slim AS production
WORKDIR /code
COPY --from=builder /code/package.json ./
RUN npm install --omit=dev
COPY --from=builder /code/dist ./dist
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 4000
ENTRYPOINT ["/start.sh"]
