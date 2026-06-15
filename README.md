# macOS Setup

My personal setup script for a fresh Mac.

```sh
bash setup.sh
```

It asks what you want upfront, then runs unattended.

## What gets installed

**Always:**

- Homebrew, git, gh, awscli
- node + fnm (Node version manager)
- Starship prompt + JetBrainsMono Nerd Font
- SSH key (ED25519) wired up to ssh-agent

**Optional groups** — prompted at the start:

- **Databases** — PostgreSQL 17, Redis, Beekeeper Studio, RedisInsight
- **Dev tools** — Zed, iTerm2, Postman, ngrok, Docker, Chrome
- **AI** — Claude Code
- **Communication** — Slack, Telegram, Threema, Spark Mail
- **Design** — Figma
- **Entertainment** — Spotify

## After it finishes

1. Copy the printed SSH public key → add it to [github.com/settings/ssh/new](https://github.com/settings/ssh/new)
2. Run `aws configure` to set up AWS credentials
3. Run `ngrok config add-authtoken <your-token>` if you installed Dev tools
4. Set `JetBrainsMono Nerd Font` in iTerm2 → Preferences → Profiles → Text → Font
5. Run `source ~/.zshrc` or open a new terminal

Safe to re-run — every step checks if something is already installed before touching it.
