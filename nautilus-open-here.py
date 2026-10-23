#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extensión de Nautilus: click derecho -> submenú "Abrir aquí".

Acciones (sobre la carpeta clickeada, o la carpeta padre si clickeaste un
archivo):
    - Terminal (Alacritty) con el shell del usuario ($SHELL)
    - Zed (con la selección completa si elegiste varios archivos)

Instalación: ./install.sh  (ver README.md)

Qué acciones se muestran lo decide el instalador (`--program alacritty`, `zed` o
ambas) y queda en ${XDG_CONFIG_HOME:-~/.config}/nautilus-open-here/programs. Sin
ese archivo el menú muestra las dos.

Requiere: nautilus-python, alacritty y zed. Los binarios se resuelven por
PATH; se pueden forzar con las variables de entorno OPEN_HERE_TERMINAL y
OPEN_HERE_EDITOR.
"""

import os
import shutil
import subprocess
import sys

import gi

# Probar la versión de la API en orden: 4.1 (GNOME 46+), 4.0 (GNOME 42+),
# 3.0 (GNOME < 42). Si el namespace ya está cargado por nautilus-python,
# require_version solo acepta la versión exacta que ya se cargó.
for _ver in ("4.1", "4.0", "3.0"):
    try:
        gi.require_version("Nautilus", _ver)
        break
    except ValueError:
        continue
from gi.repository import GObject, Nautilus

HOME = os.path.expanduser("~")
TERMINAL = (
    os.environ.get("OPEN_HERE_TERMINAL")
    or shutil.which("alacritty")
    or "/usr/bin/alacritty"
)
EDITOR = (
    os.environ.get("OPEN_HERE_EDITOR")
    or shutil.which("zed")
    or os.path.expanduser("~/.local/bin/zed")
)
SHELL = os.environ.get("SHELL") or "/bin/bash"

# Orden y nombres de las acciones disponibles. El instalador escribe el
# subconjunto elegido en PROGRAMS_FILE; si no existe, se muestran todas.
PROGRAMS = ("alacritty", "zed")
PROGRAMS_FILE = os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config"),
    "nautilus-open-here",
    "programs",
)


def enabled_programs():
    try:
        with open(PROGRAMS_FILE, encoding="utf-8") as fh:
            wanted = {
                part.strip()
                for part in fh.read().replace(",", " ").split()
                if part.strip()
            }
    except OSError:
        return PROGRAMS

    selected = tuple(program for program in PROGRAMS if program in wanted)
    # Si el archivo no tiene ningún nombre válido, no dejamos el menú vacío.
    return selected or PROGRAMS


class OpenHereExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    # -- helpers ---------------------------------------------------------
    @staticmethod
    def _path_of(item):
        """Ruta local del item, o None si no es un archivo local."""
        loc = item.get_location()
        if loc is None or loc.get_uri_scheme() != "file":
            return None
        return loc.get_path() or None

    def _target_dir(self, items):
        """Carpeta donde abrir la terminal.

        - carpeta clickeada  -> esa carpeta
        - archivo clickeado  -> su carpeta padre
        - nada usable        -> ~
        """
        for item in items or []:
            path = self._path_of(item)
            if not path:
                continue
            return path if os.path.isdir(path) else os.path.dirname(path)
        return HOME

    def _local_paths(self, items):
        return [p for p in (self._path_of(it) for it in (items or [])) if p]

    @staticmethod
    def _spawn(cmd):
        try:
            subprocess.Popen(
                cmd,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,  # sobrevive al cierre de Nautilus
                cwd=HOME,
            )
        except OSError as exc:
            sys.stderr.write(
                "open-here: no se pudo lanzar %s: %s\n" % (" ".join(cmd), exc)
            )

    # -- acciones --------------------------------------------------------
    def _open_shell(self, items):
        self._spawn(
            [TERMINAL, "--working-directory", self._target_dir(items), "-e", SHELL]
        )

    def _open_editor(self, items):
        self._spawn([EDITOR] + (self._local_paths(items) or [HOME]))

    # -- menú ------------------------------------------------------------
    def _menu_item(self, slug, label, tip, icon, handler):
        item = Nautilus.MenuItem(
            name="OpenHereExtension::" + slug,
            label=label,
            tip=tip,
            icon=icon,
        )
        item.connect("activate", lambda _item: handler())
        return item

    def _submenu(self, items):
        menu = Nautilus.Menu()
        actions = {
            "alacritty": (
                "Terminal",
                "Terminal (Alacritty)",
                "Abrir Alacritty con %s en esta carpeta" % SHELL,
                "utilities-terminal",
                lambda: self._open_shell(items),
            ),
            "zed": (
                "Zed",
                "Zed",
                "Abrir esta carpeta/archivo en Zed",
                "text-editor",
                lambda: self._open_editor(items),
            ),
        }
        for program in enabled_programs():
            slug, label, tip, icon, handler = actions[program]
            menu.append_item(self._menu_item(slug, label, tip, icon, handler))

        root = Nautilus.MenuItem(
            name="OpenHereExtension::Root",
            label="Abrir aquí",
            tip="Abrir esta carpeta en…",
            icon="system-run",
        )
        root.set_submenu(menu)
        return root

    # -- interfaz MenuProvider -------------------------------------------
    # API 4.0: get_file_items(files); API 3.0: get_file_items(window, files).
    # Con *args funciona en ambas: args[-1] siempre es la lista de archivos.
    def get_file_items(self, *args):
        return [self._submenu(args[-1])]

    def get_background_items(self, *args):
        # Click derecho sobre el fondo: args[-1] es la carpeta actual.
        return [self._submenu([args[-1]])]
