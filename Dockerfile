FROM node:22-slim 
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# 1. Ejecutar la compilación (Crea la carpeta 'dist/' y el archivo 'dist/server.js')
RUN npm run build 

EXPOSE 4000 
# Usamos el puerto 4000 definido en tu vite.config.ts

# 2. Comando de inicio: Ejecutar el script 'start' actualizado
CMD ["npm", "start"]
