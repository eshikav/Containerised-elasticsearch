#!/bin/bash
crontab /etc/cron.d/curator-cron
crond
/usr/share/elasticsearch/plugins/search-guard-6/tools/install_demo_configuration.sh -y
/usr/local/bin/sgadmin-bringup.sh &
/usr/local/bin/docker-entrypoint.sh
