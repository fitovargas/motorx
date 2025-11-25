FROM node:22-slim 
WORKDIR /
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build 
RUN cp -r ./src/app/api ./build/server/src/app/ || true
EXPOSE 4000 
CMD ["npm", "start"]
