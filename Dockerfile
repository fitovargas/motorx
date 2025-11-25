FROM node:22-slim 
WORKDIR /code 

COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# FIX ROBUSTO para ENOENT: El router busca archivos fuente dentro del directorio de salida del SSR (`build/server/`).
# Haremos la preparación necesaria *antes* de la compilación para garantizar que el escaneo de rutas tenga éxito en el primer intento.

# 1. Crear explícitamente el directorio de destino final del SSR para garantizar que exista.
RUN mkdir -p build/server

# 2. Copia la carpeta de código fuente 'src' dentro del directorio de salida del SSR.
# Esto pre-coloca los archivos en la ubicación que el router buscará durante la compilación.
RUN cp -r ./src ./build/server/

# DEBUG: Mostrar que el directorio src/app/api existe justo antes de la compilación
# Si esta prueba falla, sabremos que el directorio src/app/api no está en el .tar o el .zip de origen.
# Si esta prueba tiene éxito y el paso 3 falla, el problema es la forma en que el router está resolviendo el path.
RUN ls -l build/server/src/app/api/

# 3. Ejecutar la compilación única.
# Ahora que `src` está en `build/server`, esta compilación debería tener éxito.
RUN npm run build 

EXPOSE 4000 

CMD ["npm", "start"]
