FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app
COPY flutter_app .

RUN flutter pub get
RUN flutter build web

FROM nginx:stable-alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
