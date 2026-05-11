FROM node:18-alpine
WORKDIR /app
COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm install --only=production
COPY server.js server.js
EXPOSE 8080
CMD ["npm", "start"]
