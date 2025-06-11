#!/usr/bin/env bash

set -euo pipefail

# Ensure the system is up-to-date
echo "[+] Updating system packages..."
sudo pacman -Syu --noconfirm

# Package list
PACKAGES=(
  gcc cmake make nodejs dotnet-sdk python
  vulkan-headers vulkan-icd-loader
  xorg xorg-xinit xorg-xinput xorg-xprop
  libx11 libxcb libxkbcommon
  base-devel curl git iputils
  openssh openssh-server openssl
  tmux unzip wget lsof yq zsh
)

# Install missing packages
echo "[+] Installing development packages..."
for pkg in "${PACKAGES[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    echo "    Installing: $pkg"
    sudo pacman -S --noconfirm "$pkg"
  else
    echo "    Already installed: $pkg"
  fi
done

# Vulkan SDK setup
VULKAN_SDK_DIR="/usr/local/vulkan-sdk"
if [ ! -d "$VULKAN_SDK_DIR" ]; then
  echo "[+] Downloading Vulkan SDK..."
  wget -q --show-progress https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.xz -O /tmp/vulkan-sdk.tar.xz
  echo "[+] Extracting Vulkan SDK..."
  tar -xf /tmp/vulkan-sdk.tar.xz -C /tmp
  SDK_PATH=$(find /tmp -maxdepth 1 -type d -name "1.*" | head -n 1)
  sudo mv "$SDK_PATH" "$VULKAN_SDK_DIR"
  rm -f /tmp/vulkan-sdk.tar.xz

  echo "[+] Configuring Vulkan environment..."
  echo "export VULKAN_SDK=${VULKAN_SDK_DIR}" | sudo tee /etc/profile.d/vulkan-sdk.sh
  echo "export PATH=\$VULKAN_SDK/bin:\$PATH" | sudo tee -a /etc/profile.d/vulkan-sdk.sh
  echo "export LD_LIBRARY_PATH=\$VULKAN_SDK/lib:\$LD_LIBRARY_PATH" | sudo tee -a /etc/profile.d/vulkan-sdk.sh
  echo "export VK_ICD_FILENAMES=\$VULKAN_SDK/etc/vulkan/icd.d" | sudo tee -a /etc/profile.d/vulkan-sdk.sh
  echo "export VK_LAYER_PATH=\$VULKAN_SDK/etc/vulkan/explicit_layer.d" | sudo tee -a /etc/profile.d/vulkan-sdk.sh
  sudo chmod +x /etc/profile.d/vulkan-sdk.sh
else
  echo "[+] Vulkan SDK already set up at $VULKAN_SDK_DIR"
fi

# Zsh + Oh-My-Zsh setup
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[+] Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

  echo "[+] Installing Zsh plugins..."
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"

  echo "[+] Configuring Zsh plugins and theme..."
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)/' ~/.zshrc
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

  cp "$HOME/.oh-my-zsh/themes/agnoster.zsh-theme" "$ZSH_CUSTOM/themes/" 2>/dev/null || true
  sed -i '/^prompt_context()/,/^}/c\prompt_context() {}' "$ZSH_CUSTOM/themes/agnoster.zsh-theme" 2>/dev/null || true

  echo "[+] Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
else
  echo "[+] Oh My Zsh already installed."
fi

echo "[✔] Development environment setup complete."