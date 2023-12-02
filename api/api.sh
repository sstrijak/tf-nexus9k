curl -kg --cookie $1.jar --cookie-jar $1.jar https://$1/api/$2.json$3 > $1.json
cat $1.json | python -m json.tool
