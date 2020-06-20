
### pi-hole

pi-hole
192.168.68.130
http://pi.hole/admin

Login:
```
admin
heifWWRJcF
```

setuo host file for pi-hole:
```
echo "addn-hosts=/etc/pihole/lan.list" | sudo tee /etc/dnsmasq.d/02-lan.conf
```

local dns file:
```
/etc/pihole/lan.list
```

restart pi hole dns:
```
sudo pihole restartdns
```

add a record to pi-hole:
```
pihole -a hostrecord media.k8s.home.io 192.168.68.220
```
### BananaSpliff helm chart repo

Bananaspliff helm chart repo:
helm repo add bananaspliff https://bananaspliff.github.io/geek-charts
helm repo update

### Transmission over VPN in Kubernetes
```
kubectl create secret generic openvpn \
    --from-literal username='robermar2@gmail.com' \
    --from-literal password='n0^6SJdyWI4F' \
    --namespace media
```
provider: TUNNELBEAR

On each node:
```
kubelet --allowed-unsafe-sysctls 'net.ipv6.conf.all.disable_ipv6'
```

On each node, kubelet config file at:
```
/var/lib/kubelet/config.yaml
```

Append to the bottom:
```
allowedUnsafeSysctls:
- net.ipv6*
```

restart kubelet on the node:
```
systemctl restart kubelet
```

apply psp:
```
kubectl apply -f phase12-pihole/plex/pod-security-policy.yml
```

Update media-transmission-openvpn-values.yml

install chart:
```
helm install transmission bananaspliff/transmission-openvpn \
    --values phase12-pihole/plex/media-transmission-openvpn-values.yml \
    --namespace media


```

### Jacket
review jacket chart default values:
```
helm show values bananaspliff/jackett
```
review media-jackett-values.yml for needed changes

most likely need to set vpn to false

create this directory structure on /mnt/ssd:
```
mkdir -p /mnt/sdd/media/configs/jackett/jackett/
```

install jackett chart
```
helm install jackett bananaspliff/jackett \
    --values phase12-pihole/plex/media-jackett-values.yml \
    --namespace media
```

Append the following to /mnt/ssd/media/configs/jackett/jackett/ServerConfig.json
```
,
"BasePathOverride": "/jackett"
```

Delete existing pod for jackett so latest config is applied

### Sonarr

view default chart values
```
helm show values bananaspliff/sonarr
```

on ssd, create directory structure:
```
mkdir -p /mnt/ssd/media/configs/sonarr/
```

add config base xml to mnt/ssd
```
nano /mnt/ssd/media/configs/sonarr/config.xml
```

save this to config.xml
```
<Config>
  <UrlBase>/sonarr</UrlBase>
</Config>
```

change owner to default user running kubernetes
```
chown revans:revans config.xml
```

install sonarr chart
```
helm install sonarr bananaspliff/sonarr \
    --values phase12-pihole/plex/media-sonarr-values.yml \
    --namespace media
```

install my sonarr chart
```
helm install sonarr ../geek-charts/sonarr/ \
  --values phase12-pihole/plex/media-sonarr-values.yml \
  --namespace media
```

### Radarr
view defauts values for helm chart
```
helm show values bananaspliff/radarr
```

on ssd, create directory structure:
```
mkdir -p /mnt/ssd/media/configs/radarr/
```

add config base xml to mnt/ssd
```
nano /mnt/ssd/media/configs/radarr/config.xml
```

save this to config.xml
```
<Config>
  <UrlBase>/radarr</UrlBase>
</Config>
```

change owner to default user running kubernetes
```
chown revans:revans config.xml
```

install radarr chart
```
helm install radarr bananaspliff/radarr \
    --values phase12-pihole/plex/media-radarr-values.yml \
    --namespace media
```

upgrade radarr chart
```
helm upgrade radarr bananaspliff/radarr \
    --values phase12-pihole/plex/media-radarr-values.yml \
    --namespace media
```

install my radarr chart
```
helm install radarr ../geek-charts/radarr/ \
  --values phase12-pihole/plex/media-radarr-values.yml \
  --namespace media
```

### Plex

install chart:
```
helm install plex ../kube-plex/charts/kube-plex/ \
  --values phase12-pihole/plex/media-plex-values.yml \
  --namespace media
```

upgrade chart:
```
helm upgrade plex ../kube-plex/charts/kube-plex/ \
  --values phase12-pihole/plex/media-plex-values.yml \
  --namespace media
```