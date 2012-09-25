#!/bin/bash
# 
# Simple script to automate managing camp-specific services.
# Used in conjunction with DevCamps.org camps.
# Brian 'Phunk' Gadoury <bgadoury@endpoint.com. 

camp_dir=$( cd "$( dirname "$0" )/.." && pwd )

# ElasticSearch
es_cmd="/usr/share/elasticsearch/bin/elasticsearch"
es_pidfile="${camp_dir}/var/elasticsearch.pid"

function start {
  `$es_cmd -Des.config=${camp_dir}/v1/config/elasticsearch/elasticsearch.yml -p $es_pidfile`
}

function stop {
    if [ -e $es_pidfile ] ; then
        kill -HUP `cat $es_pidfile`
    fi
}

function restart {
    stop
    sleep 2
    start
}

if [ ! $1 ] ; then
    echo 'You forgot the --start, --stop, or --restart'
    exit 1
fi

if [ $1 = '--stop' ] ; then
    stop
fi

if [ $1 = '--start' ] ; then
    start
fi

if [ $1 = '--restart' ] ; then
    restart
fi

exit 0
