#!/usr/bin/env bash

### Variables Settings and hashmaps to run everything

check_http_ports=( 80 1080 2080 3080 4080 5080 6080 7080 8080 9080 )
check_https_ports=( 443 1443 2442 3443 4334 5443 6443 7443 8443 9443 )

# colors

BOLD="$(tput bold 2>/dev/null || printf '')"
GREY="$(tput setaf 0 2>/dev/null || printf '')"
UNDERLINE="$(tput smul 2>/dev/null || printf '')"
RED="$(tput setaf 1 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
BLUE="$(tput setaf 4 2>/dev/null || printf '')"
MAGENTA="$(tput setaf 5 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"

# color output functions
info() {
  printf ' %s\n' "${BOLD}${GREY}>${NO_COLOR} $*"
}

greet() {
  printf ' %s\n' "${BOLD}${MAGENTA}${NO_COLOR} $*"
}

warn() {
  printf ' %s\n' "${YELLOW}! $*${NO_COLOR}"
}

error() {
  printf ' %s\n' "${RED}x $*${NO_COLOR}" >&2
}

allgood() {
  printf ' %s\n' "${GREEN}✓${NO_COLOR} $*"
}

# adaptation of if you really wanna do this "yes" or --yes flag
confirm() {
  if [ -z "${FORCE-}" ]; then
    printf " %s " "${MAGENTA}?${NO_COLOR} $* ${BOLD}[y/N]${NO_COLOR}"
    set +e
    read -r yn </dev/tty
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      error "Error reading from prompt (please re-run with the '--yes' option)"
      exit 1
    fi
    if [ "$yn" != "y" ] && [ "$yn" != "yes" ]; then
      error 'Aborting (please answer "yes" or "y" to continue)'
      exit 1
    fi
  fi
}

# command found
has() {
  command -v "$1" 1>/dev/null 2>&1
}


# verbose redirecting for normal users commands
cmd() {
  if [ -z ${VERBOSE+x} ]; then
    CMD="$1 >/dev/null 2>&1"
    bash -c "${CMD}"
  else
    CMD="$1"
    warn "========================================================================================="
    warn "command executed: ${CMD}"
    bash -c "${CMD}"
    warn "========================================================================================="
  fi
}

# wannt to hide the verbose output on install only exposing it when needed
sudo_cmd() {
  if [ -z ${VERBOSE+x} ]; then
    CMD="$1 >/dev/null 2>&1"
    sudo --  bash -c "${CMD}"
  else
    CMD="$1"
    warn "========================================================================================="
    warn "command executed: ${CMD}"
    sudo --  bash -c "${CMD}"
    warn "========================================================================================="
  fi
}

welcome() {

  printf '\n'
  greet "████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
  greet "████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████"
  greet "██████                                                                                                                    ██████"
  greet "██████                                                                                                                    ██████"
  greet "██████     ██████████████████████     ███████████████████████      ██████████████████████     ███████████████████████     ██████"
  greet "██████     ██████████████████████     ███████████████████████      ██████████████████████     ███████████████████████     ██████"
  greet "██████     █████            █████     █████             █████      █████                      █████             █████     ██████"
  greet "██████     █████      ▄▄▄████████     █████             █████      ██████████████████████     █████             █████     ██████"
  greet "██████     █████▄▄▄█████████▀▀▀       ███████████████████████      ██████████████████████     ███████████████████████     ██████"
  greet "██████     ████████████████▄          ███████████████████████                       █████     ███████████████████████     ██████"
  greet "██████     █████▀▀▀   ▀██████▄        █████             █████      ██████████████████████     █████             █████     ██████"
  greet "██████     █████        ▀██████▄      █████             █████      ██████████████████████     █████             █████     ██████"
  greet "██████                                                                                                                    ██████"
  greet "██████                                                                                                                    ██████"
  greet "███████████████████████████████████████████████████████████████████████████████████████████████                █████████████████"
  greet "████████████████████████████████████████████████████████████████████████████████████████████████████           █████████████████"
  greet "                                                                                           ███████████████     ██████"
  greet "                                                                                                 ████████████████████"
  greet "                                                                                                       ██████████████"
  greet "                                                                                                             ████████"
  greet "                                                                                                                  ▀██"
  greet "                                                                                                                   ▀▀"
  printf '\n'
  info "Welcome to RASA Ephemeral Installer [REI]"
  printf '\n'

}

check_set_arch() {

    arch=$(uname -m)

    case $arch in
        amd64)
            arch=amd64
            ;;
        x86_64)
            arch=amd64
            ;;
        arm64)
            arch=arm64
            ;;
        *)
            error "Unsupported architecture $ARCH"
    esac

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	    platform="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
	    platform="darwin"
    fi

}

#check what Linux distribution we are running
check_linux_distribution() {

    kernel=$(uname -r)
    if [ -n "$(command -v lsb_release)" ]; then
    	local distroname=$(lsb_release -s -d)
    elif [ -f "/etc/os-release" ]; then
    	local distroname=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="')
    elif [ -f "/etc/debian_version" ]; then
    	local distroname="Debian $(cat /etc/debian_version)"
    elif [ -f "/etc/redhat-release" ]; then
    	local distroname=$(cat /etc/redhat-release)
    else
    	local distroname="$(uname -s) $(uname -r)"
    fi

    allgood "$distroname"

}

# MacOS Installation
# check if the binaries we need are around otherwise install them
check_install_macos() {

# check if homebrew is installed

  if has brew; then
    allgood "found homebrew"
  else
    error "cannot find homebrew which is required for installing RASA OSS / RASA X via REI"
    error "please follow this link for installation -> https://brew.sh/"
    exit 1
  fi

# Docker installation
  if has docker; then
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then

      open /Applications/Docker.app
      error "Docker Desktop is not running please check for the Docker Desktop GUI window and start it and re-run rsi.sh"
      exit 1
    fi

  else
    warn "cannot find docker - installing..."
    confirm "installing Docker Desktop via homebrew"

    # Installing docker via homebrew
    cmd "brew install --cask docker"

    allgood "installed Docker Desktop and opening it"

    # check if docker is running otherwise start it and wait till its running
    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "Docker Desktop isn't running - i have opened it for your please start it via GUI"
      open /Applications/Docker.app
      while [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; do
        warn "Waiting for Docker to launch..."
        sleep 1
      done
    fi

  fi

  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl - installing..."
    confirm "- installing kubectl via homebrew"
    # Installing docker via homebrew
    cmd "brew install kubectl"
    allgood "installed kubectl"
  fi

  # kubectl installation
  if has helm; then
    allgood "found helm"
  else
     warn "cannot find helm - installing..."
     confirm "installing helm via homebrew"
     # Installing docker via homebrew
     cmd "brew install helm"
     allgood "installed helm"
  fi

  # kubectl installation
  if has kind; then
    allgood "found kind"
  else
     warn "cannot find kind - installing..."
     confirm "installing kind via homebrew"
     # Installing docker via homebrew
     cmd "brew install kind"
     allgood "installed kind"
  fi

  install_rasactl

  set_dns_rasactl_localhost_macos

  kind_finalize_rasax

}

check_install_fedora() {
  check_sudo

# curl installation
  if has curl; then
    allgood "found curl"
  else
    warn "cannot find curl - installing..."
    confirm "installing curl via yum"
    sudo_cmd "yum install curl -y"
    allgood "installed curl"
  fi


# Docker installation
  if has docker; then
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "docker daemon isn't running"
      confirm "starting docker daemon via systemctl"
      sudo_cmd "systemctl start docker.service"
      sudo_cmd "systemctl start docker.socket"
    fi

  else
    warn "cannot find docker - installing..."
    confirm "installing docker via yum"
    # Installing docker via apt
    sudo_cmd "yum install docker -y"
    allgood "installed docker"

    # yeah chicken and egg - if docker is fresh installed we need to completly reload the users session. Logout / Login or reboot
    confirm "adding $USER to group docker to access docker via your user"
    sudo_cmd "gpasswd -a $USER docker"
    cmd "getent group docker"
    error "${BOLD}Please ${RED}REBOOT${NO_COLOR} your system !"
    error "Since this is the first installation of docker the rights for docker and your user need to be updated"
    error "run the RSI script afterwards again to continue the installation"
    exit 1

  fi

  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl - installing..."
    confirm "installing kubebctl via yum"

    sudo_cmd "yum install kubernetes-client -y"

    allgood "installed kubectl"
  fi

  # helm installation
  if has helm; then
    allgood "found helm"
  else
    warn "cannot find helm - installing..."
    if has openssl; then
      allgood "found openssl for helm installation"
    else
      confirm "installing openssl via yum - required for installation of helm"

      sudo_cmd "yum install openssl -y"
    
      allgood "installed openssl"
    fi

    confirm "installing helm via offical helm installer"

    cmd "curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3"
    cmd "bash /tmp/get_helm.sh"

    allgood "installed helm"
  fi

  # kind installation
  if has kind; then
    allgood "found kind"
  else
    warn "cannot find kind - installing..."
    confirm "installing kind via binary download"

    cmd "curl -Lo /tmp/kind-bin-download https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64"
    cmd "chmod +x /tmp/kind-bin-download"
    sudo_cmd "mv /tmp/kind-bin-download /usr/local/bin/kind"

    allgood "installed kind"

  fi

  install_rasactl

  set_dns_rasactl_localhost_linux

  kind_finalize_rasax

}

check_install_ubuntu() {
  check_sudo

# curl installation
  if has curl; then
    allgood "found curl"
  else
    warn "cannot find curl - installing..."
    confirm "installing curl via apt"
    sudo_cmd "apt-get install curl --yes"
    allgood "installed curl"
  fi


# Docker installation
  if has docker; then
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "docker daemon isn't running"
      confirm "starting docker daemon via systemctl"
      sudo_cmd "systemctl start docker.service"
      sudo_cmd "systemctl start docker.socket"
    fi

  else
    warn "cannot find docker - installing..."
    confirm "installing docker via apt"
    # Installing docker via apt
    sudo_cmd "apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common --yes"
    sudo_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -"
    sudo_cmd 'add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"'
    sudo_cmd "apt-get update"
    sudo_cmd "apt-get install docker-ce docker-ce-cli containerd.io --yes"
    allgood "installed docker"

    # yeah chicken and egg - if docker is fresh installed we need to completly reload the users session. Logout / Login or reboot
    confirm "adding $USER to group docker to access docker via your user"
    sudo_cmd "gpasswd -a $USER docker"
    cmd "getent group docker"
    error "${BOLD}Please ${RED}REBOOT${NO_COLOR} your system !"
    error "Since this is the first installation of docker the rights for docker and your user need to be updated"
    error "run the RSI script afterwards again to continue the installation"
    exit 1

  fi

  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl - installing..."
    confirm "installing kubebctl via apt"

    sudo_cmd "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"
    sudo_cmd 'add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"'
    sudo_cmd "apt update"
    sudo_cmd "apt install kubectl --yes"

    allgood "installed kubectl"
  fi

  # helm installation
  if has helm; then
    allgood "found helm"
  else
    warn "cannot find helm - installing..."
    confirm "installing helm via apt"

    sudo_cmd "curl -s https://baltocdn.com/helm/signing.asc | apt-key add -"
    sudo_cmd "apt-get install apt-transport-https --yes"
    sudo_cmd "echo 'deb https://baltocdn.com/helm/stable/debian/ all main' | tee /etc/apt/sources.list.d/helm-stable-debian.list"
    sudo_cmd "apt-get update"
    sudo_cmd "apt-get install helm --yes"
    allgood "installed helm"
  fi

  # kind installation
  if has kind; then
    allgood "found kind"
  else
    warn "cannot find kind - installing..."
    confirm "installing kind via binary download"

    cmd "curl -Lo /tmp/kind-bin-download https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64"
    cmd "chmod +x /tmp/kind-bin-download"
    sudo_cmd "mv /tmp/kind-bin-download /usr/local/bin/kind"

    allgood "installed kind"

  fi

  install_rasactl

  set_dns_rasactl_localhost_linux

  kind_finalize_rasax

}

check_install_arch() {
  # check_sudo

# Docker installation
  if has docker; then
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "docker daemon isn't running"
      confirm "starting docker daemon via systemctl"
      sudo_cmd "sudo systemctl start docker.service"
      sudo_cmd "sudo systemctl start docker.socket"
    fi

  else
    warn "cannot find docker - installing..."
    confirm "installing docker via pacman"

    sudo_cmd "pacman -S docker --noconfirm"

    allgood "installed docker"

    # yeah chicken and egg - if docker is fresh installed we need to completly reload the users session. Logout / Login or reboot
    confirm "adding $USER to group docker to access docker via your user"
    sudo_cmd "sudo gpasswd -a $USER docker"
    cmd "getent group docker"

    error "${BOLD}Please ${RED}REBOOT${NO_COLOR} your system !"
    error "Since this is the first installation of docker the rights for docker and your user need to be updated"
    error "run the RSI script afterwards again to continue the installation"
    exit 1

  fi

  # curl installation
  if has curl; then
    allgood "found curl"
  else
    warn "cannot find curl - installing..."
    confirm "installing curl via pacman"
    sudo_cmd "pacman -S curl --noconfirm"
    allgood "installed curl"
  fi

  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl - installing..."
    confirm "installing kubebctl via pacman"
    sudo_cmd "pacman -S kubectl --noconfirm"
    allgood "installed kubectl"
  fi

  # helm installation
  if has helm; then
    allgood "found helm"
  else
    warn "cannot find helm - installing..."
    confirm "installing helm via pacman"
    sudo_cmd "pacman -S helm --noconfirm"
    allgood "installed helm"
  fi

  # kind installation
  if has kind; then
    allgood "found kind"
  else
    warn "cannot find kind - installing..."
    confirm "installing kind via binary download"

    cmd "curl -Lo /tmp/kind-bin-download https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64"
    cmd "chmod +x /tmp/kind-bin-download"
    cmd "sudo mv /tmp/kind-bin-download /usr/local/bin/kind"

    allgood "installed kind"
  fi

  install_rasactl

  kind_finalize_rasax

}

# Check what OS we are running on
check_os_install_kind()
{
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # check what Linux distribution we are running
        distribution="$(check_linux_distribution)"

        # found manjaro OS
        if [[ "${distribution}" =~ "Manjaro" ]]; then
           preflight_check
           info "Detecting OS..."
           allgood "found ${distribution}"
           check_install_arch
        elif [[ "${distribution}" =~ "Fedora" ]]; then
           preflight_check
           info "Detecting OS..."
           allgood "found ${distribution}"
           check_install_fedora
        elif [[ "${distribution}" =~ "Ubuntu" ]]; then
           preflight_check
           info "Detecting OS..."
           allgood "found ${distribution}"
           check_install_ubuntu
        else
           info "Detecting OS..."
           info "${distribution}"
           error "unknown distribution"
           exit 1
        fi

    # Detecting OS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        preflight_check
        info "Detecting OS..."
        macos_version=`sw_vers -productVersion`
        allgood "MacOS ${macos_version}"
        distribution="macOS"

        check_install_macos
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        allgood "Windows"
        error "not implemented... yet "
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        allgood "Windows"
        error "not implemented... yet "
    elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
        allgood "Windows"
        error "not implemented... yet "
    else
        # Unknown.
        error "Unknown Platform :["
	      exit 1
    fi
}

set_dns_rasactl_localhost_macos() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ ! -e "/etc/resolver/rasactl.localhost" ]]; then
      warn "Missing DNS resolver configuration for rasactl.localhost domain - configuring..."
      confirm "Add DNS resolver for rasactl.localhost domain"
      check_sudo
      if [[ ! -d "/etc/resolver" ]]; then
        sudo_cmd "mkdir /etc/resolver"
      fi

      sudo_cmd "cat > /etc/resolver/rasactl.localhost<< EOF
search rasactl.localhost
nameserver 127.0.0.1
options ndots:1
timeout 2
EOF
"
      allgood "DNS resolver configuration is ready"
    fi

    run_docker_coredns
  fi
}

set_dns_rasactl_localhost_linux() {
  IS_SYSTEMD_RESOLVED_ACTIVE=$(systemctl is-active systemd-resolved || true)
  if [[ "$OSTYPE" == "linux-gnu"* && "${IS_SYSTEMD_RESOLVED_ACTIVE}" != "active" ]]; then
    run_docker_coredns
  fi
}

run_docker_coredns() {
  IS_CORE_DNS_EXIST=$(sudo docker ps --all --filter name=rasactl_coredns | grep -c rasactl_coredns || true)
  if [[ ${IS_CORE_DNS_EXIST} -eq 0 ]]; then
    warn "CoreDNS container is not running - launching..."
    sudo_cmd "docker run --restart unless-stopped --name rasactl_coredns -d  -p 127.0.0.1:53:53/udp rasa/rasactl:coredns-1.8.5"
  fi

  IS_CORE_DNS_UP=$(sudo docker ps --all --filter name=rasactl_coredns --filter status=running --no-trunc --format "{{.ID}} {{.Status}}" | grep -c Up || true)
  if [[ ${IS_CORE_DNS_UP} -eq 0 ]]; then
    warn "CoreDNS container is not running - launching..."
    sudo_cmd "docker start rasactl_coredns"
  fi

  allgood "CoreDNS container is up"
}

# Check for sudo rights - required
check_sudo() {

  info "To install and configure everything for you under ${distribution} we need sudo rights"
  info "this script will handover all to sudo and not save your password"

  if ! has sudo; then
    error 'Could not find the command "sudo", needed to get permissions for install.'
    info "If you are on Windows, please run your shell as an administrator, then"
    info "rerun this script. Otherwise, please run this script as root, or install"
    info "sudo."
    exit 1
  fi
  if ! sudo -v; then
    error "Superuser not granted, aborting installation"
    exit 1
  fi
}

preflight_check() {

    allgood "Preflight check..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      freemem=`free -g | awk '/^Mem:/{print $2}'`
      freedisk=`df --block-size=1G --output=avail "$PWD" | tail -n1`
      openports=`sudo lsof -nP -iTCP -sTCP:LISTEN`
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      fmem=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
      inmem=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
      specmem=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
      freemem=$((($fmem+specmem)*4096/1048576))
      inactive=$(($inmem*4096/1048576))
      total=$((($freemem+$inactive)))
      freedisk=`df -g | awk ' { print $4, " ", $9 } ' |grep "\/$" | awk ' { print $1 }'`
      openports=`lsof -nP -iTCP -sTCP:LISTEN`
    fi

    if [[ $freedisk -lt 20 ]]; then
       error "We have only ${freedisk} GB of Free Disk which is not enough to Run RASA X / RASA OSS"
       error "Please free at least 8 GB of local disk and run the script again"
       exit 1
    fi;

    if [[ $freemem -lt 6 ]]; then
       error "We have only ${freemem} GB of Free Memory which is not enough to Run RASA X / RASA OSS"
       error "Please free at least 8 GB of local memory and run the script again"
       exit 1
    fi;

    info "checking KIND ports to avoid collisons on binding to interface..."
    while [[ -z "${HTTPPORT}" ]] ; do
      for chttp in "${check_http_ports[@]}"
      do
        if [[ $openports =~ ":${chttp} (LISTEN)" ]]; then
          warn "port ${chttp} is used - checking other ports..."
        else
          HTTPPORT=${chttp}
          info "port ${HTTPPORT} is free - using it"
          break
        fi
      done
    done

    while [[ -n "${HTTPPORT}"&& -z "${HTTPSPORT}" ]] ; do

      for chttps in "${check_https_ports[@]}"
      do
        if [[ $openports =~ ":${chttps} (LISTEN)" ]]; then
          warn "port ${chttps} is used - checking other ports..."
        else
          HTTPSPORT=${chttps}
          info "port ${HTTPSPORT} is free - using it"
          break
        fi
      done
    done

  allgood "Free Memory: ${GREEN}${freemem} GB ${NO_COLOR}"
  allgood "Free Diskspace: ${GREEN}${freedisk} GB ${NO_COLOR}"
}


# TODO: when rasactl repo is public change logic with versioning and querying GITHUB api endpoint for latest release
# also sha256 check
install_rasactl() {

  RASACTL_BASE_URL="https://github.com/RasaHQ/rasactl/releases/download/${latest_tag}/"
  RASACTL_URL="${RASACTL_BASE_URL}rasactl_${latest_tag}_${platform}_${arch}.tar.gz"

  if has rasactl; then
    allgood "found rasactl"
  else
    warn "cannot find rasactl - installing..."
    confirm "installing rasactl via binary download"

    cmd "curl -o /tmp/rasactl.tar.gz -sfL ${RASACTL_URL}"
    cmd "tar xfvz /tmp/rasactl.tar.gz -C /tmp/"
    cmd "chmod +x /tmp/rasactl_${latest_tag}_${platform}_${arch}/rasactl"
    sudo_cmd "mv /tmp/rasactl_${latest_tag}_${platform}_${arch}/rasactl /usr/local/bin/rasactl"
    cmd "cd /tmp && rm -Rf rasactl_${latest_tag}_${platform}_${arch} && rm rasactl.tar.gz && cd -"

    allgood "installed rasactl"
  fi

}

wait_for_deployment() {
  # need to wait for a moment on kubernetes
  sleep 60

  i=0
  tput sc
  while [[ $(kubectl -n rasa get pods -l app.kubernetes.io/name=rasa-x -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') =~ "False" ]] ; do
    case $(($i % 10)) in
        0 ) j="▁" ;;
			  1 ) j="▃" ;;
			  2 ) j="▄" ;;
        3 ) j="▅" ;;
			  4 ) j="▆" ;;
			  5 ) j="▇" ;;
			  6 ) j="▆" ;;
			  7 ) j="▅" ;;
			  8 ) j="▄" ;;
			  9 ) j="▃" ;;
    esac
    tput rc
    echo -en " \r[$j] Waiting for other Helm deployment to finish..."
    sleep 0.5
    ((i=i+1))
  done

}

wait_for_kind() {
  # need to wait for a moment on kubernetes
  sleep 60

  i=0
  tput sc
  while [[ $(kubectl -n kube-system get pods -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') =~ "False" ]] ; do
    case $(($i % 10)) in
        0 ) j="▁" ;;
			  1 ) j="▃" ;;
			  2 ) j="▄" ;;
        3 ) j="▅" ;;
			  4 ) j="▆" ;;
			  5 ) j="▇" ;;
			  6 ) j="▆" ;;
			  7 ) j="▅" ;;
			  8 ) j="▄" ;;
			  9 ) j="▃" ;;
    esac
    tput rc
    echo -en " \r[$j] Waiting for KIND Cluster to be ready..."
    sleep 0.5
    ((i=i+1))
  done

}

# check fot the latest rasactl version and put it into LATESTTAG variable
check_rasactl_latest() {
    # Get tag from release URL
    local latest_release_url="https://github.com/RasaHQ/rasactl/releases"
    latest_tag=$(curl -Ls https://api.github.com/repos/RasaHQ/rasactl/releases | grep tag_name | grep -E '[0-9]\.[0-9]\.[0-9]+\"\,$' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
}

# finalize with helm at end
kind_finalize_rasax() {

  if [ -z ${RASAX_INSTALL+x} ]; then

    info "Creating KIND RASA Cluster"
    info "This will take some minutes..."

    render_kind_config

    cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
    cmd "rm /tmp/kind-rasa-config.yaml"

    allgood "KIND RASA cluster creation finished"

    wait_for_kind

    cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml"
    cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

    info "================================================================================="
    info "you can now your rasactl to kickstart a local rasax installation run"
    info "kubectl cluster-info --context kind-rasa"
    info "sudo rasactl start rasa-x --kubeconfig ${HOME}/.kube/config"
    info ""
    info "More examples you can find by executing the 'rasactl help start' command."
    info "To learn more about rasactl visit:"
    info "- https://github.com/RasaHQ/rasactl/"
    info "- https://rasa.com/docs/rasa-x/installation-and-setup/install/rasa-ephemeral-installer/introduction"
    info "================================================================================="
    exit 0

  else

      if [[ `kind get clusters |grep rasa` ]] &>/dev/null; then

      info "found RASA KIND cluster"
      info "checking if KIND cluster is ready..."

      wait_for_kind

      cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/f3c50698d98299b1a61f83cb6c4bb7de0b71fb4b/deploy/static/provider/kind/deploy.yaml"
      cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

      warn "switching kubectl context to: kind-rasa"
      warn "========================================="
      warn "kubectl cluster-info --context kind-rasa"
      warn "========================================="

      cmd "kubectl cluster-info --context kind-rasa"

      sudo rasactl start rasa-x --kubeconfig ${HOME}/.kube/config


    else
      info "Creating KIND RASA Cluster"
      info "This will take some minutes..."

      render_kind_config

      cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
      cmd "rm /tmp/kind-rasa-config.yaml"

      allgood "KIND RASA cluster creation finished"
      wait_for_kind

      cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/f3c50698d98299b1a61f83cb6c4bb7de0b71fb4b/deploy/static/provider/kind/deploy.yaml"
      cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

      warn "switching kubectl context to: kind-rasa"
      warn "========================================="
      warn "kubectl cluster-info --context kind-rasa"
      warn "========================================="

      sudo rasactl start rasa-x --kubeconfig ${HOME}/.kube/config

      warn "Bugs / Improvements / Features : https://github.com/RasaHQ/RSI/issues/new?labels=bug&assignees=RASADSA"
    fi

  fi

}

# finalize with rasaxctl at end
# TODO: rasaxctl binary download
kind_finalize_rasactl() {

  info "Creating KIND RASA Cluster"

  render_kind_config

  cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
  cmd "rm /tmp/kind-rasa-config.yaml"
  allgood "KIND RASA cluster creation finished"
  cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml"
  cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

  warn "==================================================================="
  warn "${BOLD}Installing RASAX Offical Helmchart to local RASA KIND Cluster"
  warn "${BOLD}This will take around 8-10 minutes - time to make a coffe or tea =]"
  warn "===================================================================="

  sudo rasactl start rasa-x

}

uninstall() {

  info "Deleting RSI Cluster"
  cmd "kind delete clusters rasa"
  allgood "KIND RASA cluster deleted"
  exit 1

}

# render KIND yaml cluster config ports found by preflight
render_kind_config() {

cat > /tmp/kind-rasa-config.yaml<< EOF
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        service-node-port-range: "30000-30100"
  extraPortMappings:
  - containerPort: 80
    hostPort: $HTTPPORT
    protocol: TCP
  - containerPort: 443
    hostPort: $HTTPSPORT
    protocol: TCP
EOF
for x in {30000..30100}; do
echo "  - containerPort: $x
    hostPort: $x
    protocol: TCP" >> /tmp/kind-rasa-config.yaml
done

}


# cli help page
usage() {
    cat <<EOT
rsi.sh [option]

Fetch and install the latest version RASAX running with KIND

Options

  -f, -y, --force, --yes
    Skip the confirmation prompt during installation

  -v, --verbose
    Enable verbose output of all running commands

  -h, --help
    Dispays this help message

  -u, --uninstall
    uninstall RASA X / RASA OSS installation

  -x, --invoke-rasactl
    After installation of all binaries runs:
    sudo rasactl start rasa-x --kubeconfig ${HOME}/.kube/config

EOT
}


# parse argv variables
while [ "$#" -gt 0 ]; do
  case "$1" in
  -f | -y | --force | --yes)
    FORCE=1
    shift 1
    ;;
  -v | --verbose)
    VERBOSE=1
    shift 1
    ;;
  -h | --help)
    usage
    exit
    ;;
  -u | --uninstall)
    uninstall
    exit
    ;;
  -x | --invoke-rasactl)
    RASAX_INSTALL=1
    shift 1
    ;;
  -f=* | -y=* | --force=* | --yes=*)
    FORCE="${1#*=}"
    shift 1
    ;;

  *)
    error "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
done

welcome
check_rasactl_latest
check_set_arch
check_os_install_kind
