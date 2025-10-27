# Stage 1: Build Stage (for installing dependencies and testing)
FROM node:18-alpine AS build

# Set the working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application source code
COPY . .

# Run mock tests
RUN npm test

# Stage 2: Production Stage (final, small image)
FROM node:18-alpine AS production

# Set the working directory
WORKDIR /usr/src/app

# Copy only the necessary files from the build stage
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/app.js .

# Expose the application port
EXPOSE 3000

# Define the command to run the application
CMD [ "node", "app.js" ]
