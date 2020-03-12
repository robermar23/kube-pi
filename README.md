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
- step 3: review 'phase3-image/static.yml' and make any changes you need. you will most likely want to change the hostname and static ip configuration as well as the user section.
- step 4: run the flash script:
```bash
flash -u static.yml https://github.com/hypriot/image-builder-rpi/releases/download/v1.12.0/hypriotos-rpi-v1.12.0.img.zip
```
- step 5: rinse and repeat for each Pi you want in your cluster.  Make sure to update the hostname and static ip address in phase3-image/static-yml

This will flash the image from the url above.  You may need to update the hyperiot image version.  It will then apply the config in static.yml

## Phase 3: Kubernetes Core Install
<i>Note: install requires root privledges</i>

### -- On Each Raspberry Pi (master/node) --
Trust the kubernetes APT key and add the official APT Kubernetes repository:
```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
```
Install <b>kubeadm</b>:
```bash
apt-get update && apt-get install -y kubeadm
```

Rinse. Repeat on each pi.

### -- On Each Master (only 1 required) --
```bash
kubeadm init --pod-network-cidr 10.244.0.0/16
```
<i>note the ipcdr that is being set. If you are picky and want something else, you'll need to update kube-flannel.yml as its used there as well.  See Kubernetes Networking below for more info</i>

Sit back and let it do its thing.  If all goes well, you will eventually see a message telling you the master was initialized succesfully.  Critically, if provides you the command to run to join other nodes to the cluster.  Write that shit down.  Should be:
```bash
kubeadm join --token=[unique token] [ip of master]
```

On the master still, finally run:
```bash
sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
```

### -- On Each Node (rest of your pi's)
Run the join command (use your actual join command from above):
```bash
kubeadm join --token=bb14ca.e8bbbedf40c58788 192.168.0.34
```
### Verify Nodes
using kubectl, check status of all nodes:
```bash
kubectl get nodes
```
If all went well, all nodes will appear with a status of Ready.  Your master node should display a Role of master.  

<i>note the version of kubernetes.  If can be helpful to know the version when troubleshooting</i>

## Phase 4: Kubernetes Networking
Now comes some fun.  

I ended up using Flannel as my networking provider for kubernetes. It looked like the only one that supported the arm chipset.  Turns out, what I read was old and there are other providers that support arm.  

But, I found that out only after beating my head against the wall with Flannel and actually getting it to work.  So, as it stands now, I use Flannel and the instructions here "should" work.  It was difficult to get Flannel to work because the documentation and releases of Flannel have not kept pace with the releases and required changes for newer version of Kubernetes and Docker. The changes required to fixe my issues required pulling in information from multple sources.

With all that being said, let's take the plunge:

First, we have to modify the iptables ON EACH NODE/MASTER in the cluster to address an issue with new versions of docker:
```bash
sudo iptables -A FORWARD -i cni0 -j ACCEPT
sudo iptables -A FORWARD -o cni0 -j ACCEPT
```
Next we need to deploy the flannel resources, which end up being a DaemonSet and RBAC to support it.
```bash
kubectl apply -f /phase4-core-install/kube-flannel.yml
```
The kube-flanne.yml was originally sourced from https://rawgit.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml.  The latest release is v0.11.0 but it also does not work.  The kube-flannel.yml here does work with kubernetes 1.17.3

If all goes well, this should show a flannel pod succesfully running on each node in the kube-system namespace:
```bash
kubectl get pods --namespace=kube-system
```

#### Troubleshooting Flannel
I found while troubleshooting Flannel, that the process of restarting the pods in the flannel daemonset itself caused issues.  The network interface it creates on the host is not removed and, it seemingly is unable to get around that at startup and fails.  You have to manually remove the interface on each node:
```bash
sudo ip link delete flannel.1
```

If you need to restart the flannel daemonset for whatever reason (maybe config change), you can run:
```bash
kubectl delete pod -l app=flannel --namespace=kube-system
```

#### Troubleshooting cluster join
The join token provided at init is only good for 24 hours, so if you need to join a node after that period of time, you can ask for a new token.

On the master:
```bash
kubeadm token create
```

You may see some validation errors, but they can be ignored for now. With the new token, you can run this on the new node:
```bash
kubeadm join [master ip address]:6443 --token [new token]--discovery-token-unsafe-skip-ca-verification

## Phase 4: Kubernetes Ingress
coming soon

## Phase 5: Kubernetes Local/Remote Volume Provisioning

## Phase 6: Using kube-pi