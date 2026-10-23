#!/usr/bin/env bash
# install.sh — instala o desinstala la extensión de Nautilus "Abrir aquí".
#
# El logging usa el stk vendorizado en vendor/stk: se compila a .build/stk y se
# ejecuta desde ahí. El stk del PATH queda sólo como último recurso.
set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE="${SCRIPT_DIR}/nautilus-open-here.py"
readonly DEST_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nautilus-python/extensions"
readonly DEST="${DEST_DIR}/nautilus-open-here.py"
readonly LEGACY="${DEST_DIR}/alacritty-shell.py"
readonly CACHE="${DEST_DIR}/__pycache__"

readonly VENDOR_DIR="${SCRIPT_DIR}/vendor/stk"
readonly BUILD_DIR="${SCRIPT_DIR}/.build"
readonly STK_BUILD="${BUILD_DIR}/stk"
readonly BUILD_LOG="${BUILD_DIR}/cargo-build.log"
readonly OPTIONAL_BINS=(alacritty zed)
readonly PROGRAMS_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/nautilus-open-here"
readonly PROGRAMS_FILE="${PROGRAMS_DIR}/programs"

ACTION=install
RESTART=true
STK=""
PROGRAMS=""

# --- logging ---------------------------------------------------------------
# stk 0.2.x/0.3.x no emite salto de línea final en `stk log`; el wrapper lo agrega.
stk() {
  if [[ -z "${STK}" ]]; then
    printf 'stk: no resuelto todavía\n' >&2
    return 1
  fi
  "${STK}" "$@"
  local rc=$?
  if [[ "${1:-}" == "log" ]]; then
    printf '\n'
  fi
  return "${rc}"
}

# Mensajes del bootstrap (todavía no hay stk compilado).
raw() {
  printf '  - %s\n' "$1"
}

die() {
  if [[ -n "${STK}" ]]; then
    stk log "$1" -v error
  else
    printf 'error: %s\n' "$1" >&2
  fi
  exit 1
}

usage() {
  cat <<EOF
${SCRIPT_NAME} — extensión de Nautilus "Abrir aquí" (Alacritty / Zed)

Uso:
  ./${SCRIPT_NAME} [opciones]

Opciones:
  -u, --uninstall    Desinstala la extensión
  -n, --no-restart   No reinicia Nautilus al terminar
  -p, --program LISTA
                     Acciones del menú: alacritty, zed o "alacritty zed"
                     (también con coma). Default: ambas.
  -h, --help         Muestra esta ayuda

Instala el archivo en:
  ${DEST_DIR}

La selección de --program queda en:
  ${PROGRAMS_FILE}

El logging usa el stk vendorizado en vendor/stk (compilado a .build/stk).
Variables de entorno (opcionales):
  XDG_DATA_HOME      Base del directorio de instalación
  XDG_CONFIG_HOME    Base del archivo de programas
EOF
}

# --- stk vendorizado -------------------------------------------------------
# Antes de compilar: usar el binario cacheado (o el del PATH) sólo para que los
# mensajes tempranos ya salgan con stk.
resolve_stk_early() {
  if [[ -x "${STK_BUILD}" ]]; then
    STK="${STK_BUILD}"
  elif command -v stk >/dev/null 2>&1; then
    STK="$(command -v stk)"
  fi
}

stk_build_needed() {
  if [[ ! -x "${STK_BUILD}" ]]; then
    return 0
  fi
  local newer
  newer="$(find "${VENDOR_DIR}/src" "${VENDOR_DIR}/Cargo.toml" "${VENDOR_DIR}/Cargo.lock" \
    -newer "${STK_BUILD}" -print -quit 2>/dev/null || true)"
  [[ -n "${newer}" ]]
}

build_vendored_stk() {
  if ! command -v cargo >/dev/null 2>&1; then
    raw "cargo no está en el PATH: no puedo compilar vendor/stk"
    return 1
  fi

  raw "compilando vendor/stk (release, --locked)"
  if ! CARGO_TARGET_DIR="${BUILD_DIR}/cargo" \
    cargo build --release --locked --manifest-path "${VENDOR_DIR}/Cargo.toml" >"${BUILD_LOG}" 2>&1; then
    raw "cargo build falló; últimas líneas de ${BUILD_LOG##*/}:"
    tail -n 5 "${BUILD_LOG}" | while IFS= read -r line; do
      raw "${line}"
    done
    return 1
  fi

  install -m 0755 "${BUILD_DIR}/cargo/release/stk" "${STK_BUILD}"
  raw "binario en ${STK_BUILD}"
}

ensure_stk() {
  install -d -m 0755 "${BUILD_DIR}"

  if [[ -d "${VENDOR_DIR}/src" ]]; then
    if stk_build_needed && ! build_vendored_stk; then
      raw "sigo con el stk del PATH si existe"
    fi
    if [[ -x "${STK_BUILD}" ]]; then
      STK="${STK_BUILD}"
      stk log "stk vendorizado: $("${STK}" --version 2>/dev/null || printf '%s' "${STK}")" -v debug
      return 0
    fi
  fi

  if command -v stk >/dev/null 2>&1; then
    STK="$(command -v stk)"
    stk log "Usando el stk del PATH (${STK}); el vendorizado no está disponible." -v warning
    return 0
  fi

  printf 'error: no hay stk vendorizado compilado y no encuentro stk en el PATH\n' >&2
  printf '       instalá cargo (rust) o poné stk en el PATH\n' >&2
  exit 1
}

# --- chequeos --------------------------------------------------------------
check_runtime() {
  command -v python3 >/dev/null 2>&1 || die "Falta python3 en el PATH."
  if ! python3 -c 'import gi; gi.require_version("Nautilus", "4.1")' >/dev/null 2>&1; then
    die "Falta el binding de Nautilus para Python (Fedora: sudo dnf install nautilus-python)."
  fi
}

warn_optional() {
  local bin
  local bins=("${OPTIONAL_BINS[@]}")
  if [[ -n "${PROGRAMS}" ]]; then
    read -r -a bins <<<"${PROGRAMS}"
  fi
  for bin in "${bins[@]}"; do
    if ! command -v "${bin}" >/dev/null 2>&1; then
      stk log "No encuentro '${bin}' en el PATH: esa acción del menú va a fallar." -v warning
    fi
  done
}

# Valida y normaliza la lista de --program (separada por comas o espacios).
normalize_programs() {
  [[ -n "${PROGRAMS}" ]] || return 0

  local program normalized=""
  for program in ${PROGRAMS//,/ }; do
    case "${program}" in
      alacritty | zed) ;;
      *)
        die "Programa desconocido: '${program}'. Usá: alacritty, zed o alacritty,zed"
        ;;
    esac
    [[ " ${normalized} " == *" ${program} "* ]] || normalized="${normalized:+${normalized} }${program}"
  done

  [[ -n "${normalized}" ]] || die "--program necesita al menos un programa"
  PROGRAMS="${normalized}"
}

# Persiste la selección que lee la extensión. Sin --program se borra el archivo
# para volver al menú completo (default).
write_programs_config() {
  if [[ -z "${PROGRAMS}" ]]; then
    if [[ -e "${PROGRAMS_FILE}" ]]; then
      rm -f "${PROGRAMS_FILE}"
      rmdir "${PROGRAMS_DIR}" 2>/dev/null || true
      stk log "Config de programas eliminada: menú completo (alacritty + zed)" -v warning
    fi
    return 0
  fi

  install -d -m 0755 "${PROGRAMS_DIR}"
  local program
  for program in ${PROGRAMS}; do
    printf '%s\n' "${program}"
  done >"${PROGRAMS_FILE}"
  stk log "Programas del menú: ${PROGRAMS}" -v success
}

validate_source() {
  [[ -f "${SOURCE}" ]] || die "No encuentro ${SOURCE}"
  python3 -c 'import sys; p = sys.argv[1]; compile(open(p, encoding="utf-8").read(), p, "exec")' "${SOURCE}" \
    || die "El archivo ${SOURCE} tiene errores de sintaxis."
}

restart_nautilus() {
  if [[ "${RESTART}" != "true" ]]; then
    stk log "Nautilus no se reinicia (--no-restart). Acordate de 'nautilus -q'." -v warning
    return 0
  fi
  if ! command -v nautilus >/dev/null 2>&1; then
    stk log "No encuentro 'nautilus' en el PATH: reiniciá Files a mano." -v warning
    return 0
  fi
  nautilus -q >/dev/null 2>&1 || true
  sleep 1
  nohup nautilus --gapplication-service >/dev/null 2>&1 &
  stk log "Nautilus reiniciado" -v success
}

# --- acciones --------------------------------------------------------------
do_install() {
  stk log "Instalando extensión en ${DEST_DIR}"
  install -d -m 0755 "${DEST_DIR}"
  install -m 0644 "${SOURCE}" "${DEST}"

  if [[ -e "${LEGACY}" ]]; then
    rm -f "${LEGACY}"
    stk log "Eliminada la extensión previa ${LEGACY}" -v warning
  fi
  if [[ -d "${CACHE}" ]]; then
    rm -rf "${CACHE}"
  fi

  [[ -f "${DEST}" ]] || die "No se pudo escribir ${DEST}"
  stk log "Instalado ${DEST}" -v success

  write_programs_config
  restart_nautilus
  stk log "Listo: click derecho -> 'Abrir aquí'" -v success
}

do_uninstall() {
  local found=false
  local file
  for file in "${DEST}" "${LEGACY}"; do
    if [[ -e "${file}" ]]; then
      rm -f "${file}"
      stk log "Eliminado ${file}" -v success
      found=true
    fi
  done
  if [[ -d "${CACHE}" ]]; then
    rm -rf "${CACHE}"
  fi
  if [[ -e "${PROGRAMS_FILE}" ]]; then
    rm -f "${PROGRAMS_FILE}"
    stk log "Eliminada la config de programas" -v success
  fi
  rmdir "${PROGRAMS_DIR}" 2>/dev/null || true
  if [[ "${found}" != "true" ]]; then
    stk log "No había nada instalado en ${DEST_DIR}" -v warning
  fi

  restart_nautilus
  stk log "Desinstalación terminada" -v success
}

main() {
  resolve_stk_early

  while (($#)); do
    case "$1" in
      -u | --uninstall) ACTION=uninstall ;;
      -n | --no-restart) RESTART=false ;;
      -p | --program)
        (($# >= 2)) || die "Falta el valor de $1 (alacritty, zed o ambos)"
        PROGRAMS="$2"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "Opción desconocida: $1"
        ;;
    esac
    shift
  done

  normalize_programs
  ensure_stk
  validate_source

  case "${ACTION}" in
    install)
      check_runtime
      warn_optional
      do_install
      ;;
    uninstall)
      do_uninstall
      ;;
  esac
}

main "$@"
