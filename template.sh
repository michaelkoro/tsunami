#! /bin/bash
cat example/servers-list | while read line || [[ -n $line ]];
do
  cat job.tmpl.yaml | sed "s/\$IP/$line/" > ./example/job-$line.yaml
done