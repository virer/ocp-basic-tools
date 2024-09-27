#!/bin/bash
###########
# MIT License
# 
# Copyright (c) 2024 Sebastien Caps
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###########

# Settings
ALERT_URL="http://localhost:54/notif/ocp/mon/script" # XXX CHANGEME XXX
MYUSER="my-username"                                 # XXX CHANGEME XXX
OC_CMD_FULLPATH="/usr/local/bin/oc"                  # XXX CHANGEME XXX
OCP_USR="cluster-monitor"                            # XXX CHANGEME XXX
OCP_PWD="password"                                   # XXX CHANGEME XXX
OCP_API="api.lab-ocp.example.com:6443"               # XXX CHANGEME XXX
OCP_API_SKIP_TLS_VERIFY="false"                      # XXX CHANGEME XXX
# *************************
LOGIN_ARGS="-u $OCP_USR -p $OCP_PWD -s $OCP_API --insecure-skip-tls-verify=$OCP_API_SKIP_TLS_VERIFY"
EXIT_AT_FIRST_PLACE="1"
# *************************
HOMERDIR=$( getent passwd "$MYUSER" | cut -d: -f6 )
cd $HOMERDIR
export HOME=$HOMERDIR
# *************************

# Login status
$OC_CMD_FULLPATH login $LOGIN_ARGS 1>/dev/null 
LOGIN_RET="$?"
if [ "$LOGIN_RET" == "1" ]; then
        ERROR_MSG="Error during login on the cluster"
        echo $ERROR_MSG
	curl -X POST -H "Content-Type: application/json" -d '{"message":"'"$ERROR_MSG"'"}' $ALERT_URL
        if [ "$EXIT_AT_FIRST_PLACE" == "1" ] ; then
	       exit 1
	fi
fi

# *************************

# NODES status 
NODE_LIST=`$OC_CMD_FULLPATH get nodes`
NODE_RET="$?"

if [ "$NODE_RET" == "1" ]; then
        ERROR_MSG="Error geting nodes status"
        echo $ERROR_MSG
	curl -X POST -H "Content-Type: application/json" -d '{"message":"'"$ERROR_MSG"'"}' $ALERT_URL
        if [ "$EXIT_AT_FIRST_PLACE" == "1" ] ; then 
               exit 1
        fi
fi

IFS=$'\n'
for node_line in $( $OC_CMD_FULLPATH get nodes -o go-template='{{range .items}}{{.metadata.name}}:-{{range .status.conditions}}{{ .type }}:{{ .status }};{{end}}{{"\n"}}{{end}}' | grep -v 'Ready:True' ); do
	node=$( echo $node_line | cut -d ':' -f1)
	ERROR_MSG="Node $node not ready"
	echo $ERROR_MSG
	curl -X POST -H "Content-Type: application/json" -d '{"message":"'"$ERROR_MSG"'"}' $ALERT_URL
	if [ "$EXIT_AT_FIRST_PLACE" == "1" ] ; then
               exit 1
        fi
done

# *************************

# Cluster operator status

IFS=$'\n'
for co in $( oc get co -o go-template='{{range .items}}{{.metadata.name}} :-{{range .status.conditions}}{{ .type }}:{{ .status }};{{end}}{{"\n"}}{{end}}' | grep -v insights | egrep '(-Degraded:True|Available:False)' ); do
	# output example :
        #   authentication:-Degraded:True;Progressing:False;Available:False;Upgradeable:True;
	# CO_NAME=`echo $co | cut -d ':' -f 1 `
	ERROR_MSG="Issue detected with Cluster Operator $co"
        echo $ERROR_MSG
	curl -X POST -H "Content-Type: application/json" -d '{"message":"'"$ERROR_MSG"'"}' $ALERT_URL
        if [ "$EXIT_AT_FIRST_PLACE" == "1" ] ; then 
               exit 1
        fi
done

# EOF
