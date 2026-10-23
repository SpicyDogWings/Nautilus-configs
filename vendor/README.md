# stk (vendorizado)

Copia del código fuente de **stk**, usado por `install.sh` para el logging.
`install.sh` lo compila y ejecuta el binario resultante (`.build/stk`); no
depende del `stk` del sistema.

| Campo | Valor |
|---|---|
| Origen | <https://github.com/SpicyDogWings/stk> |
| Commit | `987cc418b5ea551f4f2e3ff636e5e92d6a27f4b2` |
| Versión en `Cargo.toml` | `0.3.0-alpha` |
| Licencia | MIT (ver `stk/LICENSE`) |

## Actualizar

```bash
TMP=$(mktemp -d)
git clone --depth 1 https://github.com/SpicyDogWings/stk "$TMP/stk"
rm -rf vendor/stk
cp -a "$TMP/stk/." vendor/stk/
rm -rf vendor/stk/.git
# actualizar commit/versión en este archivo
git add vendor/stk vendor/README.md
git commit -m "vendor: actualizar stk a <commit>"
```

El próximo `./install.sh` recompila solo (detecta fuentes más nuevas que el
binario cacheado).

## Por qué vendorizado

El script de instalación no asume nada del entorno: el `stk` que colorea los
logs es exactamente el que está versionado acá. Si `cargo` no está disponible,
`install.sh` cae al `stk` del `PATH` y avisa con un warning.
