# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Build stage — Flutter web bundle
# ---------------------------------------------------------------------------
# Pin the SDK if you prefer, e.g.
#   docker build --build-arg FLUTTER_VERSION=3.47.7 .
ARG FLUTTER_VERSION=stable

FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

WORKDIR /app

ENV PUB_CACHE=/root/.pub-cache \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    CI=true

# The pubspec has path dependencies (plugins/rhttp, plugins/wakelock_plus_stub)
# so the whole source tree is required before `pub get`.
COPY . .

RUN flutter --version \
 && flutter config --no-analytics >/dev/null 2>&1 || true

RUN flutter pub get

# Generated code (*.g.dart, *.freezed.dart) is not committed.
RUN dart run build_runner build --delete-conflicting-outputs

# SQLite compiled to WebAssembly + the sqflite web worker.
RUN dart run sqflite_common_ffi_web:setup

# --no-web-resources-cdn keeps canvaskit inside the image (works offline).
# --no-wasm-dry-run keeps the JS-only build fast.
RUN flutter build web \
      --release \
      --no-web-resources-cdn \
      --no-wasm-dry-run \
      --no-tree-shake-icons

# ---------------------------------------------------------------------------
# Runtime stage — nginx with the Pixiv reverse proxy
# ---------------------------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

RUN rm -f /etc/nginx/conf.d/default.conf

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/00-cache.conf /etc/nginx/conf.d/00-cache.conf

COPY --from=build /app/build/web /usr/share/nginx/html

# The image proxy cache lives on a volume (see docker-compose.yml).
RUN mkdir -p /var/cache/nginx/pixiv \
    && chown -R nginx:nginx /var/cache/nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1/healthz || exit 1

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
