#!/bin/bash -x

# Env Vars
# ADMIN_PASSWORD
# KEYCLOAK_URL
# KEYCLOAK_REALM
# KEYCLOAK_CLIENT_ID

readarray -t lines < $1
username=${lines[0]}
password=${lines[1]}

if [[ "${password}" == "${ADMIN_PASSWORD}" ]] && [[ ! -z "${ADMIN_PASSWORD}" ]] ; then
   echo "Valid system user: $1"
   exit 0
fi


get_token() {
   curl --silent --request POST \
        --url "${KEYCLOAK_URL}/auth/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token" \
        --data "client_id=${KEYCLOAK_CLIENT_ID}" \
        --data-urlencode "username=$1" \
        --data-urlencode "password=$2" \
        --data 'grant_type=password' | jq .access_token | xargs echo -n > /etc/openvpn/tmp/$1
}

validate() {
    test=$(curl --silent --url "${KEYCLOAK_URL}/auth/realms/${KEYCLOAK_REALM}/protocol/openid-connect/userinfo" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $(cat /etc/openvpn/tmp/$1 | tr -d '\n')" | jq .email | xargs echo -n)
    if [[ "$test" == "$1" ]]; then
        echo "Valid user: $1"
        return 0
    else
        return 1
    fi
}


if (validate "${username}"); then
  exit 0
fi

if (get_token "${username}" "${password}" && validate "${username}"); then
  exit 0
fi

echo "Auth failed: ${username}"
exit 1
