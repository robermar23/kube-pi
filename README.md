# kube-pi
Log and source for my journey in creating a kubernetes cluster based off of Raspberry Pi 4's

## Phase 1: Gather Hardware
| How many  | What  |
|---|---|
| 3 or more  | RaspBerry Pi 4b  |
| 1  | Gig Network Switch  |
| 3 or more  | Ethernet cables if not using wifi  |
| 1 | Raspberry Pi Rack Kit
| | |
| 3 or more  | Raspberry Pi 4 Power Adapters  |
|  <b>or</b> |   |
| 1  | USB Power Hub  |
| 3 or more   |  USB-c to USB-a cables |

## Phase 2: Construction

## Phase 3: RaspBerry Image Prep and Install
I decided to use HypriotOS as the image for each raspberry pi in the k8s cluster.

Their images are prepped for k8s on arm devices, including docker.

Their images also support config on boot, so we can pre-config users, networking and remote ssh as needed

I found it very easy to use their own flash utility to write the image to the sd card.

- step 1: Download flash script:
```bash
curl -LO https://github.com/hypriot/flash/releases/download/2.5.0/flash
chmod +x flash
sudo mv flash /usr/local/bin/flash
```
- step 2: Insert your microSD disk. 32Gb or less is easiest, otherwise you need to perform some extra disk prep. If you don't have an sd card reader, go buy a one.
- step 3: review 'install/static.yml' and make any changes you need. you will most likely want to change the hostname and static ip configuration as well as the user section.
- step 4: run the flash script:
```bash
flash -u static.yml https://github.com/hypriot/image-builder-rpi/releases/download/v1.12.0/hypriotos-rpi-v1.12.0.img.zip
```

This will flash the image from the url above.  You may need to update the hyperiot image version.  It will then apply the config in static.yml

## Phase 3: Kubernetes Core Install

## Phase 4: Kubernetes Networking

## Phase 4: Kubernetes Ingress

## Phase 5: Kubernetes Dynamic Storage

## Phase 6: Use Kubernetes