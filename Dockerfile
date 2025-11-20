# 1. IMAGEN BASE
# Usamos una imagen Node.js moderna y estable
FROM node:20-slim

# 2. DIRECTORIO DE TRABAJO
# Establecemos el directorio donde vivirá el código dentro del contenedor
WORKDIR /app

# 3. COPIAR ARCHIVOS DE INSTALACIÓN
COPY package.json package-lock.json ./

# 4. INSTALAR DEPENDENCIAS
# 'npm ci' es ideal para Docker builds
RUN npm ci

# 5. COPIAR EL RESTO DEL CÓDIGO
# Copiamos todos tus archivos (src, plugins, configs, etc.)
COPY . .

# 6. COMPILAR LA APLICACIÓN
# Ejecutamos tu script de compilación: "react-router build"
# Esto crea los archivos estáticos de producción.
RUN npm run build 

# 7. EXPOSICIÓN DE PUERTO
# El puerto 3000 es común para proyectos de Node/React/Vite. 
# Si tu servidor 'react-router serve' usa un puerto diferente, cámbialo aquí.
EXPOSE 3000

# 8. COMANDO DE INICIO DEL SERVIDOR
# Usamos tu script de inicio: "react-router serve"
CMD ["npm", "start"]
