#!/usr/bin/env bash
# =============================================================================
# macOS Setup Script — Mykola's Dev Environment
# Run once on a fresh Mac: bash setup.sh
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()     { echo -e "${GREEN}▶${RESET} $*"; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
fail()    { echo -e "${RED}✖ $*${RESET}" >&2; exit 1; }

# ── Helpers ───────────────────────────────────────────────────────────────────
brew_install() {
  local pkg="$1"
  if brew list --formula "$pkg" &>/dev/null; then
    warn "Already installed: $pkg — skipping"
  else
    log "Installing: $pkg"
    brew install "$pkg"
  fi
}

cask_install() {
  local pkg="$1"
  if brew list --cask "$pkg" &>/dev/null; then
    warn "Already installed: $pkg — skipping"
  else
    log "Installing: $pkg"
    brew install --cask "$pkg"
  fi
}

# Ask yes/no, default No. Usage: confirm "Install X?" && do_thing
confirm() {
  local prompt="$1"
  local reply
  echo -en "  ${BOLD}${prompt}${RESET} ${CYAN}[y/N]${RESET} "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# =============================================================================
# Collect user input upfront
# =============================================================================
echo ""
echo -e "${BOLD}📋 Setup configuration${RESET}"
echo ""

while true; do
  read -rp "  GitHub email for SSH key: " GITHUB_EMAIL
  [[ -n "$GITHUB_EMAIL" ]] && break
  echo "  Email cannot be empty, try again."
done

echo ""
echo -e "  Got it — will generate SSH key for: ${CYAN}${GITHUB_EMAIL}${RESET}"
echo ""

# ── Group selection ───────────────────────────────────────────────────────────
echo -e "${BOLD}📦 Select which groups to install:${RESET}"
echo ""

confirm "Databases  (PostgreSQL, Redis + GUI tools: Beekeeper Studio, Redis Insight)?" && INSTALL_DB=true       || INSTALL_DB=false
confirm "Dev tools  (Zed, iTerm2, Postman, ngrok)?"                                   && INSTALL_DEV=true      || INSTALL_DEV=false
confirm "NestJS CLI (latest, via npm)?"                                                && INSTALL_NESTJS=true   || INSTALL_NESTJS=false
confirm "AI         (Claude Code)?"                                                    && INSTALL_AI=true       || INSTALL_AI=false
confirm "Communication  (Slack, Telegram, Threema beta, Spark Mail)?"                 && INSTALL_COMMS=true    || INSTALL_COMMS=false
confirm "Design     (Figma)?"                                                          && INSTALL_DESIGN=true   || INSTALL_DESIGN=false
confirm "Entertainment  (Spotify)?"                                                    && INSTALL_ENTERTAINMENT=true || INSTALL_ENTERTAINMENT=false

echo ""

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
section "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools already installed — skipping"
else
  log "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  echo -e "${YELLOW}  A dialog has opened to install Xcode Command Line Tools."
  echo -e "  Complete that installation, then press Enter here to continue...${RESET}"
  read -r
fi

# =============================================================================
# 2. Homebrew
# =============================================================================
section "Homebrew"
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  log "Homebrew already installed — updating..."
  brew update
fi

# =============================================================================
# 3. Core CLI tools (always installed)
# =============================================================================
section "Core CLI tools"

brew_install git
brew_install node
brew_install starship
brew_install gh
brew_install fnm
brew_install pnpm
brew_install awscli

ZSHRC="$HOME/.zshrc"

# fnm init
if ! grep -q 'fnm env' "$ZSHRC" 2>/dev/null; then
  log "Adding fnm to .zshrc"
  cat >> "$ZSHRC" <<'EOF'

# ── fnm (Node version manager) ───────────────────────────────────────────────
eval "$(fnm env --use-on-cd --shell zsh)"
EOF
fi

# =============================================================================
# 4. Shell — Zsh + Starship
# =============================================================================
section "Shell setup"

if ! grep -q 'starship init zsh' "$ZSHRC" 2>/dev/null; then
  log "Adding Starship to .zshrc"
  cat >> "$ZSHRC" <<'EOF'

# ── Starship prompt ──────────────────────────────────────────────────────────
eval "$(starship init zsh)"
EOF
fi

if [[ "$SHELL" != "$(which zsh)" ]]; then
  log "Setting default shell to zsh"
  chsh -s "$(which zsh)"
fi

# =============================================================================
# 5. Fonts (always, since Starship is always installed)
# =============================================================================
section "Fonts"
log "Installing JetBrains Mono Nerd Font..."
cask_install font-jetbrains-mono-nerd-font

# =============================================================================
# 6. iTerm2 (part of Dev tools group, but needed by everyone — warn if skipped)
# =============================================================================
section "iTerm2"
if [[ "$INSTALL_DEV" == true ]]; then
  cask_install iterm2
else
  warn "Dev tools skipped — iTerm2 not installed. You can install it later with: brew install --cask iterm2"
fi

# =============================================================================
# 7. Databases (PostgreSQL + Redis + GUIs — always together)
# =============================================================================
if [[ "$INSTALL_DB" == true ]]; then
  section "Databases & GUI tools"

  brew_install postgresql@17
  brew_install redis

  if ! grep -q 'postgresql@17' "$ZSHRC" 2>/dev/null; then
    echo "export PATH=\"$(brew --prefix)/opt/postgresql@17/bin:\$PATH\"" >> "$ZSHRC"
  fi

  log "Starting PostgreSQL (launch on login)..."
  brew services start postgresql@17

  log "Starting Redis (launch on login)..."
  brew services start redis

  # GUI tools — only useful with the engines running
  cask_install beekeeper-studio
  cask_install redis-insight
else
  warn "Databases skipped — PostgreSQL, Redis, Beekeeper Studio and Redis Insight will not be installed."
fi

# =============================================================================
# 8. Dev tools
# =============================================================================
if [[ "$INSTALL_DEV" == true ]]; then
  section "Dev tools"
  cask_install zed
  cask_install postman
  cask_install ngrok
  cask_install docker
  cask_install google-chrome
  echo ""
  echo -e "${YELLOW}  Remember: run 'ngrok config add-authtoken <your-token>' after install.${RESET}"
fi

# =============================================================================
# 9. NestJS CLI
# =============================================================================
if [[ "$INSTALL_NESTJS" == true ]]; then
  section "NestJS CLI"
  if command -v nest &>/dev/null; then
    log "NestJS CLI found — updating to latest..."
  else
    log "Installing NestJS CLI (latest) via npm..."
  fi
  npm install -g @nestjs/cli@latest
fi

# =============================================================================
# 10. AI — Claude Code
# =============================================================================
if [[ "$INSTALL_AI" == true ]]; then
  section "Claude Code"
  if command -v claude &>/dev/null; then
    warn "Claude Code already installed — skipping"
  else
    log "Installing Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code
  fi
fi

# =============================================================================
# 11. Communication
# =============================================================================
if [[ "$INSTALL_COMMS" == true ]]; then
  section "Communication"
  cask_install slack
  cask_install telegram
  cask_install threema@beta
  cask_install readdle-spark
fi

# =============================================================================
# 12. Design
# =============================================================================
if [[ "$INSTALL_DESIGN" == true ]]; then
  section "Design"
  cask_install figma
fi

# =============================================================================
# 13. Entertainment
# =============================================================================
if [[ "$INSTALL_ENTERTAINMENT" == true ]]; then
  section "Entertainment"
  cask_install spotify
fi

# =============================================================================
# 14. SSH Key
# =============================================================================
section "SSH Key"

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
  warn "SSH key already exists at $SSH_KEY — skipping generation"
else
  log "Generating ED25519 SSH key for ${GITHUB_EMAIL}..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY" -N ""
  log "Starting ssh-agent and adding key..."
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY"

  if ! grep -q 'ssh-agent' "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" <<'EOF'

# ── SSH agent ────────────────────────────────────────────────────────────────
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
  fi
fi

echo ""
echo -e "${BOLD}${CYAN}══ Your public SSH key (add this to GitHub → Settings → SSH Keys) ══${RESET}"
echo ""
cat "${SSH_KEY}.pub"
echo ""

# =============================================================================
# Done
# =============================================================================
section "All done"
echo -e "${GREEN}${BOLD}"
echo "  ✔  Xcode CLT              installed"
echo "  ✔  Homebrew               installed / updated"
echo "  ✔  git                    $(git --version 2>/dev/null | head -1)"
echo "  ✔  node                   $(node --version 2>/dev/null)"
echo "  ✔  fnm                    $(fnm --version 2>/dev/null | head -1)"
echo "  ✔  pnpm                   $(pnpm --version 2>/dev/null | head -1)"
echo "  ✔  gh                     $(gh --version 2>/dev/null | head -1)"
echo "  ✔  awscli                 $(aws --version 2>/dev/null | head -1)"
echo "  ✔  starship               prompt configured"
echo "  ✔  JetBrains Nerd Font    installed"
echo "  ✔  SSH key                ~/.ssh/id_ed25519"
[[ "$INSTALL_DB" == true ]]            && echo "  ✔  PostgreSQL + Redis     running as services"
[[ "$INSTALL_DB" == true ]]            && echo "  ✔  Beekeeper + RedisInsight  installed"
[[ "$INSTALL_DEV" == true ]]           && echo "  ✔  iTerm2, Zed, Postman, ngrok, Docker, Chrome  installed"
[[ "$INSTALL_NESTJS" == true ]]        && echo "  ✔  NestJS CLI             $(nest --version 2>/dev/null || echo 'installed')"
[[ "$INSTALL_AI" == true ]]            && echo "  ✔  Claude Code            $(claude --version 2>/dev/null || echo 'installed')"
[[ "$INSTALL_COMMS" == true ]]         && echo "  ✔  Slack, Telegram, Threema, Spark Mail  installed"
[[ "$INSTALL_DESIGN" == true ]]        && echo "  ✔  Figma                  installed"
[[ "$INSTALL_ENTERTAINMENT" == true ]] && echo "  ✔  Spotify                installed"
echo -e "${RESET}"
echo -e "${YELLOW}→ Configure AWS CLI: run 'aws configure' and enter your Access Key, Secret, and region.${RESET}"
echo -e "${YELLOW}→ Copy the public key above and add it at: https://github.com/settings/ssh/new${RESET}"
echo -e "${YELLOW}→ Set 'JetBrainsMono Nerd Font' in iTerm2 → Preferences → Profiles → Text → Font${RESET}"
echo -e "${YELLOW}→ Restart your terminal (or run: source ~/.zshrc) to apply shell changes.${RESET}"
[[ "$INSTALL_COMMS" == true ]] && echo -e "${YELLOW}→ Sign in to Slack, Telegram, Threema, and Spark manually.${RESET}"
echo ""
