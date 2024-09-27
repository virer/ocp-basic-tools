# My OCP basic Monitoring Script

This script focus on verifying the cluster operator(co) and nodes health status

## Install

First create a user "cluster-monitor" for example, in your cluster.


Then create the limited role to be used
```console
oc apply -f basic-cluster-monitoring-role.yaml
```

Add the cluster role to the user cluster-monitor
```console
oc adm policy add-cluster-role-to-user basic-cluster-monitoring cluster-monitor
```

## Configure
edit the monitor.sh file and change any setting (like password, API, URL, for alerts,etc...)
depending on your setup you may need to change the value of OCP_API_SKIP_TLS_VERIFY

## Test
to test, run the script like that :
```console
bash monitor.sh
```
