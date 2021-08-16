#!/bin/bash
#CLUSTER_NAME=$1
#RESOURCE_GROUP=$2
#SUBSCRIPTION=$3

az aks get-upgrades \
--subscription "$SUBSCRIPTION" \
--resource-group "$RESOURCE_GROUP" \
--name "$CLUSTER_NAME" \
-o yaml