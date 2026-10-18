# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Build stage — Flutter web bundle
# ---------------------------------------------------------------------------
# The Flutter SDK is downloaded explicitly instead of relying on a prebuilt
# image, so the version is reproducible and always satisfies the pubspec's
# Dart constraint.  Override with:
#   docker build --build-arg FLUTTER_VERSION=3.47.7 .
ARG FLUTTER_VERSION=3.47.7

FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      unzip \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH \
    PUB_CACHE=/root/.pub-cache \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    CI=true

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && mkdir -p /opt \
 && tar -xJf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz \
 && git config --global --add safe.directory /opt/flutter \
 && flutter --version

WORKDIR /app

# The pubspec has path dependencies (plugins/rhttp, plugins/wakelock_plus_stub)
# so the whole source tree is required before `pub get`.
COPY . .

RUN flutter config --no-analytics >/dev/null 2>&1 || true

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
