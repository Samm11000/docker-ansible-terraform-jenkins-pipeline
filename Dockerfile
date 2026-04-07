# Step 1: Start from official Node.js image (alpine = tiny Linux)
FROM node:18-alpine

# Step 2: Set working directory inside the container
WORKDIR /app

# Step 3: Copy package.json FIRST (Docker caches this layer)
COPY package*.json ./

# Step 4: Install dependencies
RUN npm install --production

# Step 5: Copy the rest of your code
COPY . .

# Step 6: Tell Docker your app uses port 3000
EXPOSE 3000

# Step 7: Command to start the app
CMD ["node", "app.js"]