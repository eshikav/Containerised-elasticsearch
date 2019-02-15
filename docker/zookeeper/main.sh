ZOO_ID_PATH=/tmp/zookeeper
cp /conf/zoo_sample.cfg /conf/zoo.cfg
for (( i=0; i<$ZOO_CLUSTER_SIZE;i++ ))
do
echo "server.$i=zookeeper-$i.zookeeper.default.svc.cluster.local:2888:3888" >> /conf/zoo.cfg
done

echo "Setting the id for the zookeeper node"
mkdir -p /tmp/zookeeper
eval $ZOOID_BUILD_COMMAND > $ZOO_ID_PATH/myid

/zookeeper-3.4.13/bin/zkServer.sh start-foreground zoo.cfg
