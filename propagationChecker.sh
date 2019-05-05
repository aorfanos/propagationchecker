#!/bin/bash

#This is a very simple wrapper around the DNS-LG API
#offered at dns-lg.com

usage(){
	echo "Options:
		-c | --check : Checks one time using 17 nameservers and 7 anycast
			./propagationChecker.sh -c <record-type> <name>
			EXAMPLE: ./propagationChecker.sh -c a google.com
		-l | --list-available: List the available nameservers to perform the query.
			EXAMPLE: ./propagationChecker.sh -l
		-r | --repeat-every : Performs the same check as -c but every N seconds
			./propagationChecker.sh -r <seconds> <record-type> <name>	
			EXAMPLE: ./propagationChecker.sh -r 10 aaaa google.com
		-s | --server: Request records from specific server.
		Valid options: listed via the -l flag
			./propagationChecker.sh -s <server> <record-type> <name>
			EXAMPLE: ./propagationChecker.sh -s at01 mx google.com
		Powered by www.dns-lg.com"

}

master(){
SERVER_POOL=("at01" "at02" "ch01" "cn01"\
         "cn02" "cz01" "cz02" "de01"\
         "de02" "de03" "dk01" "dk02"\
         "ru01" "ru02" "ru03" "us01"\
         "us02" "cloudflare" "google1" "google2"\
	 "he" "opendns1" "opendns2" "quad9")

for server in "${SERVER_POOL[@]}"
do
	 echo "===== Server $server ====="
	 curl -s http://www.dns-lg.com/$server/$2/$1 | jq '.[] | .[] | select(.rdlength > 0 ) | .rdata'
done
}

list_nodes(){
	curl -s http://www.dns-lg.com/nodes.json | jq -r '.[] | .[] | "\(.name) , (\(.country) - \(.operator))"'
}

propchecker(){
	master $1 $2
}

propchecker_loop(){

	REFRESH_TIME=$1
	while :
	do
		master $2 $3
		sleep $REFRESH_TIME
		clear
	done

}

spec_server(){
	#Usage:
	# spec_server <server> <request-type> <name>
	echo "===== Server $1 ====="
	curl -s http://www.dns-lg.com/$1/$3/$2 | jq '.[] | . [] | select(.rdlength > 0) | .rdata'
}

while [[ $# -gt 0 ]]
do
	key=$1
	case $key in
		-c|--check)
			propchecker $2 $3
			shift
		;;
		-r|--repeat-every)
			propchecker_loop $2 $3 $4
			shift
		;;
		-s|--server)
			spec_server $2 $3 $4
			shift
		;;
		-l|--list-available)
			list_nodes
			shift
		;;
		-h|--help)
			usage
			shift
		;;
		*)
			shift
		;;
esac
done
