#!/bin/bash

# ==========================================
# VARIÁVEIS DE CONFIGURAÇÃO
# ==========================================
REPO_URL="https://github.com/51jota/dots.git"
CONFIG_DIR="$HOME/niri-dots"
AUR_HELPER="yay"

# Lista de pacotes para instalar
PKGS=(
    "niri"
    "waybar"
    "tofi"
    "kitty"
    "dunst"
    "swww"
    "git"
    "base-devel"
    "ttf-jetbrains-mono-nerd"
    "fastfetch"
    "btop"
    "hyprlock"
    "firefox"
    "nvim"
    "superfile"
    "nautilus"
    "sddm"
    "qt6"
    "qt6-svq"
    "qt6-vitualkeyboard"
    "qt6-multimedia"
)

# ==========================================
# FUNÇÕES DE UTILIDADE
# ==========================================
# Cores para o output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# ==========================================
# 1. PREPARAÇÃO DO SISTEMA
# ==========================================
log "Atualizando o sistema..."
sudo pacman -Syu --noconfirm

# Verifica se o git está instalado
if ! command -v git &> /dev/null; then
    log "Instalando Git..."
    sudo pacman -S git --noconfirm
fi

# ==========================================
# 2. INSTALAÇÃO DO AUR HELPER (YAY)
# ==========================================
# Verifica se o yay/paru existe. Se não, instala o yay-bin.
if ! command -v $AUR_HELPER &> /dev/null; then
    log "$AUR_HELPER não encontrado. Instalando yay-bin..."
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
else
    log "$AUR_HELPER já está instalado."
fi

# ==========================================
# 3. INSTALAÇÃO DOS PACOTES
# ==========================================
log "Instalando pacotes necessários..."
$AUR_HELPER -S --noconfirm "${PKGS[@]}"

# ==========================================
# 4. CLONAGEM DOS DOTFILES E LINK
# ==========================================
if [ -d "$CONFIG_DIR" ]; then
    log "O diretório de configs já existe. Atualizando..."
    cd "$CONFIG_DIR" && git pull
else
    log "Clonando seus dotfiles..."
    git clone "$REPO_URL" "$CONFIG_DIR"
fi

# Função para fazer backup e link simbólico
link_config() {
    # $1 = pasta no repo (ex: niri)
    # $2 = destino em .config (ex: niri)
    
    SOURCE="$CONFIG_DIR/$1"
    TARGET="$HOME/.config/$2"

    if [ -d "$TARGET" ] || [ -f "$TARGET" ]; then
        log "Fazendo backup de $TARGET para ${TARGET}.bak"
        mv "$TARGET" "${TARGET}.bak"
    fi

    log "Criando link simbólico para $1..."
    ln -s "$SOURCE" "$TARGET"
}

# === APLICAÇÃO DAS CONFIGS (Adapte conforme sua estrutura) ===
mkdir -p "$HOME/.config"

# Exemplo: Linkando a pasta 'niri' do repo para ~/.config/niri
link_config "niri" "niri"
link_config "waybar" "waybar"
link_config "alacritty" "alacritty"
# link_config "pasta-no-repo" "nome-na-config"

# ==========================================
# CONFIGURAÇÃO DO SDDM
# ==========================================
echo -e "\033[0;32m[SETUP]\033[0m Configurando SDDM..."

# 1. Habilita o serviço para iniciar no boot
sudo systemctl enable sddm

# 2. Copia seus temas para a pasta do sistema
# (O -r garante que copie a pasta do tema inteira)
if [ -d "$CONFIG_DIR/sddm/themes" ]; then
    echo "Copiando temas..."
    sudo cp -r "$CONFIG_DIR/sddm/themes/"* /usr/share/sddm/themes/
fi

# 3. Copia seu arquivo de configuração
if [ -f "$CONFIG_DIR/sddm/sddm.conf" ]; then
    echo "Aplicando sddm.conf..."
    sudo cp "$CONFIG_DIR/sddm/sddm.conf" /etc/sddm.conf
fi

log "Instalação concluída! Reinicie o sistema ou inicie o Niri."
