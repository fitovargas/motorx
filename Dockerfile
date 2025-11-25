FROM node:22-slim 
WORKDIR /code 

COPY package.json package-lock.json ./
RUN npm ci
COPY . .

# FIX: La compilación del router busca archivos fuente dentro del directorio de salida del SSR (`build/server/`).
# Se requiere una compilación de dos pasos para crear primero el directorio `build/server/`, copiar los archivos fuente, y luego completar la compilación.

# 1. Primera pasada de compilación (Crea `build/server` y falla en el escaneo de rutas)
# `|| true` previene que Docker falle completamente en este paso.
RUN npm run build || true

# 2. Copia la carpeta de código fuente 'src' al directorio de salida del SSR.
RUN cp -r ./src ./build/server/

# 3. Segunda pasada de compilación (Debería tener éxito ahora que los archivos están en su sitio)
RUN npm run build 

EXPOSE 4000 

CMD ["npm", "start"]
