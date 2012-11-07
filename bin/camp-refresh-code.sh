#!/bin/bash
# 
# Simple script to automate getting a camp running on the latest codebase
# Used in conjunction with DevCamps.org camps.
# Brian 'Phunk' Gadoury <bgadoury@endpoint.com> 

camp_dir=$( cd "$( dirname "$0" )/.." && pwd )
cd $camp_dir

git checkout develop
git pull
rake db:migrate
bundle install
re --all

echo -n "Normal wait for ElasticSearch"

for i in {1..3}
do
    echo -n "."
    sleep  1
done

echo ""

rake v1:recreate_search_index
rake v1:recreate_repo_database
rake v1:recreate_repo_river

echo "Done $0"
