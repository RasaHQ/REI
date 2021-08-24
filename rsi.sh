#!/usr/bin/env bash

### Variables Settings and hashmaps to run everything

RASACTL_BASE_URL="https://github.com/RasaHQ/rasactl/releases"
RASACTL_URL="${RASACTL_BASE_URL}/latest/download/starship-${TARGET}.${EXT}"

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
  info "Welcome to RASA Simple Installer [RSI]"
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
    error "cannot find homebrew which is required for installing RASA X"
    error "please follow this link for installation -> https://brew.sh/"
    exit 1
  fi

# Docker installation
  if has docker; then
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then

      open /Applications/Docker.app
      warn "Docker Desktop is not running please check for the Docker Desktop GUI window and start it"

    fi

  else
    warn "cannot find docker"
    confirm "installing Docker Desktop via homebrew"

    # Installing docker via homebrew
    brew install --cask docker ${VERBOSE-}

    allgood "installed Docker Desktop and opening it"

    # check if docker is running otherwise start it and wait till its running
    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "Docker Desktop isnt running - i have opened it for your please start it via GUI"
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
    warn "cannot find kubectl - installing it via homebrew"
    confirm "- installing kubectl via homebrew"
    # Installing docker via homebrew
    cmd "brew install kubectl"
    allgood "installed kubectl"
  fi

  # kubectl installation
  if has helm; then
    allgood "found helm"
  else
     warn "cannot find helm - installing it via homebrew"
     confirm "installing helm via homebrew"
     # Installing docker via homebrew
     cmd "brew install helm"
     allgood "installed helm"
  fi      

  # kubectl installation
  if has kind; then
    allgood "found kind"
  else
     warn "cannot find kind"
     confirm "installing kind via homebrew"
     # Installing docker via homebrew
     cmd "brew install kind"
     allgood "installed kind"
  fi      

  kind_finalize_rasax

}

check_install_ubuntu() {
  check_sudo

# Docker installation
  if has docker; then 
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "docker daemmon isnt running"
      confirm "starting docker daemon via systemctl"
      sudo_cmd "systemctl start docker.service"
      sudo_cmd "systemctl start docker.socket"
    fi

  else
    warn "cannot find docker"
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
    error "A relogin to your Desktop session is required that the group rights are loaded. If this doesnt work please reboot"
    error "run the execute the install script afterwards again"
    exit 1
        
  fi
  
  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl"
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
    warn "cannot find helm"
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
    warn "cannot find kind"
    confirm "installing kind via binary download"

    cmd "curl -Lo /tmp/kind-bin-download https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64"
    cmd "chmod +x /tmp/kind-bin-download"
    sudo_cmd "mv /tmp/kind-bin-download /usr/local/bin/kind"

    allgood "installed kind"

  fi    

  kind_finalize_rasax

}

check_install_arch() {
  check_sudo

# Docker installation
  if has docker; then 
    allgood "found docker"

    if [[ ! `docker stats --no-stream |grep "CONTAINER ID"` ]] &>/dev/null; then
      warn "docker daemmon isnt running"
      confirm "starting docker daemon via systemctl"
      sudo_cmd "sudo systemctl start docker.service"
      sudo_cmd "sudo systemctl start docker.socket"
    fi

  else
    warn "cannot find docker"
    confirm "installing docker via pacman"

    sudo_cmd "sudo pacman -S docker --noconfirm"

    allgood "installed docker"

    # yeah chicken and egg - if docker is fresh installed we need to completly reload the users session. Logout / Login or reboot
    confirm "adding $USER to group docker to access docker via your user"
    sudo_cmd "sudo gpasswd -a $USER docker"
    cmd "getent group docker"
    error "A relogin to your Desktop session is required that the group rights are loaded. If this doesnt work please reboot"
    error "run the execute the install script afterwards again"
    exit 1
        
    # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
    #elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
    #    then
    #        sudo apt-get install openjdk-8-jre-headless -y
  fi
  
  # curl installation
  if has curl; then
    allgood "found curl"
  else
    warn "cannot find curl - installing it via apt"
    confirm "installing curl via apt"
    sudo_cmd "sudo pacman -S curl --noconfirm"
    allgood "installed curl"
  fi      

  # kubectl installation
  if has kubectl; then
    allgood "found kubectl"
  else
    warn "cannot find kubectl"
    confirm "installing kubebctl via pacman"
    sudo_cmd "pacman -S kubectl --noconfirm"
    allgood "installed kubectl"
  fi

  # helm installation
  if has helm; then
    allgood "found helm"
  else
    warn "cannot find helm"
    confirm "installing helm via pacman"
    sudo_cmd "sudo pacman -S helm --noconfirm"
    allgood "installed helm"
  fi      

  # kind installation
  if has kind; then
    allgood "found kind"
  else
    warn "cannot find kind"
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
        elif [[ "${distribution}" =~ "CentOS" ]]; then
           preflight_check
           info "Detecting OS..."
           allgood "found ${distribution}"
           warn "not implemented... yet "
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

# Check for sudo rights - required
check_sudo() {

  info "To install everything for you under ${distribution} we need sudo rights"
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

    if [[ $freedisk -lt 30 ]]; then              
       error "We have only ${diskfree} GB of Free Disk which is not enough to Run RASA X / RASA OSS" 
       error "Please free at least 30 GB of local disk and run the script again"
       exit 1
    fi;

    if [[ $freemem -lt 6 ]]; then              
       error "We have only ${freemem} GB of Free Memory which is not enough to Run RASA X / RASA OSS" 
       error "Please free at least 8 GB of local memory and run the script again"
       exit 1
    fi;


    if [[ $openports =~ "*:80 (LISTEN)" ]]; then              
       error "We detected that port 80 is already occupied - please close the application and run the script again"
       exit 1
    elif [[ $openports =~ "*:443 (LISTEN)" ]]; then
       error "We detected that port 443 is already occupied - please close the application and run the script again"
       exit 1
    fi

  allgood "Free Memory: ${GREEN}${freemem} GB ${NO_COLOR}" 
  allgood "Free Diskspace: ${GREEN}${freedisk} GB ${NO_COLOR}" 
}


# TODO: when rasactl repo is public change logic with versioning and querying GITHUB api endpoint for latest release
# also sha256 check
install_rasactl() {

  RASACTL_BASE_URL="https://gist.github.com/RASADSA/51bd3fff20e69731abe8c693aaa87562/raw/a0da15a6cf6839b6480b133d0460d5ad073499ee/"
  RASACTL_URL="${RASACTL_BASE_URL}rasactl_0.0.9_${platform}_${arch}.tar.gz"

  if has rasactl; then
    allgood "found rasactl"
  else
    warn "cannot find rasactl"
    confirm "installing rasactl via binary download"

    cmd "curl -o /tmp/rasactl.tar.gz -sfL ${RASACTL_URL}"
    cmd "tar xfvz /tmp/rasactl.tar.gz -C /tmp/"
    cmd "chmod +x /tmp/rasactl_0.0.9_${platform}_${arch}/rasactl"
    sudo_cmd "mv /tmp/rasactl_0.0.9_${platform}_${arch}/rasactl /usr/local/bin/rasactl"
    cmd "cd /tmp && rm -Rf rasactl_0.0.9_${platform}_${arch} && rm rasactl.tar.gz && cd -"

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
echo "\n"

}

# finalize with helm at end
kind_finalize_rasax() {

  if [ -z ${NO_RASAX_INSTALL+x} ]; then

    if [[ `kind get clusters |grep rasa` ]] &>/dev/null; then

      info "found RASA KIND cluster"

      warn "switching kubectl context to: kind-rasa"
      warn "========================================="
      warn "kubectl cluster-info --context kind-rasa"
      warn "========================================="

      cmd "kubectl cluster-info --context kind-rasa"

      cmd "helm repo add rasa-x https://rasahq.github.io/rasa-x-helm"
      cmd "helm -n rasa upgrade rasa-x --install --create-namespace -f https://gist.githubusercontent.com/RASADSA/32138b62bd97a348db374c87c27d8dc6/raw/90c0ba3564c33739107678163b588d7e0fde5918/values.yaml rasa-x/rasa-x"

      warn "==================================================================="
      warn "${BOLD}Installing RASAX Offical Helmchart to local RASA KIND Cluster"
      warn "${BOLD}This will take around 6-20 minutes - time to make a coffe or tea =]"
      warn "===================================================================="

      wait_for_deployment

      allgood "Helmchart deployed"
      allgood "to start using RASAX please visit ${BOLD}http://localhost/${NOCOLOR} or ${BOLD}https://localhost/${NOCOLOR}"
      allgood "Password: ${BOLD}test${NOCOLOR}"

    else
      info "Creating KIND RASA Cluster"
      info "This will take some minutes..."

      cmd "curl -Lo /tmp/kind-rasa-config.yaml https://raw.githubusercontent.com/RasaHQ/RSI/main/kind/kind-rasa-config.yaml"
      cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
      cmd "rm /tmp/kind-rasa-config.yaml"

      allgood "KIND RASA cluster creation finished"

      warn "switching kubectl context to: kind-rasa"
      warn "========================================="
      warn "kubectl cluster-info --context kind-rasa"
      warn "========================================="

      cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml"
      cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

      cmd "helm repo add rasa-x https://rasahq.github.io/rasa-x-helm"
      cmd "helm -n rasa upgrade rasa-x --install --create-namespace -f https://gist.githubusercontent.com/RASADSA/32138b62bd97a348db374c87c27d8dc6/raw/90c0ba3564c33739107678163b588d7e0fde5918/values.yaml rasa-x/rasa-x"

      warn "================================================================================="
      warn "${BOLD}Installing / Upgrading RASAX Offical Helmchart to local RASA KIND Cluster"
      warn "${BOLD}This will take around 8-10 minutes - time to make a coffe or tea =]"
      warn "================================================================================="

      wait_for_deployment

      allgood "Helmchart deployed"
      allgood "to start using RASAX please visit ${BOLD}http://localhost/${NOCOLOR} or ${BOLD}https://localhost/${NOCOLOR}"
      allgood "Password: ${BOLD}test${NOCOLOR}"

      warn "Bugs / Improvements / Features : https://github.com/RasaHQ/RSI/issues/new?labels=bug&assignees=RASADSA"
    fi

  else
    
    info "Creating KIND RASA Cluster"
    info "This will take some minutes..."

    cmd "curl -Lo /tmp/kind-rasa-config.yaml https://raw.githubusercontent.com/RasaHQ/RSI/main/kind/kind-rasa-config.yaml"
    cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
    cmd "rm /tmp/kind-rasa-config.yaml"

    allgood "KIND RASA cluster creation finished"

    info "================================================================================="
    info "Since you choose the --just-install flag "
    info "you can now your rasactl to kickstart a local rasax installation run"
    info "kubectl cluster-info --context kind-rasa"
    info "rasaxctl start rasa-x --kubeconfig /home/<user>/.kube/config --project-path /home/<user>/<rasaworkdir>"
    info ""
    info "More information you can find under "
    info "https://github.com/RasaHQ/rasactl/"
    info "================================================================================="
    exit 1

  fi

}

# finalize with rasaxctl at end
# TODO: rasaxctl binary download
kind_finalize_rasactl() {

  info "Creating KIND RASA Cluster"
  cmd "curl -Lo /tmp/kind-rasa-config.yaml https://raw.githubusercontent.com/RASADSA/DSI/main/kind/kind-rasa-config.yaml"
  cmd "kind create cluster --name rasa --config /tmp/kind-rasa-config.yaml"
  cmd "rm /tmp/kind-rasa-config.yaml"
  allgood "KIND RASA cluster creation finished"
  cmd "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml"
  cmd "kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission"

  warn "==================================================================="
  warn "${BOLD}Installing RASAX Offical Helmchart to local RASA KIND Cluster"
  warn "${BOLD}This will take around 8-10 minutes - time to make a coffe or tea =]"
  warn "===================================================================="

  sudo_cmd "rasaxctl start rasa-demo --kubeconfig $HOME/.kube/config --project-path $PWD"

}

uninstall() {

  info "Deleting RSI Cluster"
  cmd "kind delete clusters rasa"
  allgood "KIND RASA cluster deleted"
  exit 1

}


# cli help page
usage() {
    cat <<EOT
rsi.sh [option]

Fetch and install the latest version RASAX running with KIND

Options

  -f, -y, --force, --yes
    Skip the confirmation prompt during installation

  -V, --verbose
    Enable verbose output of all running commands

  -h, --help
    Dispays this help message

  -u, --uninstall
    uninstall RASA X / RASA OSS installation

  -x, --just-install
    Install rasactl binary and all depencies for KIND but dont create a KIND Cluster and install the chart

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
  -x | --just-install)
    NO_RASAX_INSTALL=1
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
check_set_arch
check_os_install_kind
