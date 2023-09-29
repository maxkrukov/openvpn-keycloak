FROM alpine:3

RUN apk add openvpn wget curl openssl iproute2 iptables net-tools bash python3 py3-urllib3 ipcalc jq

RUN cd /etc/openvpn/ && \
    wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz && \
    tar -xf tar -xf EasyRSA-3.1.2.tgz && \
    mv EasyRSA-3.1.2/ easy-rsa/; rm -f EasyRSA-3.1.2.tgz
    
COPY openvpn-bootstrap/vars /etc/openvpn/easy-rsa/vars

RUN cd /etc/openvpn/easy-rsa && ./easyrsa init-pki  && \
    ./easyrsa --batch --req-cn=cn_MqZtFvwq35w1vtVX build-ca nopass && \
    yes yes | ./easyrsa gen-req openvpn-server nopass && yes yes | ./easyrsa sign-req server openvpn-server nopass && \
    ./easyrsa gen-dh && openvpn --genkey secret ta.key && \
    mkdir -p /etc/openvpn/client  && \
    mkdir -p /etc/openvpn/server  && \
    mkdir -p /etc/openvpn/tmp  && \
    mkdir -p /etc/openvpn/client/ccd && \
    cp pki/ca.crt /etc/openvpn/server/ && \
    cp pki/issued/openvpn-server.crt /etc/openvpn/server/ && \
    cp pki/private/openvpn-server.key /etc/openvpn/server/ && \
    cp pki/ca.crt /etc/openvpn/client/ && \
    cp pki/dh.pem /etc/openvpn/server/ && \
    cp ta.key /etc/openvpn/server/

RUN chown nobody:nobody -R /etc/openvpn

CMD /run.sh
