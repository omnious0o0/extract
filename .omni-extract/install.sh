#!/usr/bin/env bash

set -euo pipefail

PROJECT_REPO="omnious0o0/omni-extract"
SOURCE_URL="${OMNI_EXTRACT_SOURCE_URL:-https://raw.githubusercontent.com/${PROJECT_REPO}/main/extract}"

DEFAULT_INSTALL_DIR="${HOME}/.local/bin"
INSTALL_DIR=""
EXPLICIT_INSTALL_DIR="0"
ENABLE_GLOBAL_LINK="1"
GLOBAL_LINK_DIR=""
ENABLE_AUTO_UPDATE="1"
QUIET="0"

TARGET=""
DOWNLOAD_FILE=""
STAGED_FILE=""
BACKUP_FILE=""
RESTORE_MODE="none"

if [[ -t 1 ]]; then
  CLR_RESET="\033[0m"
  CLR_DIM="\033[2m"
  CLR_BLUE="\033[34m"
  CLR_GREEN="\033[32m"
  CLR_YELLOW="\033[33m"
  CLR_RED="\033[31m"
else
  CLR_RESET=""
  CLR_DIM=""
  CLR_BLUE=""
  CLR_GREEN=""
  CLR_YELLOW=""
  CLR_RED=""
fi

usage() {
  cat <<EOF
Usage: install.sh [options]

Options:
  --install-dir <path>   Explicit installation directory
  --global-link-dir <p>  Directory for global 'extract' command shim/symlink
  --no-global-link       Do not create shim/symlink in PATH directories
  --auto-update          Keep default auto-update behavior (default)
  --no-auto-update       Print guidance for disabling auto-update in config
  --quiet                Reduce non-error output
  -h, --help             Show this help message
EOF
}

logo() {
  cat <<'EOF'
 ██████╗ ███╗   ███╗███╗   ██╗██╗      ███████╗██╗  ██╗████████╗██████╗  █████╗  ██████╗████████╗
██╔═══██╗████╗ ████║████╗  ██║██║      ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
██║   ██║██╔████╔██║██╔██╗ ██║██║█████╗█████╗   ╚███╔╝    ██║   ██████╔╝███████║██║        ██║   
██║   ██║██║╚██╔╝██║██║╚██╗██║██║╚════╝██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║██║        ██║   
╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║      ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║╚██████╗   ██║   
 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝      ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  
EOF
}

info() {
  if [[ "${QUIET}" == "1" ]]; then
    return 0
  fi
  printf "%b[i]%b %s\n" "${CLR_BLUE}" "${CLR_RESET}" "$1"
}

ok() {
  if [[ "${QUIET}" == "1" ]]; then
    return 0
  fi
  printf "%b[ok]%b %s\n" "${CLR_GREEN}" "${CLR_RESET}" "$1"
}

warn() {
  printf "%b[warn]%b %s\n" "${CLR_YELLOW}" "${CLR_RESET}" "$1"
}

die() {
  printf "%b[error]%b %s\n" "${CLR_RED}" "${CLR_RESET}" "$1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

path_has_dir() {
  local needle="$1"
  local part
  IFS=':' read -r -a path_parts <<< "${PATH:-}"
  for part in "${path_parts[@]}"; do
    if [[ -n "${part}" && "${part}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

first_writable_path_dir() {
  local part
  IFS=':' read -r -a path_parts <<< "${PATH:-}"
  for part in "${path_parts[@]}"; do
    if [[ -z "${part}" || "${part}" == "." ]]; then
      continue
    fi
    if [[ -d "${part}" && -w "${part}" && -x "${part}" ]]; then
      printf "%s\n" "${part}"
      return 0
    fi
  done
  return 1
}

resolve_install_dir() {
  if [[ "${EXPLICIT_INSTALL_DIR}" == "1" ]]; then
    printf "%s\n" "${INSTALL_DIR}"
    return 0
  fi

  if path_has_dir "${DEFAULT_INSTALL_DIR}"; then
    printf "%s\n" "${DEFAULT_INSTALL_DIR}"
    return 0
  fi

  local existing
  existing="$(command -v extract || true)"
  if [[ -n "${existing}" ]]; then
    local existing_dir
    existing_dir="$(dirname "${existing}")"
    if [[ -d "${existing_dir}" && -w "${existing_dir}" ]]; then
      printf "%s\n" "${existing_dir}"
      return 0
    fi
  fi

  local writable_path
  writable_path="$(first_writable_path_dir || true)"
  if [[ -n "${writable_path}" ]]; then
    printf "%s\n" "${writable_path}"
    return 0
  fi

  printf "%s\n" "${DEFAULT_INSTALL_DIR}"
  return 0
}

cleanup() {
  local status=$?

  if [[ ${status} -ne 0 ]]; then
    if [[ "${RESTORE_MODE}" == "replace" && -n "${BACKUP_FILE}" && -f "${BACKUP_FILE}" && -n "${TARGET}" ]]; then
      cp "${BACKUP_FILE}" "${TARGET}" || true
      chmod 0755 "${TARGET}" || true
      warn "Recovered previous extract binary after failed install"
    elif [[ "${RESTORE_MODE}" == "remove" && -n "${TARGET}" ]]; then
      rm -f "${TARGET}" || true
    fi
  fi

  if [[ -n "${DOWNLOAD_FILE}" && -f "${DOWNLOAD_FILE}" ]]; then
    rm -f "${DOWNLOAD_FILE}" || true
  fi
  if [[ -n "${STAGED_FILE}" && -f "${STAGED_FILE}" ]]; then
    rm -f "${STAGED_FILE}" || true
  fi
  if [[ -n "${BACKUP_FILE}" && -f "${BACKUP_FILE}" ]]; then
    rm -f "${BACKUP_FILE}" || true
  fi

  return ${status}
}

download_extract() {
  local destination="$1"
  if command -v curl >/dev/null 2>&1; then
    if [[ "${QUIET}" == "1" ]]; then
      curl --silent --fail --show-error --location --connect-timeout 10 --retry 3 --retry-delay 1 --retry-connrefused "${SOURCE_URL}" -o "${destination}"
    else
      curl --fail --show-error --location --connect-timeout 10 --retry 3 --retry-delay 1 --retry-connrefused "${SOURCE_URL}" -o "${destination}"
    fi
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    if [[ "${QUIET}" == "1" ]]; then
      wget -q -O "${destination}" "${SOURCE_URL}"
    else
      wget -O "${destination}" "${SOURCE_URL}"
    fi
    return 0
  fi

  die "neither curl nor wget is available for downloading extract"
}

validate_payload() {
  local file_path="$1"
  local first_line
  first_line="$(head -n 1 "${file_path}" || true)"
  [[ "${first_line}" == "#!/usr/bin/env python3" ]] || die "downloaded file failed shebang validation"
  grep -q '^VERSION = ' "${file_path}" || die "downloaded file missing VERSION metadata"
  grep -q '^def main(' "${file_path}" || die "downloaded file missing entrypoint"
  python3 -m py_compile "${file_path}" >/dev/null 2>&1 || die "downloaded file failed Python syntax validation"
}

verify_executable() {
  local file_path="$1"
  OMNI_EXTRACT_NO_AUTO_UPDATE=1 "${file_path}" --version >/dev/null 2>&1
}

ensure_global_access() {
  local installed_path="$1"
  local install_dir="$2"

  if path_has_dir "${install_dir}"; then
    ok "${install_dir} is in PATH; 'extract' is globally runnable"
    return 0
  fi

  if [[ "${ENABLE_GLOBAL_LINK}" != "1" ]]; then
    warn "${install_dir} is not in PATH"
    printf "Add this line to your shell profile:\n"
    printf "  export PATH=\"%s:\$PATH\"\n" "${install_dir}"
    return 0
  fi

  local link_dir="${GLOBAL_LINK_DIR}"
  if [[ -z "${link_dir}" ]]; then
    link_dir="$(first_writable_path_dir || true)"
  fi

  if [[ -n "${link_dir}" ]]; then
    mkdir -p "${link_dir}"
    local shim_path="${link_dir}/extract"

    if ln -sfn "${installed_path}" "${shim_path}" 2>/dev/null; then
      if verify_executable "${shim_path}"; then
        ok "Linked 'extract' into ${link_dir} for global command access"
        return 0
      fi
    fi

    cp "${installed_path}" "${shim_path}"
    chmod 0755 "${shim_path}"
    if verify_executable "${shim_path}"; then
      ok "Installed command shim to ${shim_path} for global access"
      return 0
    fi
  fi

  warn "Could not auto-link into a PATH directory"
  warn "Add ${install_dir} to PATH to run 'extract' globally"
  printf "Add this line to your shell profile:\n"
  printf "  export PATH=\"%s:\$PATH\"\n" "${install_dir}"
  return 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      [[ $# -ge 2 ]] || die "--install-dir expects a value"
      INSTALL_DIR="$2"
      EXPLICIT_INSTALL_DIR="1"
      shift 2
      ;;
    --global-link-dir)
      [[ $# -ge 2 ]] || die "--global-link-dir expects a value"
      GLOBAL_LINK_DIR="$2"
      shift 2
      ;;
    --no-global-link)
      ENABLE_GLOBAL_LINK="0"
      shift
      ;;
    --auto-update)
      ENABLE_AUTO_UPDATE="1"
      shift
      ;;
    --no-auto-update)
      ENABLE_AUTO_UPDATE="0"
      shift
      ;;
    --quiet)
      QUIET="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

trap cleanup EXIT

require_cmd mkdir
require_cmd mktemp
require_cmd chmod
require_cmd cp
require_cmd mv
require_cmd grep
require_cmd head
require_cmd python3

if [[ "${QUIET}" != "1" ]]; then
  printf "%b" "${CLR_BLUE}"
  logo
  printf "%b" "${CLR_RESET}"
  printf "%b%s%b\n" "${CLR_DIM}" "omni-extract installer" "${CLR_RESET}"
fi

INSTALL_DIR="$(resolve_install_dir)"
TARGET="${INSTALL_DIR}/extract"

info "Installing into ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

DOWNLOAD_FILE="$(mktemp "${TMPDIR:-/tmp}/extract.download.XXXXXX")"
info "Downloading extract from ${SOURCE_URL}"
download_extract "${DOWNLOAD_FILE}"
validate_payload "${DOWNLOAD_FILE}"

STAGED_FILE="$(mktemp "${INSTALL_DIR}/.extract.staged.XXXXXX")"
cp "${DOWNLOAD_FILE}" "${STAGED_FILE}"
chmod 0755 "${STAGED_FILE}"
verify_executable "${STAGED_FILE}" || die "staged extract binary failed execution check"

if [[ -f "${TARGET}" ]]; then
  BACKUP_FILE="$(mktemp "${TMPDIR:-/tmp}/extract.backup.XXXXXX")"
  cp "${TARGET}" "${BACKUP_FILE}"
  RESTORE_MODE="replace"
  info "Backed up existing extract binary"
else
  RESTORE_MODE="remove"
fi

mv "${STAGED_FILE}" "${TARGET}"
STAGED_FILE=""
chmod 0755 "${TARGET}"
verify_executable "${TARGET}" || die "installed extract failed execution check"

RESTORE_MODE="none"

ok "Installed extract to ${TARGET}"
ensure_global_access "${TARGET}" "${INSTALL_DIR}"

if [[ "${ENABLE_AUTO_UPDATE}" == "1" ]]; then
  info "Auto-update is controlled per project via config.yaml (auto_update: true/false)"
else
  info "Auto-update disable requested. Set auto_update: false in project config.yaml"
fi

printf "%bDone.%b Run: %sextract .%s\n" "${CLR_GREEN}" "${CLR_RESET}" "${CLR_BLUE}" "${CLR_RESET}"
