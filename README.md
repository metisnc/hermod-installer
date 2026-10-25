# Hermod — installation

Script d'amorçage de Hermod sur un serveur Debian 12 vierge (VM, VPS ou serveur du client). Il récupère le code
(dépôt privé : un jeton GitHub en lecture seule est demandé, saisie masquée, jamais enregistré), puis lance
l'installation : mises à jour, Docker, pare-feu, SSH, accès par Internet ou par Tailscale, démarrage de Hermod et
affichage du code d'installation. La suite se fait dans le navigateur.

```sh
curl -fsSL https://raw.githubusercontent.com/metisnc/hermod-installer/main/amorcer.sh | sudo bash
```

Options : `| sudo bash -s -- --internet` (ou `--tailscale`). Installe toujours la branche `main`.

Ce dépôt ne contient aucun secret ni aucune partie de l'application : c'est une copie du script
`deploiement/amorcer.sh` du dépôt de Hermod.
