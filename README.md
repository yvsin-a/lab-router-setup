# Script d'Automatisation pour la Configuration d'un Routeur

Ce script a été créé par **Emre A.** pour automatiser la configuration d'un routeur dans un environnement de laboratoire. Il configure le routage, le pare-feu, DHCP, DNS (Bind9), et les interfaces réseau via Netplan.

## Prérequis

- **Système d'exploitation** : Ubuntu/Debian (ou dérivés)
- **Accès root** : Le script doit être exécuté en tant que super-utilisateur (`root`).
- **Paquets requis** : `isc-dhcp-server`, `bind9`, `bind9utils`, `bind9-doc`, `iptables-persistent`, `netplan`.

## Fonctionnalités

1. **Routage IP** : Active le routage entre deux interfaces réseau.
2. **Pare-feu** : Configure `iptables` pour activer le NAT et filtre les paquets.
3. **DHCP** : Installe et configure un serveur DHCP pour la distribution des adresses IP dans le réseau local.
4. **DNS** : Installe et configure Bind9 comme serveur DNS avec une zone directe et une zone inverse pour le domaine local.
5. **Configuration réseau** : Configure les interfaces réseau via Netplan.

## Variables Modifiables

Voici quelques variables importantes à ajuster selon votre environnement :

- **WAN_INTERFACE** : Interface WAN (externe) par défaut, actuellement `ens33`.
- **LAN_INTERFACE** : Interface LAN (interne) par défaut, actuellement `ens34`.
- **LAN_IP** : Adresse IP du routeur sur le réseau local, actuellement `192.168.25.1`.
- **LAN_SUBNET** : Sous-réseau local, actuellement `192.168.25.0`.
- **DOMAIN** : Domaine local, actuellement `lab.local`.
- **DNS_FORWARDERS** : DNS utilisés pour le forwarding, actuellement `8.8.8.8` et `10.10.10.10`.

## Utilisation

1. Cloner le dépôt ou copier le script sur votre serveur.
2. Rendre le script exécutable :

   ```bash
   chmod +x setup-lab-router.sh
