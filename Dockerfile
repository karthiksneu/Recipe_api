# Use the official Node.js image as the base image
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies, including devDependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Generate Prisma Client inside the container
RUN npx prisma generate

# Build the NestJS application
RUN npm run build

# Create a new stage to reduce the final image size
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Set environment variables
ENV DATABASE_URL=postgres://recipe:12345@postgres:5432/recipesdb

# Install ts-node globally
RUN npm install -g ts-node

# Run Prisma migrations, seed the database, and then start the application
CMD ["sh", "-c", "npx ts-node prisma/seed.ts && npx prisma migrate deploy && node dist/src/main.js"]
