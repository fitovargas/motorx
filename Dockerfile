FROM node:20-slim AS builder

WORKDIR /code

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN mkdir -p build/server/src/app/ && \
    cp -r ./src/app/api ./build/server/src/app/ && \
    echo "--- DIAGNÓSTICO DE RUTA API INYECTADA ---" && \
    ls -l build/server/src/app/api && \
    echo "--- Inicia la compilación react-router build ---" && \
    npm run build

FROM node:20-slim AS production

WORKDIR /code

COPY --from=builder /code/package.json ./
RUN npm install --omit=dev

COPY --from=builder /code/build ./build
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 4000

CMD ["npm", "start"]

