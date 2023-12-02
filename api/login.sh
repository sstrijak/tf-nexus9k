#./api.sh fen1 mo/sys/isis/inst-underlay/dom-default/af-v4 "?query-target=children"
curl -k --cookie $1.jar --cookie-jar $1.jar -X POST -d '{"aaaUser" : {"attributes" : {"name": "$NXOS_USERNAME","pwd": "$NXOS_PASSWORD"}}}'  https://$1/api/mo/aaaLogin.json
