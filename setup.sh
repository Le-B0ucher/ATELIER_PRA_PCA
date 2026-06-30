#!/usr/bin/env bash
set -e

echo "=== Séquence 2 : Environnement de travail ==="

# Cluster K3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d cluster create pra --servers 1 --agents 2
kubectl get nodes

# Packer
PACKER_VERSION=1.11.2
curl -fsSL -o /tmp/packer.zip \
  "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
sudo unzip -o /tmp/packer.zip -d /usr/local/bin
rm -f /tmp/packer.zip

# Ansible
python3 -m pip install --user ansible kubernetes PyYAML jinja2
export PATH="$HOME/.local/bin:$PATH"
ansible-galaxy collection install kubernetes.core

echo "=== Séquence 3 : Déploiement de l'infrastructure ==="

# Image Docker avec Packer
packer init .
packer build -var "image_tag=1.0" .
docker images | head

# Import dans le cluster
k3d image import pra/flask-sqlite:1.0 -c pra

# Déploiement Ansible
ansible-playbook ansible/playbook.yml

# Forward du port
kubectl -n pra port-forward svc/flask 8080:80 >/tmp/web.log 2>&1 &

echo "=== Terminé. Va dans l'onglet PORTS pour rendre public le port 8080. ==="