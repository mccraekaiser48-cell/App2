# Nimbus OS

A Windows 11–style desktop that runs entirely in the browser, in one file.

`index.html` contains the whole thing — styles, scripts, wallpaper and the
Brave Origin app — with no other files, folders or build step. GitHub Pages
serves it directly at the repo root.

## Brave Origin

The Brave Origin window streams a real Brave Origin running on an Android
phone over a `cloudflared` tunnel. That address is at the top of `index.html`,
once, as `streamUrl`. Quick tunnels get a new address every restart; when the
stream stops, start it again on the phone, copy the new link and replace that
one line.

If the address is empty, the app asks for it once and remembers it in the
browser.

## Publishing

Settings → Pages → Source: **Deploy from a branch** → `main` / `/ (root)` → Save.
The site appears at `https://<user>.github.io/<repo>/`.
