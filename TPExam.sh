#!/usr/bin/env bash
set -euo pipefail


# Installer les paquets nécessaires (pour VM fraîche)
apt-get update
apt-get install -y acl sudo


# ------------- comptes et groupes -------------
# groupes
groupadd -f geeks || true
groupadd -f secrets || true

useradd -m -s /bin/bash alice
useradd -m -s /bin/bash bob
useradd -m -s /bin/bash geek
useradd -m -s /bin/bash ops
useradd -m -s /bin/bash player


# mots de passe simples pour testing (changer avant diffusion si vous voulez)
echo "alice:Alice123" | chpasswd
echo "bob:Bob123" | chpasswd
echo "geek:geek123" | chpasswd
echo "ops:Ops123" | chpasswd
echo "player:Player123" | chpasswd


# ajout aux groupes
usermod -aG geeks,secrets alice
usermod -aG ops bob
usermod -aG geeks geek
usermod -aG ops,geeks ops
# player volontairement laissé hors des groupes sensibles


# ------------- arborescence et flag -------------
mkdir -p /srv/hidden
# Le flag appartient à alice mais est initialement non lisible (0000) -> obligera l'usage de chmod par alice
echo "RM{Br4v0_p3rm1ss10n}" > /srv/hidden/flag.txt
chown root:root /srv/hidden/flag.txt
chmod 0000 /srv/hidden/flag.txt

# Le dossier est possédé par alice (elle pourra modifier ses permissions si nécessaire)
chown -R alice:secrets /srv/hidden
chmod 0700 /srv/hidden


# ------------- indices et fichiers mal configurés -------------
# README dans le home du joueur
mkdir -p /home/player
cat > /home/player/README.txt <<'EOF'
Bienvenue. Explore l'arborescence et les comptes locaux. Il faut vraiment que je fasse le tri dans var/backups un de ces 4.
Hint: ls -la, id, groups, getfacl et find sont tes amis.
EOF
chown player:player /home/player/README.txt
chmod 0644 /home/player/README.txt


# fichier accessible mais ne contenant pas de credentials (pour leurrer légèrement)
mkdir -p /var/backups
chown player:player /var/backups
cat > /var/backups/notes_public.txt <<'EOF'
Fichier de logs public. Pas de secrets ici.
EOF
chown root:root /var/backups/notes_public.txt
chmod 0644 /var/backups/notes_public.txt


# fichier privé lisible uniquement par ops (contient la credential alice)
echo "alice:Alice123" > /var/backups/bob_backup.log
chown ops:ops /var/backups/bob_backup.log
chmod 0640 /var/backups/bob_backup.log


# Chaînage de credentials: geek possède un fichier lisible par geek qui contient ops:Ops123
mkdir -p /home/geek
echo "ops:Ops123" > /home/geek/ops_pass.txt
chown geek:geek /home/geek/ops_pass.txt
chmod 000 /home/geek/ops_pass.txt


# Et alice publie (volontairement pour le CTF) le mot de passe de geek dans un fichier world-readable
mkdir -p /home/alice
echo "geek:geek123 note à moi même, il faut vraiment que je clean /srv" > /var/backups/public_info.txt
chown alice:alice /var/backups/public_info.txt
chmod 0644 /var/backups/public_info.txt

# autre indice (non critique)
echo "J'aime le groupe geeks." > /home/alice/hint.txt
chown alice:geeks /home/alice/hint.txt
chmod 0400 /home/alice/hint.txt


# ------------- ACLs exemples (pas nécessaires pour la chaîne, info pédagogique) -------------
setfacl -m u:geek:r-- /srv/hidden/flag.txt || true


# ------------- permissions finales -------------
chmod 700 /home/alice
chmod 700 /home/bob
chmod 700 /home/geek
chmod 700 /home/ops
chmod 700 /home/player


# laisser /var/backups world-readable pour listage, mais seul ops peut lire bob_backup.log
chmod 755 /var/backups


# ------------- nettoyage de logs inutiles (facultatif) -------------
history -c || true

cat <<EOF
Installation terminée.
- player / Player123 (compte de départ)

Bonne création !
EOF

exec su - player