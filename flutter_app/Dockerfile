# Stage 1: Build Flutter Web app
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app
COPY flutter_app .

# Fetch dependencies
RUN flutter pub get

# Build the web app
RUN flutter build web

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# Copy built web files from the first stage
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]
