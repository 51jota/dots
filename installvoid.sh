#!/bin/bash

# ==========================================
# VARIÁVEIS DE CONFIGURAÇÃO
# ==========================================
REPO_URL="https://github.com/51jota/dots.git"
CONFIG_DIR="$HOME/niri-dots"

# Lista de pacotes oficiais do Void
PKGS=(
    "niri"
    "waybar"
    "tofi"
    "kitty"
    "dunst"
    "git"
    "base-devel"     # Essencial para compilar coisas
    "nerd-fonts"
    "fastfetch"
    "btop"
    "firefox"
    "neovim"
    "nautilus"
    "sddm"
    "qt6-base"
    "qt6-svg"
    "qt6-virtualkeyboard"
    "qt6-multimedia"
    # Dependências para compilar o swww (Rust)
    "rust"
    "cargo"
    "pkg-config"
    "liblz4-devel"
)

# ==========================================
# FUNÇÕES DE UTILIDADE
# ==========================================
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; }

# ==========================================
# 1. PREPARAÇÃO DO SISTEMA
# ==========================================
log "Atualizando o sistema..."
sudo xbps-install -huy
sudo xbps-install -Su

# Instala repositórios non-free
log "Verificando repositórios non-free..."
sudo xbps-install -S void-repo-nonfree void-repo-multilib --yes

# Dependências básicas (curl, unzip, git)
sudo xbps-install -S git curl unzip --yes

# ==========================================
# 2. ADICIONANDO REPO EXTRA (Hyprlock)
# ==========================================
# O Hyprlock não está no oficial, usamos o repo do Makrennel (comunidade Void)
if [ ! -f /etc/xbps.d/hyprland-void.conf ]; then
    log "Adicionando repositório extra para Hyprlock..."
    echo 'repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc' | sudo tee /etc/xbps.d/hyprland-void.conf
    sudo xbps-install -S
fi

# Adicionamos hyprlock na lista de instalação agora que temos o repo
log "Instalando Hyprlock do repositório extra..."
sudo xbps-install -S hyprlock --yes || error "Falha ao instalar hyprlock"

# ==========================================
# 3. INSTALAÇÃO DOS PACOTES OFICIAIS
# ==========================================
log "Instalando pacotes do repositório oficial..."
for pkg in "${PKGS[@]}"; do
    sudo xbps-install -S "$pkg" --yes
done

# ==========================================
# 4. INSTALAÇÃO DO SWWW (Via Cargo/Rust)
# ==========================================
log "Verificando SWWW..."
if ! command -v swww &> /dev/null; then
    log "Compilando SWWW via Cargo (isso pode demorar um pouco)..."
    # Instala o swww direto do crates.io
    cargo install swww
    
    # Adiciona o binário ao PATH se não estiver (padrão do cargo é ~/.cargo/bin)
    if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
        log "Adicionado ~/.cargo/bin ao PATH."
    fi
else
    log "SWWW já instalado."
fi

# ==========================================
# 5. INSTALAÇÃO DO SUPERFILE
# ==========================================
log "Instalando Superfile..."
if ! command -v superfile &> /dev/null; then
    bash -c "$(curl -sLo- https://superfile.dev/install.sh)"
fi

# ==========================================
# 6. DOTFILES E LINKS
# ==========================================
if [ -d "$CONFIG_DIR" ]; then
    cd "$CONFIG_DIR" && git pull
else
    git clone "$REPO_URL" "$CONFIG_DIR"
fi

link_config() {
    SOURCE="$CONFIG_DIR/$1"
    TARGET="$HOME/.config/$2"
    mkdir -p "$(dirname "$TARGET")"
    
    if [ -e "$TARGET" ]; then mv "$TARGET" "${TARGET}.bak"; fi
    ln -s "$SOURCE" "$TARGET"
}

mkdir -p "$HOME/.config"

# Seus links
link_config "niri" "niri"
link_config "waybar" "waybar"
link_config "kitty" "kitty"
link_config "btop" "btop"
link_config "Code" "Code"
link_config "dunst" "dunst"
link_config "fastfetch" "fastfetch"
link_config "hypr" "hypr"
link_config "mozilla" "mozilla"
link_config "nautilus" "nautilus"
link_config "nvim" "nvim"
link_config "obs-studio" "obs-studio"
link_config "superfile" "superfile"
link_config "tofi" "tofi"
link_config "walls" "walls"

# ==========================================
# 7. SERVIÇOS
# ==========================================
log "Configurando SDDM..."
if [ ! -L /var/service/sddm ] && [ -d /etc/sv/sddm ]; then
    sudo ln -s /etc/sv/sddm /var/service/
fi

# Tema do SDDM
if [ -d "$CONFIG_DIR/sddm" ]; then
    sudo cp -r "$CONFIG_DIR/sddm" /usr/share/
fi

log "Instalação concluída! Reinicie o sistema."
