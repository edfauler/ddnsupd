# ddnsupd
!!! Still in Developement!!!

Small Script for dynamic DNS updates

How does is work:

It uses nsupdate and DNSSEC keys to update or add a host entry to a bind DNS server zone file. Of course this can be done with nsupdate and a more static script but I have multiple domains and locked for a dyndns setup which doesn't require a subscription.

## Recommendations
The script require nsupdate and wget to run. If not installed you can install them as following

```
sudo apt-get install dnsutils
sudo apt-get install wget
```

## Client configuration:

1. Clone the Github project
2. Create a DNSSEC key e.g. 

```
dnssec-keygen -a HMAC-MD5 -b 512 -n HOST domain.tld.
```

3. Copy the Key to your clipboard to paste it later into your BIND conf file.

```
cat Kdomain.tld.+157+22940.key 
weflashit.de. IN KEY 512 3 157 kjldsjfieKJLKSDJLK§JLSJDLKSLKDNLKFLDKGLKJLS999F92CM0R0X39R3R0293==
```
4. Make the ddnsupd.sh file executable

```
chmod +x ddnsupd.sh
```

5. Test the script
```
./ddnsupd.sh -f -c example.conf -A
```
or
```
./ddnsupd.sh -fv -D domain.tld -H www -l log.log
```

6. Create a cron job to continously keep the IP updated

## BIND9 Server configuration:

tbd
