# stk

Pinta texto en la terminal. Un pequeño CLI en Rust que colorea (y pone en
negrita) el texto que le pases, y que además genera líneas de log con color,
etiqueta y hora.

## Instalación rápida

    curl -fL -o ~/.local/bin/stk \
      https://github.com/SpicyDogWings/stk/releases/download/v0.2.1-alpha/stk
    chmod +x ~/.local/bin/stk

Asegurate de tener `~/.local/bin` en tu `PATH`.

## Requisitos

- Rust y Cargo (edition 2024, toolchain reciente)

## Instalación

Desde el código fuente:

    cargo build --release
    # binario en target/release/stk

O instalándolo en tu `PATH`:

    cargo install --path .

O bajando el binario precompilado de una release (Linux, x86_64); ver
**Instalación rápida** arriba.

## Uso

    stk <TEXT>... [-f <COLOR>]
    stk log <TEXT>... [-v <VARIANT>]

Ejemplos:

    stk "hola mundo"
    stk "hola" -f red
    stk hola mundo --foreground bright-cyan
    stk log "servidor iniciado"
    stk log "algo falló" -v error

## Opciones

Comando principal:

| Argumento                    | Descripción                 | Default         |
|------------------------------|-----------------------------|-----------------|
| `<TEXT>...`                  | Texto a pintar (uno o más)  | — (obligatorio) |
| `-f`, `--foreground <COLOR>` | Color del texto             | `green`         |

Subcomando `log`:

| Argumento                   | Descripción                  | Default         |
|-----------------------------|------------------------------|-----------------|
| `<TEXT>...`                 | Texto del log (uno o más)    | — (obligatorio) |
| `-v`, `--variant <VARIANT>` | Variante semántica del log   | `log`           |

## Colores disponibles

`black`, `red`, `green`, `blue`, `cyan`, `yellow`, `magenta`, `white`,
`bright-black`, `bright-red`, `bright-green`, `bright-blue`, `bright-cyan`,
`bright-yellow`, `bright-magenta`, `bright-white`.

## Variantes de log

Cada variante define el color de fondo de la etiqueta y su texto:

| Variante  | Color        | Etiqueta |
|-----------|--------------|----------|
| `log`     | azul         | `LOG`    |
| `error`   | rojo         | `ERR`    |
| `warning` | amarillo     | `WARN`   |
| `success` | verde        | `SUCC`   |
| `debug`   | bright-black | `DEBG`   |

Cada línea se imprime con la hora local en formato `HH:MM:SS`, la etiqueta de
la variante y el texto.

## Cómo funciona

- `clap` parsea los argumentos: el struct compartido `TextArgs` (texto), el
  color `foreground` del comando principal y el subcomando opcional
  `Commands::Log` con su `variant`.
- `anstyle` construye los estilos ANSI (colores y `Effects::BOLD`).
- `src/color.rs` define `StkColor` (16 colores ANSI) y `ColorVariant` (variantes
  de log), con sus `impl From` y `ColorVariant::label()`.
- `time` obtiene la hora local (`OffsetDateTime::now_local()`, con respaldo a
  UTC) y la formatea con `format_description!`.

## Desarrollo

    cargo build
    cargo run -- "texto" -f green
    cargo run -- log "texto" -v warning
    cargo fmt
    cargo clippy

## Licencia

Este proyecto se distribuye bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE).
