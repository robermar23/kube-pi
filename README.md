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

## Phase 4: Kubernetes Core Install
<i>Note: install requires root privledges</i>

### -- On Each Raspberry Pi (master/node) --

Ensure legacy binaries are installed for iptables
```bash
sudo apt-get install -y iptables arptables ebtables
```
switch to legacy version of iptables (required for kubernetes)
```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy
```

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

## Phase 5: Kubernetes Networking
weave.works's weave-net offers a cni plugin for kubernetes that also supports arm chipsets and, at this time, works out of the box.

Per their instructions:
```bash
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

If all goes well, this should show a weave pod succesfully running on each node in the kube-system namespace:
```bash
kubectl get pods --namespace=kube-system
```

## Phase 6 Join Nodes
### -- On Each Node (except Master)
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

### Setup ssh to each node from a client (optiona)
```bash
ssh-keygen

for host in 192.168.68.201 \
    192.168.68.202 \
    192.168.68.203 \
    192.168.68.204 \
    192.168.68.205 \
    192.168.68.127; \
    do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
    done
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
```

## Phase 7: Kubernetes Ingress
Decided to go with traefik: https://docs.traefik.io/user-guides/crd-acme/

treaefik crd's:
```bash
kubectl apply -f phase6-ingress/controller/traefik-crd.yaml 
```

deploy example services
```bash
kubectl apply -f phase6-ingress/services.yaml 
```

deploy example apps
```bash
kubectl apply -f phase6-ingress/deployment.yaml 
```

```bash
kubectl port-forward --address 0.0.0.0 service/traefik 8000:8000 8080:8080 443:4443 -n default
```

This has some good steps for testing out your cluster:
https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/

### Access cluster resources from outside the cluster

#### kubectl proxy
```bash
kubetctl proxy [port]
```
all traffic over the port is sent to the cluster (specifically the main api)

#### port forward
```bash
kubectl port-forward [service or pod] [port]:[target-port]
```

#### Build proxy url's manually:
```bash
https://192.168.68.201:6443/api/v1/namespaces/default/services/http:whoami:web/proxy
```

#### Use NodePort loadbalancers
This is the avenue you'll most likely use for labs/personal/development use.  This type of service will create a LoadBalancer that opens a defined port on each NODE in your cluster.  You can view the port opened by describing the service.  This is ideal as it allows you to setup something like HAProxy in front of your cluster nodes, defining proxy paths to the port on each node.

Example NodePort type is at: /phase7-ingress/example-http/load-balancer.yaml

## Phase 9: HAProxy with DNSMasq for External Ingress

From entry-point, either local client or dedicated linux:

Install HAProxy
```bash
sudo apt-get install haproxy
```

HAProxy config is at:
```bash
/etc/haproxy/haproxy.cfg
```

View output for haproxy:
```bash
journalctl -u haproxy.service --since today
```

If you setup a Service of type NodePort, and Kubernetes started listening on port 31090, you can setup a simple load balancer to proxy traffic to that service using the following in your haproxy.cfg:

Note: 
```
frontend k8s-whoami-proxy
        bind    [local client ip]:[port to expose, usually 80 or 443]
        mode    tcp
        option  tcplog
        default_backend k8s-whoami

backend k8s-whoami
        mode    tcp
        option  tcp-check
        balance roundrobin
        default-server  inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
        server  k8s-node-01 [node1-ip]:31090 check
        server  k8s-node-02 [node2-ip]:31090 check
        server  k8s-node-03 [node3-ip]:31090 check
        server  k8s-node-04 [node4-ip]:31090 check
```
replace the [node1-ip] and so on with actual ip's of node's in your kubernetes cluster

Install dnsmasq
```bash
apt-get install dnsmasq dnsutils
```

## Phase 8: Kubernetes Dashboard
https://github.com/kubernetes/dashboard

to deploy:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```
we first need to setup cheap local admin access with a serviceaccount.

create a service account that has a cluster-admin role
```bash
kubectl apply -f phase8-dashboard/admin-sa.yaml
```

describe the new local-admin service account to get its access token secret name:
```bash
kubectl describe sa local-admin
```

copy the first "Tokens" secret name you see and describe it like so:
```bash
kubectl describe secret local-admin-token-9whqp
```

copy down the token as you will use it later to login to the dashboard

to access, without setting up any ingress:
```bash
kubectl proxy
```

go to the following url:
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
```

this is also a good way to gain access to any service running in your cluster without setting up ingress.

## Phase 9 Nagios
I wanted to setup a monitoring solution that was light weight and free.  Nagios has been around forever and, as it turned out, you can get the agents and server to work on a raspberry pi.

I am work working on contaierizing nagios core server.

But, for now I have it running on bare metal on a separate pi.

The scripts here are to get the nrpe agent + nagios plugins installed on each pi running as a kubernetes node.

It involves compiling the source from scratch in order to install on a raspberry pi.  It can take some time.

Copy over the script to each node and then run it. It installs nrpe and the core plugins.

From where you have checked out this repo:
```bash
rcp /phase8-nagios/install_nrpe_source.sh pirate@[node ip]:/tmp
```

ssh into each node and run the script:
```bash
ssh pirate@[node ip]
cd /tmp
chmod +x install_nrpe_source.sh
./install_nrpe_Source.sh
```

At this point its about setting up your nagios core server to monitor these nodes through check_nrpe.

## Phase 10: Kubernetes Local/Remote Volume Provisioning

## Phase 11: Using kube-pi

## Helpful Kubernetes commands
<b>Setup local kubectl to connect to remove cluster</b>
```bash
scp -r pirate@192.168.68.201:/home/pirate/.kube .
cp -r .kube $HOME/
```
bam!

<b> Switch namespace</b>
```bash
kubectl config set-context --current --namespace=[my-namespace]
```

<b>Auto complete for kubectl</b>
```bash
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
```

<b>Attach to a container that support tty.  The net-tool pod is a swiss army knife of network troubleshooting tools in a containerized environment.</b>

```bash
kubectl apply phase5-networking/net-tool.yml
```

This will run a tty capable pod that will wait for you
```bash
kubectl attach -it net-tool -c net-tool
```
That will attach to the net-tool container in the net-tool pod

Export kubernetes object as yaml
```bash
kubectl get service kubernetes-dashboard -n kubernetes-dashboard --export -o yaml > phase8-dashboard/dashboard-service.yaml
```

List listening ports on a given host:
```bash
sudo netstat -tulpn | grep LISTEN
```

