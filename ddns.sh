#!/usr/bin/env bash

if [ ! -f ".auth.json" ];
then
  echo "no .auth.json file found"
  echo "creating one"
  jq --null-input '{"secretapikey":"", "apikey":"", "domain":""}' > .auth.json
  exit
fi

DOMAIN=$(jq .domain .auth.json | sed "s/\"//g")
APIKEY=$(jq .apikey .auth.json)
SECRETAPIKEY=$(jq .secretapikey .auth.json)

retrieve=$(curl -s -X POST https://api.porkbun.com/api/json/v3/dns/retrieve/"$DOMAIN" -d "{\"secretapikey\": $SECRETAPIKEY, \"apikey\": $APIKEY }")


retrieve_by_line=$(jq -c .records.[] <<<"$retrieve")
subdomains=""
for subdomain in $retrieve_by_line;
do
  if [ "$(jq .type <<<"$subdomain" )" == "\"A\"" ];
  then
    name=$(jq .name <<<"$subdomain" | sed "s/\"//g")
    ip=$(jq .content <<<"$subdomain" | sed "s/\"//g")
    echo "$name: $ip"
    subdomains+="$subdomain"$'\n'
  fi
done

IP="$( curl -s https://ipecho.net/plain )"

echo
echo "pubblic ip: $IP"

for subdomain in $retrieve_by_line;
do
  if [ "$(jq .type <<<"$subdomain" )" == "\"A\"" ];
  then
    name=$(jq .name <<<"$subdomain" | sed "s/\"//g" )
    ip=$(jq .content <<<"$subdomain" | sed "s/\"//g")
    if [ "$ip" != "$IP" ];
    then
      if [ "$name" == "$DOMAIN" ];
      echo "$DOMAIN"
      then
        echo "$name"
        curl -X POST https://api.porkbun.com/api/json/v3/dns/editByNameType/"$DOMAIN"/A -d "{\"secretapikey\": $SECRETAPIKEY, \"apikey\": $APIKEY, \"content\": \"$IP\", \"ttl\": \"600\" }"
        echo
      else
        name=$(echo "$name" | sed "s/\./ /g" | awk '{ print $1 }')
        echo "$name"
        curl -X POST https://api.porkbun.com/api/json/v3/dns/editByNameType/"$DOMAIN"/A/"$name" -d "{\"secretapikey\": $SECRETAPIKEY, \"apikey\": $APIKEY, \"content\": \"$IP\", \"ttl\": \"600\" }"
        echo
      fi
    fi
  fi
done
