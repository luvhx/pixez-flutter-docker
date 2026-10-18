#!/bin/sh
# Generates the HTTP Basic Auth configuration at container start.
#
#   PIXEZ_AUTH_USER      username (default: pixez)
#   PIXEZ_AUTH_PASSWORD  password; when empty, authentication is disabled
#
# The generated files live in /etc/nginx and are referenced by nginx.conf.
set -eu

AUTH_CONF="/etc/nginx/pixez-auth.conf"
HTPASSWD="/etc/nginx/.htpasswd"

if [ -z "${PIXEZ_AUTH_PASSWORD:-}" ]; then
  echo "pixez: PIXEZ_AUTH_PASSWORD is not set - web login verification is DISABLED" >&2
  printf '# authentication disabled (PIXEZ_AUTH_PASSWORD not set)\n' > "$AUTH_CONF"
  exit 0
fi

AUTH_USER="${PIXEZ_AUTH_USER:-pixez}"

# -b: batch, -c: create/overwrite, -m: apr1-MD5 (supported by nginx on
# every libc; recent htpasswd defaults to bcrypt which musl cannot verify).
htpasswd -mbc "$HTPASSWD" "$AUTH_USER" "$PIXEZ_AUTH_PASSWORD"
chmod 644 "$HTPASSWD"

cat > "$AUTH_CONF" <<EOF
auth_basic "PixEz";
auth_basic_user_file $HTPASSWD;
EOF

echo "pixez: HTTP Basic Auth enabled (user: $AUTH_USER)"
