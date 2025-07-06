# T41 Launcher

A simple, customizable terminal-based app launcher designed for older hardware like the IBM T41.

---

## Installation

Run this command in your terminal to install T41 Launcher:

```bash
curl -fsSL https://raw.githubusercontent.com/nebuff/t41launcher/main/installer.sh | sh
```

This will clone the repo to `~/t41launcher`, set permissions, and create a system-wide command `t41launcher` to launch it easily.

---

## Usage

Start the launcher anytime by running:

```bash
t41launcher
```

---

## Adding an alias for shortcuts

If you want to run the launcher or specific apps with short commands, add aliases to your shell config.

For example, to add an alias for the launcher in `~/.bashrc` or `~/.config/fish/config.fish`:

```bash
alias t41='t41launcher'
```

Then reload your shell:

```bash
source ~/.bashrc   # for bash
# or
source ~/.config/fish/config.fish  # for fish shell
```

Now you can run the launcher by typing:

```bash
t41
```

---

## Run launcher automatically on login

To start the launcher automatically when you log into your shell, add this line to your shell config file (`~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`):

```bash
t41launcher
```

This will launch the T41 Launcher every time you open a terminal session.

---

### Optional: Run launcher as your login shell (advanced)

You can replace your default login shell with the launcher by editing `/etc/passwd` (requires care):

```bash
sudo usermod --shell /home/yourusername/t41launcher/launcher.sh yourusername
```

*Warning:* This makes your terminal always open the launcher; use only if you want a kiosk-style setup.

---

## Customize the menu

Edit the `menu.json` file in the installation folder (`~/t41launcher/menu.json`) to add or remove apps. Each entry supports:

- `name` — Display name in the menu  
- `command` — Command to run  
- `description` — Optional description  
- `prompt_args` — Ask for extra arguments? (`true` or `false`)  
- `pause_after` — Pause and wait for ENTER before returning? (`true` or `false`)  
- `sudo` — Run with sudo? (`true` or `false`)  
- `confirm` — Ask for confirmation before running? (`true` or `false`)

---

## Requirements

- bash  
- git  
- jq  
- dialog

Make sure these are installed for full functionality.

---

Feel free to open issues or pull requests on GitHub!
