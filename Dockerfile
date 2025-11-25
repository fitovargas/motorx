FROM node:22-slim 
# 1. Usar la ruta confirmada como Working Directory
WORKDIR /code 

COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# 2. Ejecutar la compilación (Crea la carpeta 'dist/' y el archivo 'dist/server.js')
RUN npm run build 

EXPOSE 4000 

# 3. Comando de inicio: Ejecutar el script 'start' actualizado
# Esto ejecutará: node dist/server.js
CMD ["npm", "start"]
