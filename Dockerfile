FROM node:22-slim 
# 1. Usar la ruta confirmada como Working Directory
WORKDIR /code 

COPY package.json package-lock.json ./
# Este paso fue CACHED y no falló
RUN npm ci

# Copia todo el código fuente. Esto es lo que permite que el build funcione.
COPY . .

# 2. Ejecutar la compilación (Crea la carpeta 'build/' y el archivo 'build/server.js')
RUN npm run build 

# 3. FIX: Copiar la carpeta 'src/app/api' a la ubicación esperada por el código compilado.
# Esto es necesario si el código compilado intenta acceder a la estructura de archivos fuente.
# Si la carpeta 'src/app/api' existe en tu repositorio, la copiamos.
# Si el framework lo requiere, a veces es mejor copiarla a la carpeta de build del servidor.
# Si la carpeta 'api' está en el nivel superior, no la copiamos aquí.
# Basándonos en el error, la ruta esperada es /code/build/server/src/app/api.

# Si la estructura de carpetas es esencial para el runtime, el mejor lugar es copiarla a la raíz.
# Pero el error apunta a la ruta de build del servidor. Asumamos que debe estar allí:
RUN cp -r ./src/app/api ./build/server/src/app/ || true

# Si la carpeta 'api' no existe en 'src/app' (la razón por la que falla),
# un mejor enfoque sería asegurarnos de que el bundler (Vite) copie los archivos necesarios
# durante el paso 'npm run build', o que el código no escanee una carpeta que no existe.
# Ya que no podemos cambiar el código fuente de tu aplicación fácilmente, si el error
# persiste, intenta la solución de abajo.
# --------
# SOLUCIÓN ALTERNATIVA SI 'cp -r' falla o no es la correcta:
# La solución más común es que el código compilado acceda a la carpeta 'src'
# que *debió* ser copiada en el paso de COPY . .
# Sin embargo, dado el error: 'Error finding route files: Error: ENOENT: no such file or directory, scandir /code/build/server/src/app/api',
# significa que la librería de router está intentando escanear esa ruta *dentro* de la carpeta de build.
# Probemos el primer fix:
# --------

EXPOSE 4000 

# 4. Comando de inicio: Ejecutar el script 'start' actualizado
CMD ["npm", "start"]
