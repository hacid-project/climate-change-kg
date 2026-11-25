#!/usr/bin/env bash
# Sets up keng.istc.cnr.it to serve the Climate Change Knowledge Graph (see README.md here).
#
#   sudo deployment/install.sh kgserve   knowledge-graph-serve (Docker), on 127.0.0.1:8081
#   sudo deployment/install.sh front     nginx on ports 80 and 443, and the certificate
#
# Both can be run again at any time: they bring the server in line with the files of this
# folder (e.g. after changing kgserve/config.json or KGSERVE_REF).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

DOMAIN=keng.istc.cnr.it
# knowledge-graph-serve, at a reviewed commit (update it to deploy a newer version).
KGSERVE_REPO=https://github.com/miguel76/knowledge-graph-serve.git
KGSERVE_REF="${KGSERVE_REF:-a120c466b9959b2db76ac9017616d87097517d89}"
KGSERVE_DIR="${KGSERVE_DIR:-/srv/kgserve/climate-change-kg}"
# Where nginx answers the HTTP challenges of Let's Encrypt.
WEBROOT=/var/www/letsencrypt

die() { echo "install.sh: $*" >&2; exit 1; }
step() { echo "==> $*"; }

install_kgserve() {
    command -v docker >/dev/null || die "Docker is not installed"
    docker compose version >/dev/null 2>&1 || die "the Docker Compose plugin is not installed"

    if [ ! -d "$KGSERVE_DIR/.git" ]; then
        step "Cloning knowledge-graph-serve into $KGSERVE_DIR"
        mkdir -p "$(dirname "$KGSERVE_DIR")"
        git clone --quiet "$KGSERVE_REPO" "$KGSERVE_DIR"
    fi
    step "Checking out knowledge-graph-serve $KGSERVE_REF"
    git -C "$KGSERVE_DIR" fetch --quiet origin
    git -C "$KGSERVE_DIR" checkout --quiet --detach "$KGSERVE_REF"

    # Without it, Docker would create a directory in its place.
    [ -s "$KGSERVE_DIR/graphdb.license" ] ||
        die "put the GraphDB license in $KGSERVE_DIR/graphdb.license (the one of climate-change-kg-docker), then run this again"

    local config_changed=no
    if [ -e "$KGSERVE_DIR/config.json" ] && ! cmp -s "$HERE/kgserve/config.json" "$KGSERVE_DIR/config.json"; then
        config_changed=yes
    fi
    step "Installing config.json, compose.keng.yaml and .env"
    install -m 644 "$HERE/kgserve/config.json" "$KGSERVE_DIR/config.json"
    install -m 644 "$HERE/kgserve/compose.keng.yaml" "$KGSERVE_DIR/compose.keng.yaml"
    install -m 644 "$HERE/kgserve/compose.env" "$KGSERVE_DIR/.env"

    step "Building and starting the services"
    (cd "$KGSERVE_DIR" && docker compose up -d --build --remove-orphans)
    if [ "$config_changed" = yes ]; then
        # The services read config.json when they start.
        step "config.json changed: restarting sync and linked-data"
        (cd "$KGSERVE_DIR" && docker compose restart sync linked-data)
    fi

    echo
    echo "knowledge-graph-serve runs in $KGSERVE_DIR, at http://${KG_LISTEN:-127.0.0.1:8081}/."
    echo "Follow the load of the KG with: cd $KGSERVE_DIR && docker compose logs -f sync"
}

install_front() {
    # The nginx of climate-change-kg-docker (a container) must be stopped first.
    local others
    others="$(ss -ltnpH '( sport = :80 or sport = :443 )' | grep -v '"nginx"' || true)"
    [ -z "$others" ] || die "ports 80/443 are taken by another program (the nginx of climate-change-kg-docker? stop it first):
$others"

    step "Installing nginx and certbot"
    apt-get update -q >/dev/null
    apt-get install -y -q nginx certbot >/dev/null

    step "Installing the nginx sites"
    install -d -m 755 "$WEBROOT"
    install -m 644 "$HERE/nginx/keng-http.conf" "$HERE/nginx/keng-https.conf" /etc/nginx/sites-available/
    rm -f /etc/nginx/sites-enabled/default
    ln -sfn ../sites-available/keng-http.conf /etc/nginx/sites-enabled/keng-http.conf

    if [ ! -e "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        # nginx serves HTTP only until the certificate exists.
        rm -f /etc/nginx/sites-enabled/keng-https.conf
        nginx -t -q
        systemctl enable --quiet nginx
        systemctl reload-or-restart nginx

        step "Obtaining the certificate of $DOMAIN from Let's Encrypt"
        local account=(--register-unsafely-without-email)
        [ -z "${CERTBOT_EMAIL:-}" ] || account=(--email "$CERTBOT_EMAIL")
        # The webroot and the deploy hook are saved in /etc/letsencrypt/renewal/$DOMAIN.conf,
        # and used by every renewal.
        certbot certonly --non-interactive --agree-tos "${account[@]}" \
            --webroot -w "$WEBROOT" -d "$DOMAIN" \
            --deploy-hook "systemctl reload nginx"
    fi

    ln -sfn ../sites-available/keng-https.conf /etc/nginx/sites-enabled/keng-https.conf
    nginx -t -q
    systemctl enable --quiet nginx
    systemctl reload-or-restart nginx

    if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
        step "Opening ports 80 and 443 in ufw"
        ufw allow "Nginx Full" >/dev/null
    fi

    step "Checking the automatic renewal"
    systemctl enable --now --quiet certbot.timer
    systemctl list-timers certbot.timer --no-pager
    certbot renew --dry-run --cert-name "$DOMAIN" --no-random-sleep-on-renew

    echo
    echo "https://$DOMAIN/climate-change-kg/ is served by nginx; the certificate renews automatically."
}

[ "$(id -u)" -eq 0 ] || die "run it as root (sudo)"
case "${1:-}" in
    kgserve) install_kgserve ;;
    front) install_front ;;
    *) die "usage: $0 kgserve|front" ;;
esac
