#!/bin/bash


for year in 2013; do
  for month in $(seq -f "%02g" 1 5); do
    for day in $(seq -f "%02g" 1 31); do
      for hour in $(seq 0 23); do
	filename="$year-$month-$day-$hour.json.gz"
	echo $filename
	if [[ ! -f rawdata/$filename ]]; then
	  wget http://data.githubarchive.org/$filename -P rawdata
	fi
      done
    done
  done
done


