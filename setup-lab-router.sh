#!/bin/bash
#Scripted by Emre A. to automate lab's router setup


# Vérifie que le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Variables
WAN_INTERFACE="ens33"
LAN_INTERFACE="ens34"
LAN_IP="192.168.25.1"
LAN_SUBNET="192.168.25.0"
DOMAIN="lab.local"
DNS_REVERSE_ZONE="25.168.192.in-addr.arpa"
DHCP_RANGE_START="192.168.25.10"
DHCP_RANGE_END="192.168.25.50"
DHCP_NETMASK="255.255.255.0"
DHCP_ROUTER="192.168.25.1"
DNS_FORWARDERS="8.8.8.8; 10.10.10.10;"

# Met à jour le système
apt update && apt upgrade -y

# Activer le routage IP
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configurer iptables pour le NAT
iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -j ACCEPT
iptables -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# Rendre les règles iptables persistantes
apt install -y iptables-persistent
netfilter-persistent save

# Installer et configurer le serveur DHCP
apt install -y isc-dhcp-server

# Configurer DHCP pour le LAN
cat > /etc/dhcp/dhcpd.conf <<EOL
# Bail de 24H
default-lease-time 86400; 
# Bail maxi de 48H
max-lease-time 172800;
subnet $LAN_SUBNET netmask $DHCP_NETMASK {
  range $DHCP_RANGE_START $DHCP_RANGE_END;
  option routers $DHCP_ROUTER;
  option domain-name-servers $LAN_IP;
  option domain-name "$DOMAIN";
}
EOL

# Spécifier l'interface LAN pour le serveur DHCP
sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$LAN_INTERFACE\"/" /etc/default/isc-dhcp-server

# Redémarrer le service DHCP
systemctl restart isc-dhcp-server

# Installer et configurer Bind9 pour le DNS
apt install -y bind9 bind9utils bind9-doc

# Configurer Bind9 pour le domaine lab.local
cat > /etc/bind/named.conf.local <<EOL
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.lab.local";
};
zone "$DNS_REVERSE_ZONE" {
    type master;
    file "/etc/bind/db.192.168.25";
};
EOL

# Configurer le forwarding DNS vers 8.8.8.8 et 10.10.10.10
cat > /etc/bind/named.conf.options <<EOL
options {
    directory "/var/cache/bind";
    
    forwarders {
        $DNS_FORWARDERS
    };
    
    dnssec-validation auto;
    
    listen-on-v6 { any; };
};
EOL

# Créer le fichier de zone pour lab.local
cat > /etc/bind/db.lab.local <<EOL
;
; BIND data file for lab.local
;
\$TTL    604800
@       IN      SOA     router.lab.local. root.lab.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      router.lab.local.
@       IN      A       $LAN_IP
router  IN      A       $LAN_IP
EOL

# Créer le fichier pour le reverse DNS
cat > /etc/bind/db.192.168.25 <<EOL
;
; BIND reverse data file for 192.168.25.0/24
;
\$TTL    604800
@       IN      SOA     router.lab.local. root.lab.local. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      router.lab.local.
1       IN      PTR     router.lab.local.
EOL

# Vérifier la configuration et redémarrer Bind9
named-checkconf
systemctl restart bind9


# Configuration des interfaces réseau via Netplan
cat > /etc/netplan/50-cloud-init.yaml <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $WAN_INTERFACE:
      dhcp4: true
    $LAN_INTERFACE:
      addresses:
        - $LAN_IP/24
      nameservers:
        addresses:
          - 127.0.0.1
      dhcp4: false
EOL

netplan apply

# Fin du script
echo "Configuration complète. Votre serveur est maintenant un routeur avec DNS et DHCP."
