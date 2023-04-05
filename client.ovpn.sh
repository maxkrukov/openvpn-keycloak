#!/bin/bash
docker exec -it openvpn cat /etc/openvpn/client.ovpn | tee -a client.ovpn
