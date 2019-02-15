**Containerized elasticsearch cluster on kubernetes:**\n
The scope of this document is to deploy the elasticsearch cluster in containers on the kubernetes platform, the document doesnot explains in depth on the kubernetes for detailed information please refer to (https://kubernetes.io/docs/home/)

kubernetes cluster setup details:
```
Masternode:  69.64.48.14
slave1:      199.217.116.88
slave2:      199.217.117.75
slave3:      199.217.117.84
```
Master node is responsible for creating the containers on the slave nodes. All the managment related tasks for the kubernetes cluster has to be performed from the master nodes.

The current kubernetes cluster is using the flanneld flanneld for the networking. For more details on flanneld networking please refer to the (https://github.com/coreos/flannel#flannel).All the containers will be getting the ip addresses in the range of 10.244.0.0/16.
For more information on Kubernetes and its commands please refer to the (https://kubernetes.io/docs/home/)

**check the kubernetes cluster health:**

From the master node use the below commands to get the cluster health.(Need to do be root user)
```
$ kubectl get nodes -o wide
NAME   STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME
esm1   Ready    <none>   8d    v1.13.2   199.217.116.88   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
esm2   Ready    <none>   8d    v1.13.2   199.217.117.75   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
esm3   Ready    <none>   8d    v1.13.2   199.217.117.84   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
spw1   Ready    master   8d    v1.13.2   69.64.48.14      <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
```
The above command will show the available nodes and if it is functioning good ( Ready status means that the node is ready to deploy any of the containers)

If you want to inspect the node in detail use the below command.
```
$ kubectl describe node/NODE-NAME
```
NOTE: Replace NODE-NAME with the node name

**Configuration files for the deployment:**


There are no much files that are as needed for the deployment the only configuration file is the elasticsearch.yml. It contains all the configuration which is responsible to deploy and control the elasticsearch cluster on the kubernetes.

**How to deploy the elasticsearch cluster:**
```
$ kubectl apply -f elasticsearch.yml
service/elasticsearch created
service/elasticsearch-data created
service/elasticsearch-dat-master created
configmap/hotwarm-config created
configmap/curator-config created
configmap/cron-config created
statefulset.apps/elasticsearch-master created
deployment.apps/elasticsearch-data created
deployment.apps/elasticsearch-dat-master created

```
```
$ kubectl get pods
NAME                                 READY   STATUS              RESTARTS   AGE
elasticsearch-data-7dc7bb47f-2qx24   1/1     Running             0          25s
elasticsearch-data-7dc7bb47f-ttvx7   1/1     Running             0          25s
elasticsearch-master-0               1/1     Running             0          25s
elasticsearch-master-1               1/1     Running             0          13s
elasticsearch-master-2               0/1     ContainerCreating   0          0s
```
To check which node is running the respective container use the below command.
For the master nodes.
```
$ kubectl describe pod/<POD_NAME>
eg:kubectl describe pod/elasticsearch-master-0
Name:               elasticsearch-master-0
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               esm1/199.217.116.88
Start Time:         Fri, 25 Jan 2019 20:29:19 +0530
Labels:             app=elasticsearch-master
                    controller-revision-hash=elasticsearch-master-67bb5fbb5d
                    statefulset.kubernetes.io/pod-name=elasticsearch-master-0
Annotations:        <none>
Status:             Running
IP:                 10.244.1.52
Controlled By:      StatefulSet/elasticsearch-master
......
......
```

This gives a lot of information of the container if one requires.

How to get the endpoint ip to use for the elasticsearch:

There are two ways how you can access the elastic cluster:
1)Once the cluster is deployed all the containers are placed behind a loadbalancer and the requests to elasticsearch can be made to the loadbalancer ip address.To get the ip-address of the loadbalancer follow the below steps.
```
$ kubectl get service/elasticsearch
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
elasticsearch   NodePort   10.102.27.94   <none>        9200:30183/TCP,9300:30568/TCP   14m
```
note that the "CLUSTER-IP" displayed in the above step is the ip address of the elastic cluster. This can be specified in the logstash,kibana or other applications which utilizes the elasticsearch configuration files. Also, note that inorder to make applications that reside outside kubernetes cluster to contact the cluster-ip there has to be a route set in the machine specifying the next hop of 10.244.0.0/16 to be 69.64.48.14.

example: use the below command.
```
$ ip route add 10.244.0.0/16 via 69.64.48.14
```
if it is a cloud provider please contact the cloud provider how to add additional routes in the network. There should be a way how it can be configured globally.
In this case the endpoint which has to be used to access the cluster is http://10.102.27.94:920

2)The elasticsearch is also exposed on the public ip address of any of the kubernetes cluster node on a port.To get the port on which it is exposed follow the below steps.
```
$ kubectl get service/elasticsearch
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
elasticsearch   NodePort   10.102.27.94   <none>        9200:30183/TCP,9300:30568/TCP   14m
```
In the port section of the output get the port number beside "9200:". in the above case the node port on which the elastic cluster is exposed is 30183.

In this case the endpoint which has to be used to access the elasticsearch cluster is http://<ANY-OF-KUBERNETES-CLUSTER-NODE-IP>:30183  (ANY-OF-KUBERNETES-CLUSTER-NODE-IP refers to any of the node in the kubernetes cluster)
example:

```
$ kubectl get nodes -o wide
NAME   STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME
esm1   Ready    <none>   8d    v1.13.2   199.217.116.88   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
esm2   Ready    <none>   8d    v1.13.2   199.217.117.75   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
esm3   Ready    <none>   8d    v1.13.2   199.217.117.84   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
spw1   Ready    master   8d    v1.13.2   69.64.48.14      <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://1.13.1
```
In the above case we can use http://69.64.48.14:30183 or http://199.217.116.88:30183 or any of the node ip

NOTE: In the second case please make sure that if the kubernetes nodes are  in the cloud environment the security- groups should allow the "nodeport" otherwise you cannot access the cluster.

How to scale the cluster:
------------------------
The cluster supports 3 type of node types:
1) master
2) data
3) master/data
If required you can increase and decrease the size of the cluster. Use the below command to scale the cluster to desired size.

To scale the data nodes use the below command:
*********************************************
```
$ kubectl scale --replicas=3 deployment/elasticsearch-data
deployment.extensions/elasticsearch-data scaled

$ kubectl get pods
NAME                                  READY   STATUS              RESTARTS   AGE
elasticsearch-data-866789ddd8-n727r   1/1     Running             0          33m
elasticsearch-data-866789ddd8-rzt67   0/1     ContainerCreating   0          5s
elasticsearch-data-866789ddd8-zjq9g   1/1     Running             0          33m
elasticsearch-master-0                1/1     Running             0          33m
elasticsearch-master-1                1/1     Running             0          33m
elasticsearch-master-2                1/1     Running             0          33m
```
To scale the master nodes use the below command:
************************************************
```
$ kubectl scale --replicas=4 statefulset/elasticsearch-master
statefulset.apps/elasticsearch-master scaled

$ kubectl get pods
NAME                                  READY   STATUS              RESTARTS   AGE
elasticsearch-data-866789ddd8-kdff2   1/1     Running             0          61s
elasticsearch-data-866789ddd8-n727r   1/1     Running             0          36m
elasticsearch-data-866789ddd8-nt2m2   1/1     Running             1          61s
elasticsearch-data-866789ddd8-rzt67   1/1     Running             0          2m47s
elasticsearch-data-866789ddd8-tlz7p   1/1     Running             0          61s
elasticsearch-data-866789ddd8-zjq9g   1/1     Running             0          36m
elasticsearch-master-0                1/1     Running             0          36m
elasticsearch-master-1                1/1     Running             0          36m
elasticsearch-master-2                1/1     Running             0          36m
elasticsearch-master-3                0/1     ContainerCreating   0          6s
```

To scale the data/master nodes use the below command:
***********************************************
```
$ kubectl scale --replicas=3 deployments/elasticsearch-dat-master
deployment.extensions/elasticsearch-dat-master scaled

$ kubectl get pods
NAME                                       READY   STATUS              RESTARTS   AGE
elasticsearch-dat-master-74c96c86f-ftk4x   0/1     ContainerCreating   0          6s
elasticsearch-dat-master-74c96c86f-kgscd   0/1     ContainerCreating   0          6s
elasticsearch-dat-master-74c96c86f-tgphw   0/1     ContainerCreating   0          6s
elasticsearch-data-866789ddd8-kdff2        1/1     Running             0          18h
elasticsearch-data-866789ddd8-n727r        1/1     Running             0          19h
elasticsearch-data-866789ddd8-rzt67        1/1     Running             0          18h
elasticsearch-data-866789ddd8-ssnlc        1/1     Running             0          18h
elasticsearch-data-866789ddd8-tlz7p        1/1     Running             0          18h
elasticsearch-data-866789ddd8-zjq9g        1/1     Running             0          19h
elasticsearch-master-0                     1/1     Running             0          19h
elasticsearch-master-1                     1/1     Running             0          19h
elasticsearch-master-2                     1/1     Running             0          19h
```

NOTE: you should be very catious while scaling the cluster. If the scale value is below than the existing nodes the cluster might shrink. So always before scaling try to first check the current master or data nodes  size and scale accordingly.To check the current sizes use the below commands.

**To check the size of the master nodes:**
```
$ kubectl get statefulset/elasticsearch-master
NAME                   READY   AGE
elasticsearch-master   3/3     19h
```
**To check the size of the data nodes:**
```
$ kubectl get deployments/elasticsearch-data
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
elasticsearch-data   6/6     6            6           19h
```
**To check the size of the data/master nodes:**
```
$ kubectl get deployments/elasticsearch-dat-master
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
elasticsearch-dat-master   3/3     3            3           19h
```
**How to change the configurations for the elassticsearch cluster:**

All the configurations can be tweaked from the main cluster deployment yml file and can be changed on the fly for the cluster.

1) To change the cluster properties for master node change the "env" property  in the below section of the elasticsearch.yml
```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: StatefulSet
metadata:
  name: elasticsearch-master
  labels:
    app: elasticsearch-master
.....
.....
```

2) To change the cluster properties for data node change the "env" property in the below section of the elasticsearch.yml
```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: elasticsearch-data
  labels:
    app: elasticsearch-data
.....
.....
```

3) To change the cluster properties for data/master node change the "env" property in the below section of the elasticsearch.yml
```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: elasticsearch-dat-master
  labels:
    app: elasticsearch-dat-master
....
....
```
4) To change the curator configurations  for the hotwarm configurations edit the below section in the elasticsearch.yml
```
kind: ConfigMap
apiVersion: v1
metadata:
  name:  hotwarm-config
  labels:
    app: hotwarm-config
.....
....
```
5) To change the curator configurations edit the below section in the elasticsearch.yml
```
kind: ConfigMap
apiVersion: v1
metadata:
  name:  curator-config
  labels:
    app: curator-config
.....
....
```
Once the configuration is edited, issue the below command.
```
$ kubectl apply -f elasticsearch.yml
```
**How to extend the kubernetes cluster:**
If you want to scale the kubernetes cluster follow the below steps:

1) Turnoff the firewalld service.
```
$ systemctl stop firewalld
```
2) Turnoff the selinux set the "SELINUX" property to disabled in /etc/selinux/config file. A reboot is required for the selinux to be deactivated.

3) Kubernetes doesnot support swap so disable the swap if any in the /etc/fstab.

4) configure repositories for the installation of the docker packages.
```
$ yum install epel-release -y
```
5) Install the docker package.
```
$ yum install docker -y
```
6) start the docker service and make it active on the reboot.
```
$ systemctl start docker
$ systemctl enable docker
```

7) configure the yum repositories for the installation of kubernetes packages.
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
```
8) Install the packages for the kubernetes.
```
$ yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```
9) Start the kubernetes services.
```
$ systemctl enable kubelet && systemctl start kubelet
```
10) set the systemctl parametes.
```
$ cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sysctl --system
```
11) Once all the above steps are done successfully, Run the below command to bring the node into the cluster.
```
$ kubeadm join 69.64.48.14:6443 --token dxmy0d.9adxmya3cmx9w5q8 --discovery-token-ca-cert-hash sha256:8548c4f002eaf127d5dc6b1d22bc7709e4d8a32a3e557cf41c977d6ce45867b4
```
12) Import the image required for the container into the new node using the elasticsearch-curator.tar.
```
$ docker load -i elasticsearch-curator.tar 
```
Once the above commands are executed, it will bring the node into the kubernetes cluster.


Destroy the cluster:
===================
use the below commad to destroy the cluster.
```
$ kubectl delete -f elasticsearch.yml
service "elasticsearch" deleted
service "elasticsearch-data" deleted
service "elasticsearch-dat-master" deleted
configmap "hotwarm-config" deleted
configmap "curator-config" deleted
configmap "cron-config" deleted
statefulset.apps "elasticsearch-master" deleted
deployment.apps "elasticsearch-data" deleted
deployment.apps "elasticsearch-dat-master" deleted
```