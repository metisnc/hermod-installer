#!/usr/bin/env bash
# Amorçage de Hermod sur un serveur Debian 12 (ou Ubuntu 22.04 / 24.04) vierge : récupère le code puis lance
# l'installation.
#
#   curl -fsSL https://raw.githubusercontent.com/metisnc/hermod-installer/main/amorcer.sh | sudo bash
#   (options : ... | sudo bash -s -- --internet | --tailscale)
#
# Installe toujours la branche main : on ne déploie jamais une branche de travail.
#
# Demande un jeton GitHub en lecture seule sur le dépôt (saisie masquée) : il sert au seul téléchargement du code,
# n'est écrit nulle part sur la machine et n'apparaît pas dans l'historique du terminal. Ce script ne contient aucun
# secret : il peut être transmis librement.
set -euo pipefail

DEPOT="metisnc/assistant-tri-mails"
DOSSIER=/opt/hermod
BRANCHE=main
OPTIONS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --internet | --tailscale) OPTIONS+=("$1"); shift ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

[ "$(id -u)" = 0 ] || { echo "À lancer avec sudo." >&2; exit 1; }
UTILISATEUR=${SUDO_USER:-}
[ -n "$UTILISATEUR" ] && [ "$UTILISATEUR" != root ] || {
  echo "Lancer avec sudo depuis un compte ordinaire (il sera propriétaire de $DOSSIER)." >&2
  exit 1
}

printf '\n\033[1;35m▸ Récupération du code de Hermod (%s, branche %s)\033[0m\n' "$DEPOT" "$BRANCHE"
if [ -d "$DOSSIER/.git" ]; then
  echo "  Code déjà présent dans $DOSSIER : mise à jour."
fi
apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git ca-certificates >/dev/null
read -rsp "  Jeton GitHub (lecture seule, saisie masquée) : " JETON </dev/tty
echo
[ -n "$JETON" ] || { echo "Jeton vide." >&2; exit 1; }

# Le jeton passe par un en-tête HTTP en mémoire : ni dans l'adresse du dépôt, ni dans la configuration git
ENTETE="Authorization: Basic $(printf 'x-access-token:%s' "$JETON" | base64 -w0)"
install -d -o "$UTILISATEUR" -g "$UTILISATEUR" "$DOSSIER"
if [ -d "$DOSSIER/.git" ]; then
  sudo -u "$UTILISATEUR" git -C "$DOSSIER" -c http.extraHeader="$ENTETE" fetch -q origin "$BRANCHE"
  sudo -u "$UTILISATEUR" git -C "$DOSSIER" checkout -q "$BRANCHE"
  sudo -u "$UTILISATEUR" git -C "$DOSSIER" -c http.extraHeader="$ENTETE" pull -q --ff-only origin "$BRANCHE"
else
  sudo -u "$UTILISATEUR" git -c http.extraHeader="$ENTETE" clone -q --branch "$BRANCHE" \
    "https://github.com/$DEPOT.git" "$DOSSIER"
fi
unset JETON ENTETE
echo "  Code à jour : $(sudo -u "$UTILISATEUR" git -C "$DOSSIER" log -1 --format='%h %s')"
echo "  Le jeton n'est conservé nulle part : il sera redemandé pour une prochaine mise à jour."

exec "$DOSSIER/deploiement/installer.sh" "${OPTIONS[@]}"
