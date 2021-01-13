#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

responseCode=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://www.arvancloud.com/fa/ips.txt)

# do only, if adresse is reachable
if [ "$responseCode" == "200" ] ; then

    echo "Extraction of ArvanCloud IPs started ...";
    echo '';

    ARVAN_FILE_PATH=/etc/nginx/conf.d/arvan.conf

    echo "#ARVANCLOUD" > $ARVAN_FILE_PATH;
    echo "" >> $ARVAN_FILE_PATH;

    for i in `curl https://www.arvancloud.com/fa/ips.txt`; do
            echo "set_real_ip_from $i;" >> $ARVAN_FILE_PATH;
    done

    echo "" >> $ARVAN_FILE_PATH;
    echo "real_ip_header AR_REAL_IP;" >> $ARVAN_FILE_PATH;

    #test configuration and reload nginx
    nginx -t && systemctl reload nginx

    # Run script every dat at 1 AM
    updateArvanIps="0 1 * * * /usr/local/bin/ar-ngxrealip.sh"

    (crontab -l ; echo "$updateArvanIps" ) | crontab -

    sed '30,39d' ar-ngxrealip.sh >> /usr/local/bin/ar-ngxrealip.sh

    chmod +x /usr/local/bin/ar-ngxrealip.sh

else
    echo "ArvanCloud IPs is not accessible!";

fi
