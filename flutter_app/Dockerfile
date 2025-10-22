FROM ghcr.io/cirruslabs/flutter:3.35.6 AS build
WORKDIR /app

COPY . .

RUN flutter pub get

RUN flutter build web

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
