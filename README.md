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

This will update www.domain.tld to the current public IP of the client you running the script. -l will write an log output. Because -k <key> is not specified the script search for a *.private file in the same folder of the script and use it in case there is just one found. As long as no -s <server> is specified the primary nameserver of the domain will be picked out of the MNAME filed from the SOA record. Make sure this point to the right server. 
```
./ddnsupd.sh -fv -D domain.tld -H www -l log.log
```
or using Batch-Mode by modify the example.conf file. After the domain name you can add multiple hostnames if you wish. All will be updated with the same IP in case you want to use multiple services with different names behind the same IP. E.g. smtp, www, imap......
Then run ddnsupd.sh as follows:
```
./ddnsupd.sh -f -c example.conf -A
```

6. Create a cron job to continously keep the IP updated

## BIND9 Server configuration:

Adjust named.conf and modify "allow-update" with the coresponding key from Step 1
```
zone "domain.tld" IN {
        type master;
        ...
        allow-update { key "domain.tld."; };
        ...
};

key "domain.tld." {
	algorithm hmac-md5;
	secret "<paste your Key here>";
};
```

The Zone File itself shouldn't containt the entry you like to dynamically add. The script will take care of and bind will update the zone file anyway. 