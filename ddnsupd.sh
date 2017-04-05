#!/bin/bash
# ------------------------------------------------------------------
# [edfauler] ddnsups.sh
#           Dyndns service update script
#           This allows you to update your DNS entries with your
#           current public internet address
# ------------------------------------------------------------------

VERSION=0.9.0
SUBJECT=000
DDNSFILE="./ddnsupd.file"
DDNSLAST="./ddnsupd.last"

force=false
climode=true
verbose=false
write_zone_a_record=false
real=0

# --- Display Help --- -------------------------------------------
display_help() {
    echo "Usage: $0 [option...] -D domain.tld -H www" >&2
    echo
    echo "   -x             Execute nsupdate with the given parameters, if not specified nothing will be executed"
    echo "   -f             Force update even IP address is still the same"
    echo "   -v             Enable verose output"
    echo "   -D <domain>    Set Domainname domain.tld."
    echo "   -H <hostname>  Set Hostname which should be updated. Multiple -H entries are possible to update different hosts."
    echo "   -A             Set Zone File A-Record as well"
    echo "   -k <keyfile>   Name of keyfile *.private"
    echo "   -s <server>    FQDN of DDNS Server"
    echo "   -c <conf>      Provide a conf file with multiple entries. Content: domain.tld host1 host2"
    echo "                  One line per Domain. Keep in mind in Batch mode just one key is supported"
    echo "   -l <logfile>   Specify a logfile to write output"
    echo
    echo "Example: CLIMODE "
    echo "$0 -x -D domain.tld -H www -H vpn -H gp -A" >&2
    echo
    echo "This will update www.domain.tld, vpn.domain.tld, gp.domain.tld" 
    echo "and domain.tld to the current public facingIP address of the"
    echo "computer. Keep in mind if you like to host services behind that"
    echo "hostname to update you firewall forwarding / destination NAT entry"
    echo 
    echo "Example: BATCHMODE "
    echo "$0 -xA -c ddnsupd.conf" >&2
    exit 1
}

# --- Options processing -------------------------------------------
while getopts "xfvD:H:c:k:Al:h" opt; do
  case $opt in
    x)  execute=true ;;
    f)  force=true ;;
    v)  verbose=true ;;
    D)  SETDOMAIN=("$OPTARG") ;;
    H)  hosts+=("$OPTARG") ;;
    c)  DDNSCONF=("$OPTARG"); climode=false ;;
    k)  DDNSKEY=("$OPTARG") ;;
    A)  write_zone_a_record=true ;;
    l)  LOGFILE=("$OPTARG") ;;
    h)  display_help ;;
    \?) echo "Invalid option: -$OPTARG" >&2; display_help ;;
    : ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
  esac
done


# --- Functions ---------------------------------------------------
function v_echo
{
    #Verbose echo & Logging to write output to stdout or file
    if [ $verbose = true ]; then echo "$0 : $1"; fi
    if [ -v LOGFILE ]; then echo `date` $0 $1 >> $LOGFILE; fi
}

function get_primary_dnsserver
{
    for word in $(dig $SETDOMAIN soa +short); do
        DDNSSERVER=${word::-1}
        v_echo "SOA NS Server set to $DDNSSERVER automatically"
        break
    done
}


function find_keyfile
{    
    ddnskeycounter="$(find "./" -maxdepth 1 -type f -name '*.private' -printf .)"
    case "${#ddnskeycounter}" in
        1)  for dir in ./; do
                DDNSKEY="$(find "./" -type f -name '*.private')"
                v_echo "$DDNSKEY found" 
            done
            ;;
        0)  v_echo "No keyfile found. Please specify *.private keyfile location with -k ..."   
            exit 1
            ;;
        *)  v_echo "More than 1 keyfile found. Please specify *.private keyfile location with -k ..."
            exit 1
            ;;
    esac  
}


function check_valid_IP
{
    if [[ $1 =~ ^([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5]).([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5]).([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5]).([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5])+$ ]]; then
        v_echo "IP validation succeeded"
        return 0
    else
        v_echo "IP validation failed"
        return 1
    fi
}
 
function get_real_IP
{
    real=`wget -qO- 87.106.41.124/index.php`
    #echo $real
    check_valid_IP $real
    if [ $? -eq 1 ]
            then
            v_echo "Internet IP is not a valid IP $real"
                    exit 1
        else
            v_echo "Public facing IP address is $real"
            return 0
    fi
}


function send_nsupdate()
{
    domain=$1
    shift
    allhosts=("${@}")
    echo "server $DDNSSERVER" > $DDNSFILE
    echo "zone $domain" >> $DDNSFILE
    
    # If Option -A is set
    if [ "$write_zone_a_record" == "true" ]; then
            echo "update delete $domain.  A" >> $DDNSFILE
            echo "update add $domain. 60 A $real" >> $DDNSFILE
            v_echo "$domain updated - new ip $real"
    fi

    # Update DNS entry for each -H entry
    for val in "${allhosts[@]}"; do
            echo "update delete $val.$domain.  A" >> $DDNSFILE
            echo "update add $val.$domain. 60 A $real" >> $DDNSFILE
            v_echo "$val.$domain updated - new ip $real"
    done
    echo "show" >> $DDNSFILE
    echo "send" >> $DDNSFILE
    cat $DDNSFILE | while read LINE
        do
        v_echo " - nsupdate: $LINE"
    done
    #nsupdate -k $DDNSKEY -v $DDNSFILE
}

function check_if_update_required
{
    if [ -f $DDNSLAST ]
        then
            oldfile=`cat $DDNSLAST`
            check_valid_IP $oldfile
            if [ $? -eq 1 ]
                then
                    echo Not an IP
            fi
            if [ $real == $oldfile ]
                then
                    v_echo "IP $real nothing to update"
                    exit 0;
            fi
    fi
    v_echo "Old IP $oldfile, new IP $real"
}

# --- Body --------------------------------------------------------
v_echo "Started"
v_echo "Call -> $*"
if [ $write_zone_a_record = true ]; then v_echo "Zone A Record will be updated as well"; fi
if [ -v LOGFILE ]; then v_echo "Logging enabled; Filename: $LOGFILE"; fi

get_real_IP
if [ $force = "false" ]; then check_if_update_required; else v_echo "Force mode enabled"; fi
if [ -z ${DDNSKEY+x} ]; then find_keyfile; else v_echo "$DDNSKEY manually set"; fi


echo ${hosts[@]}
v_echo "CLIMODE = $climode"
if [ $climode = true ]; 
then
    send_nsupdate $SETDOMAIN ${hosts[@]}
else
    v_echo "Starting Batch Mode using $DDNSCONF"
    cat $DDNSCONF | while read LINE
        do
        arr=($LINE)
        SETDOMAIN=${arr[0]}
        hosts=()
        for ((i=1 ; i <= ${#arr[@]} ; i++))
            do
            hosts+=(${arr[$i]})
        done
        v_echo "Batchmode: New Domain $SETDOMAIN"
        get_primary_dnsserver
        v_echo "Batchmode: Domainhosts to update: "${hosts[@]}
        send_nsupdate $SETDOMAIN ${hosts[@]}
    done    
fi

echo $real > $DDNSLAST

rm $DDNSFILE
v_echo "Done"
# -----------------------------------------------------------------
