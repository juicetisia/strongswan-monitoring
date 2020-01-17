#!/bin/bash
#scv="measurement,tunnel,value\n"
json="["
tun_list=$(strongswan status | awk '{ print $1 }' | sed "s/[\{\[].*//" | grep -v "Security" | sort | uniq)
for tun in $tun_list
do
        tunnel_status=$(strongswan statusall $tun | grep -e "$tun{[0-9]*}: *INSTALLED")
        if [ $? -ne 0 ]; then
                eval "tunnel_status"=4
        else
                tunnel_connect=$(strongswan statusall $tun | grep -e "$tun\[[0-9]*\]: *ESTABLISHED")
                if [ $? -ne 0 ]; then
                        eval "tunnel_status"=1
                else
                        eval "tunnel_status"=0
                fi
                bytesIn=$(strongswan statusall $tun | grep $tun | grep -e "\([0-9]*\) bytes_i" | sed '/\([0-9]*\) bytes_i.*/s//\1/' | awk '{ print $NF }')
                bytesOut=$(strongswan statusall $tun | grep $tun | grep -e "\([0-9]*\) bytes_o" | sed '/\([0-9]*\) bytes_o.*/s//\1/' | awk '{ print $NF }')
                pkts=$(strongswan statusall $tun | grep $tun | grep pkts)
                if [ $? -eq 0 ]; then
                        packetsIn=$(strongswan statusall $tun | grep $tun | grep pkts | sed '/.*bytes_i (\([0-9]*\).*/s//\1/')
                        packetsOut=$(strongswan statusall $tun | grep $tun | grep pkts | sed '/.*bytes_o (\([0-9]*\).*/s//\1/')
                else
                        packetsIn=0
                        packetsOut=0
                fi
        fi
#                scv+="tunnel_status,$tun,$tunnel_status\npackets_in,$tun,$packetsIn\npackets_out,$tun,$packetsOut\nbytes_in,$tun,$bytesIn\nbytes_out,$tun,$bytesOut\n"
                json+="{\"tunnel_status\":$tunnel_status, \"tunnel\":\"$tun\", \"tunnel_packets_in\":$packetsIn, \"tunnel_packets_out\":$packetsOut, \"tunnel_bytes_in\":$bytesIn, \"tunnel_bytes_out\":$bytesOut},"
done

json2=${json%?}
json2+="]"
echo -e $json2
