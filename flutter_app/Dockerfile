# Stage 1: Build Flutter Web app
FROM ghcr.io/cirruslabs/flutter:3.35.6 AS build
WORKDIR /app

# Copy all files from the flutter_app folder (context is flutter_app/)
COPY . .

# Fetch dependencies
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# Copy built web files from the first stage
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
