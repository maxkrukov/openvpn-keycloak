#!/bin/bash -xe

convert_mask() {
 if [ ! -z $1 ]; then
    for i in ${1//,/ }; do
       eval $(ipcalc -nm $i)
       echo "push \"route ${NETWORK} ${NETMASK}\""
    done
 fi
}

sed -i "s/<subnet>/${SUBNET}/g" /etc/openvpn/server.conf
sed -i "s/<server_ip>/$(curl --silent http://ifconfig.me)/g" /etc/openvpn/server.conf
sed -i "s/<server_ip>/$(curl --silent http://ifconfig.me)/g" /etc/openvpn/client.ovpn
convert_mask "${forwardSubnets}" >> /etc/openvpn/server.conf

echo  '<ca>'                   >> /etc/openvpn/client.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/client.ovpn
echo '</ca>'                   >> /etc/openvpn/client.ovpn

sed -i "s/<ADMIN_PASSWORD>/${ADMIN_PASSWORD}/" /etc/openvpn/server.conf
sed -i "s@<KEYCLOAK_URL>@${KEYCLOAK_URL}@" /etc/openvpn/server.conf
sed -i "s/<KEYCLOAK_REALM>/${KEYCLOAK_REALM}/" /etc/openvpn/server.conf
sed -i "s/<KEYCLOAK_CLIENT_ID>/${KEYCLOAK_CLIENT_ID}/" /etc/openvpn/server.conf

cat /etc/openvpn/server.conf

sysctl -w net.ipv4.ip_forward=1

iptables -P FORWARD DROP
iptables -A FORWARD -d "${SUBNET}/24,${forwardSubnets}" -j ACCEPT

iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING  -j MASQUERADE
mkdir -p /dev/net && mknod /dev/net/tun c 10 200 || true
chmod 600 /dev/net/tun

openvpn --config  /etc/openvpn/server.conf
