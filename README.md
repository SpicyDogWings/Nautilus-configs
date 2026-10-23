# nautilus-open-here

Extensión de Nautilus (nautilus-python) que agrega un submenú **Abrir aquí** al menú
contextual:

| Acción | Qué hace |
|---|---|
| **Terminal (Alacritty)** | Abre Alacritty en la carpeta clickeada, con el `$SHELL` del usuario |
| **Zed** | Abre la carpeta (o los archivos seleccionados) en Zed |

```
nautilus-open-here/
├── nautilus-open-here.py   # extensión (nautilus-python)
├── install.sh              # instalador/desinstalador (logging con stk vendorizado)
├── vendor/stk/             # stk: CLI de logging (MIT), compilado a .build/stk
└── vendor/README.md        # origen, commit y cómo actualizar stk
```

Reglas de la carpeta objetivo:

- click en una **carpeta** → esa carpeta
- click en un **archivo** → su carpeta padre
- selección múltiple → el primer item local (Zed recibe todos)
- sin ruta local (trash, red, etc.) → `$HOME`

Los procesos se lanzan desacoplados (`start_new_session`), así que sobreviven al
cierre de Nautilus.

## Requisitos

- Nautilus / GNOME Files
- `nautilus-python` — Fedora: `sudo dnf install nautilus-python`
  (en distros más viejas el paquete es `python3-nautilus`)
- `alacritty` en el `PATH`
- `zed` en el `PATH` (el CLI, no sólo el desktop entry)
- `cargo` (Rust) para compilar el `stk` vendorizado — sólo la primera vez o cuando
  cambie `vendor/stk/`. Sin `cargo`, el script cae al `stk` del `PATH` y avisa.

## Instalación

```bash
./install.sh                       # instala las dos acciones
./install.sh --program alacritty   # menú sólo con "Terminal (Alacritty)"
./install.sh --program zed         # menú sólo con "Zed"
./install.sh -n                    # instala sin reiniciar Nautilus
./install.sh -u                    # desinstala
./install.sh -h                    # ayuda
```

La selección de `--program` se guarda en
`${XDG_CONFIG_HOME:-~/.config}/nautilus-open-here/programs`, que la extensión lee
al armar el menú. Reinstalar sin `--program` borra ese archivo y restaura el menú
completo; `--uninstall` también lo elimina.

Copia `nautilus-open-here.py` a
`${XDG_DATA_HOME:-~/.local/share}/nautilus-python/extensions/` y borra la extensión
previa `alacritty-shell.py` si existía (mismo menú, nombre viejo).

## stk vendorizado

El logging del instalador **no depende del `stk` del sistema**: `vendor/stk/` tiene el
código fuente (MIT, ver `vendor/README.md`) y el script lo compila a `.build/stk`
(`cargo build --release --locked`, cacheado y gitignored). El binario cacheado se
recompila solo si algún fuente de `vendor/stk/` es más nuevo.

Orden de resolución: `.build/stk` → `stk` del `PATH` (con warning) → error.


## Configuración

Los binarios se resuelven por `PATH` con fallback a `/usr/bin/alacritty` y
`~/.local/bin/zed`. Para forzar otros, exportá (por ejemplo en
`~/.config/environment.d/open-here.conf`):

```bash
OPEN_HERE_TERMINAL=/usr/local/bin/alacritty
OPEN_HERE_EDITOR=/usr/local/bin/zed
```

El shell de la terminal es `$SHELL` (fallback `/bin/bash`).

## Desinstalación manual

```bash
rm ~/.local/share/nautilus-python/extensions/nautilus-open-here.py
rm -rf ~/.local/share/nautilus-python/extensions/__pycache__
nautilus -q
```

## Notas

- API usada: Nautilus 4.1 (GNOME 46+), con fallback a 4.0 y 3.0.
- Si el submenú no aparece: `nautilus -q` y reabrí Files; los errores de carga salen
  por el stderr de Nautilus (mirá `journalctl --user -b` o corré
  `nautilus --gapplication-service` desde una terminal).
