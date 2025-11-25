FROM node:22-slim 
# Usamos /code como Working Directory para consistencia
WORKDIR /code 

COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# 2. Ejecutar la compilación (Crea las carpetas 'build/client' y 'build/server')
RUN npm run build 

# 3. FIX CRÍTICO: Copia la carpeta de código fuente 'src' dentro del bundle SSR 'build/server'.
# El error original era: 'ENOENT: no such file or directory, scandir '/code/build/server/src/app/api'
# Esto asegura que el router pueda escanear la estructura de archivos que necesita durante el arranque.
RUN cp -r ./src ./build/server/ || true

EXPOSE 4000 

# 4. Comando de inicio
CMD ["npm", "start"]
