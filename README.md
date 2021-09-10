# RASA Ephermal Installer (REI) 

REI will help you to get an easy way to run and test RASA X / RASA OSS on your local workstation with a breeze.

## How does REI manage the installation

REI installs KIND as Kubernetes (k8s) Platform and install RASA rasactl to deploy managed RASA X / OSS on top.

REI will check Requirments and install for the supported OS:

- Docker
- kubectl
- helm
- kind
- rasactl

### Requirements

Supported OS:

- MacOS Catalina+
- Ubuntu / Debian
- ArchLinux / Manjaro

to work with REI in an optimal enviroment please use a  System with the following resources at hand

Minimum / (Recommended)

- Dual-Core CPU / Quad-Core CPU
- 8 GB RAM / 16 GB RAM
- 25 GB DISK / 50 DISK

## Quick Installation
TL:DR;

```bash
curl -O https://raw.githubusercontent.com/RasaHQ/REI/main/rei.sh && bash rei.sh -y -x
```

or

```bash
wget https://raw.githubusercontent.com/RasaHQ/REI/main/rei.sh && bash rei.sh -y -x
```

## Installation

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RasaHQ/REI/main/rei.sh)"
```

Note - The defaults of the install script can be overridden see the built-in help.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RasaHQ/REI/main/rei.sh)" -- --help
```

## FAQ

### how do I see all logfiles ?

to get all logfiles from the RASA X / OSS Deployment just run in your terminal

```bash
kubectl -n rasa logs -l app.kubernetes.io/name=rasa-x
```

### how do i remove the KIND Rasa Cluster locally ?

excute the rsi.sh script with the -u flag

```bash
bash rei.sh -u
```

### how do i see all running RASA containers ?

all running pods are inside the rasa namespace via kubectl

```bash
kubectl -n rasa get pods
```

### how do i access the KIND K8S Cluster via kubectl ?

```bash
kubectl cluster-info --context kind-rasa

```
