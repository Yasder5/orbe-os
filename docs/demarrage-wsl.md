# Kit de démarrage Orbe OS

Pour un PC sous Windows, via WSL2 (Ubuntu). Tout se fait dans WSL, pas dans `C:` : Windows casserait les liens symboliques et les droits des fichiers.

1. Dans PowerShell en administrateur, puis redémarre si Windows le demande :
   `wsl --install -d Ubuntu`
2. Dans le terminal Ubuntu, en remplaçant `TON_NOM` par ton nom d'utilisateur Windows :
   `sudo apt update && sudo apt install -y unzip && cp /mnt/c/Users/TON_NOM/Downloads/orbe-os-kit.zip ~ && cd ~ && unzip orbe-os-kit.zip && mkdir -p ~/orbe-os && cp -a orbe-os-kit/. ~/orbe-os/`
3. Installe Claude Code, puis lance-le dans le dossier :
   `curl -fsSL https://claude.ai/install.sh | bash`
   `cd ~/orbe-os && claude`
4. Écris-lui : `Lis CLAUDE.md et suis ses instructions.`

Claude vérifiera le PC, te donnera les commandes `sudo` éventuelles, puis te demandera de valider les choix techniques et la licence avant d'écrire du code.
