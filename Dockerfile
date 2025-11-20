FROM node:22-slim 
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# 1. Copiar el código *después* de la instalación para asegurar que todo esté en /app
COPY . .

# 2. Ejecutar la compilación
RUN npm run build 

# 3. Este comando de inicio es el que está fallando.
# Vamos a intentar pasar el comando completo, aunque 'npm start' debería ser suficiente.
# Si el error persiste, significa que 'react-router serve' tiene requisitos de entorno adicionales.

EXPOSE 3000
CMD ["npm", "start"]
