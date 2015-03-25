#!/bin/bash

# FIRST DRAFT
# DNSSEC
# SIGN DNS CPANEL WITH DNNSEC
#
# ALPHA SOFTWARE
# The code is alpha, and will eat your lunch and kill your kittens.


# CREATE THE DOMAIN ARRAY LIST
cd /var/named/
DOMINIOS=($(grep -l -v "\$INCLUDE" *))


# CREATE DS KEYS IN /etc/bind/keys
cd /etc/bind/keys/
DNSKEYPATH=/etc/bind/keys/

for i in "${DOMINIOS[@]}"
do

        # REMOVE 'db' extension from file name (ex.: domain.com.db -> domain.com)
        DOM=`echo $i | rev | cut -c 4- | rev`

        # CHECK IF THE DOMAIN ALREADY HAVE A DNSSEC KEY
        if [ -d $DNSKEYPATH$DOM ]; then

				# DEBUG
        echo "Folder $DNSKEYPATH$DOM already exists"

        # FOLDER WITH THE DOMAIN NAME EXIST, SO WE HAVE DNSSEC KEY ALREADY CREATED
				# LETS SIGN
				
                #LET's SIGN THE ZONES
                for key in `ls $DNSKEYPATH$DOM/*.key`
                do
#                       echo "\$INCLUDE $key"
                        echo "\$INCLUDE $key">> /var/named/$i

                        cd $DNSKEYPATH$DOM
                        dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N INCREMENT -o $DOM -t /var/named/$i

						
                        #CHANGE NAMED.CONF TO POINT TO THE DNSSEC DB FILES
                        sed -i 's/$i\"/$i.signed/gi' /tmp/named.conf
                done


        else
                #Hum...NO KEYS FOR THE DOMAIN, LETS CREATE THEM

                # CREATE DNSSEC KEY FOLDER
                mkdir $DNSKEYPATH$DOM

                cd $DNSKEYPATH$DOM
                
				# CREATE THE ZSK KEY

                dnssec-keygen -a NSEC3RSASHA1 -b 2048 -n ZONE $DOM

                # CREATE THE KSK KEY
                dnssec-keygen -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE $DOM

                cd ..
        fi
done

