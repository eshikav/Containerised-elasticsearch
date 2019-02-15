output=1
until [ $output == 0 ]
do
/usr/share/elasticsearch/sgadmin_demo.sh
output=$?
done
