# Use the official Node.js image
FROM node:18

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy only package.json first (if you have one)
COPY package*.json ./

# Install dependencies (safe even if none exist)
RUN npm install

# Copy rest of the app
COPY . .

# Expose the port your app runs on
EXPOSE 8080

# Command to start your server
CMD ["node", "app.js"]
