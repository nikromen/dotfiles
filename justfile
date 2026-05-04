# Dotfiles -- check, lint, and deploy

check:
    shellcheck .local/bin/*
    @echo "Shellcheck passed."

stow-dry-run target="$HOME":
    stow -n -v -R . --target={{target}}

stow target="$HOME":
    stow -R . --target={{target}}

unstow target="$HOME":
    stow -D . --target={{target}}
