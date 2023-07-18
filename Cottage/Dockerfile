# Use the official Node.js 18 image as the base
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install Node.js dependencies
RUN npm install --only=production

# Install tcpdump
RUN apt-get update && apt-get install -y tcpdump

# Copy the application code
COPY . .

# Expose the port on which your Node.js app listens
EXPOSE 3032

# Start the Node.js application
CMD ["node", "app.js"]