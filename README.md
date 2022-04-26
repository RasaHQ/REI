# Deprecation Notice 

**REI is deprecated - please use [rasactl](https://github.com/RasaHQ/rasactl) for the future**
**https://github.com/RasaHQ/rasactl**


## RASA Ephemeral Installer (REI)

REI will help you to get an easy way to run and test RASA X / RASA OSS on your local workstation with a breeze.

## How does REI manage the installation

REI installs KIND as Kubernetes (k8s) Platform and install RASA rasactl to deploy managed RASA X / OSS on top.

REI will check Requirements and install for the supported OS:

- Docker
- kubectl
- helm
- kind
- rasactl

### Requirements

- Linux or macOS operating system

To work with REI in an optimal enviroment please use a System with the following resources at hand

Minimum / (Recommended)

- Dual-Core CPU / Quad-Core CPU
- 8 GB RAM / 16 GB RAM
- 25 GB DISK / 50 DISK

## Quick Installation
TL:DR;

```bash
curl -O https://rei.rasa.com/rei.sh && bash rei.sh -y -x
```

or

```bash
wget https://rei.rasa.com/rei.sh && bash rei.sh -y -x
```

## Installation

```bash
bash -c "$(curl -fsSL https://rei.rasa.com/rei.sh)"
```

Note - The defaults of the install script can be overridden see the built-in help.

```bash
bash -c "$(curl -fsSL https://rei.rasa.com/rei.sh)" -- --help
```

## FAQ

### How do I see all logfiles ?

To get all logfiles from the RASA X / OSS Deployment just run in your terminal

```bash
kubectl -n rasa-x logs -l app.kubernetes.io/name=rasa-x
```

### How do I remove the KIND Rasa Cluster locally ?

Execute the rsi.sh script with the -u flag

```bash
bash rei.sh -u
```

### How do I see all running RASA containers ?

All running pods are inside the rasa namespace via kubectl

```bash
kubectl -n rasa-x get pods
```

### How do I access the KIND K8S Cluster via kubectl ?

```bash
kubectl cluster-info --context kind-rasa

```
