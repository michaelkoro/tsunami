
# Tsunami

## Prerequisites 

- pre-compiled docker image of tsunami. available here - https://github.com/google/tsunami-security-scanner


## Installation
There are 2 main ways to deploy this tsunami job on top of Kubernetes.

### Option 1 - Kubernetes resource

Given a list of servers in a file,  we need to create a Job in kubernetes for each server in the list (since the tsunami scanner takes only one IP address as an argument). In order to achieve that, we store a template for the Job resource, iterate over the list of servers, and create multiple independent Job resources for each server.
Our template.sh script - 
```
#! /bin/bash
cat example/servers-list |  while  read line || [[ -n $line ]];
do
cat job.tmpl.yaml | sed "s/\$IP/$line/"  > ./example/job-$line.yaml
done
```
Given the following file - 
```
1.1.1.1
1.1.1.3
2.2.2.2
100.200.100.200
```
This will generate 4 kubernetes Job files, where each one points to one of the servers.
For example - 
```
apiVersion: batch/v1
kind: Job
metadata:
  name: tsunami-scanner-1.1.1.1
  namespace: kube-system
  labels:
    jobgroup: tsunami-scanner
spec:
  template:
    metadata:
      name: tsunami-scanner
	  labels:
	    jobgroup: tsunami-scanner
	spec:
	  containers:
      - name: scanner
        image: tsunami
        args: ["sh", "-c", "--ip-v4-target=1.1.1.1"]
        restartPolicy: Never
```

## Option 2 - Helm
This is very similar to the first option, however, instead of creating independent Job resource for each server, we create all Jobs as part of one chart (this provides us with more control over the tsunami configuration, where changes are only made through the chart, and are updated across all Jobs).

With the given values.yaml file -
```
servers:
 - 1.1.1.1
 - 1.1.1.3
 - 2.2.2.2
 - 100.200.100.200
```
We iterate over the list of servers, and create for each IP its own Job resource, using the template - 
```
{{- range  .Values.servers }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $.Values.serviceName }}-{{ . }}
  namespace: {{ $.Values.namespace }}
  labels:
    jobgroup: {{ $.Values.serviceName }}
spec:
  template:
    metadata:
      name: {{ $.Values.serviceName }}
      labels:
        jobgroup: {{ $.Values.serviceName }}
    spec:
      containers:
      - name: scanner
        image: {{ $.Values.image.repository }}
        imagePullPolicy: {{ $.Values.image.pullPolicy }}
        args: ["sh", "-c", "--ip-v4-target={{ . }}"]
        resources:
          limits:
            cpu: 200m
            memory: 256Mi
          requests:
            cpu: 100m
            memory: 128Mi
      restartPolicy: Never
---
{{- end }}
```

This way all created Jobs are part of one helm release and can be managed together.