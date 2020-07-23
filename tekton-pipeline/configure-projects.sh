#!/bin/bash 

set -xe 

echo "Configuring  project"


if [ $# -ne 3 ];
then
  echo "Please pass projectname"
  echo "USAGE: $0 projectname appname create"
  echo "USAGE: $0 projectname appname delete"
  exit 1
fi

if [ ${3} != 'create' ||  ${3} != 'delete'  ];
then 
  echo "CREATE or DELETE flag was not passed"
  exit 1
fi

PROJECT_NAME=${1}
APP_NAME=${2}
CREATE_DELETE=${3}

cat >deploymentConfig.yaml<<EOF
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: ${APP_NAME}-dc
spec:
  replicas: 0
  strategy:
    type: Rolling
  template:
    metadata:
      labels:
        traffic: "true"
        app: ${APP_NAME}
    spec:
      containers:
        - image: image-registry.openshift-image-registry.svc:5000/${PROJECT_NAME}/${APP_NAME}
          imagePullPolicy: Always
          name: ${APP_NAME}
          ports:
            - containerPort: 8080
              protocol: "TCP"
EOF

cat >services.yaml<<EOF
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
    app.kubernetes.io/component: ${APP_NAME}
    app.kubernetes.io/instance: ${APP_NAME}
    app.kubernetes.io/name: php
    app.kubernetes.io/part-of: ${APP_NAME}
spec:
  selector:
    traffic: "true"
  ports:
    - name: 8080-tcp
      protocol: TCP
      port: 8080
      targetPort: 8080
    - name: 8443-tcp
      protocol: TCP
      port: 8443
      targetPort: 8443
EOF

cat >route.yaml<<EOF
apiVersion: v1
kind: Route
metadata:
  name: ${APP_NAME}
spec:
  port:
    targetPort: 8080
  to:
    kind: Service
    name: ${APP_NAME}
    weight: 100
EOF


oc ${CREATE_DELETE} -f deploymentConfig.yaml -n $PROJECT_NAME
oc ${CREATE_DELETE} -f services.yaml -n $PROJECT_NAME
oc ${CREATE_DELETE} -f route.yaml -n $PROJECT_NAME