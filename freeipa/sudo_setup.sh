#!/bin/bash
# Configures Sudo for FreeIPA
#
# Usually nothing needs to be changed, although you
# can specify a kerberos server or a comma-seperated
# list of LDAP URI's instead of or in addition to
# the DNS SRV records.

KRB5_SERVER="_srv_"
LDAP_URI="_srv_"

######################################################################################
# Generally shouldn't need to touch anything down here.

freeipa_realm=$(grep default_realm /etc/krb5.conf | cut -d"=" -f2 | tr -d ' ')
freeipa_domain=$(grep default_domain /etc/krb5.conf | cut -d"=" -f2 | tr -d ' ')
freeipa_dn=$(for word in $(echo $freeipa_domain | sed 's/\./ /g'); do echo -n dc=$word,; done)

sssd_version=$(rpm -q --queryformat '%{VERSION}' sssd)
sssd_major=$(echo $sssd_version | cut -f1 -d.)
sssd_minor=$(echo $sssd_version | cut -f2 -d.)
ldap_config=$(mktemp)

if [[ $sssd_minor -ge 11 || $sssd_major -gt 1 ]];
then
    echo "sudo_provider = ipa" > $ldap_config
else

cat <<EOF > $ldap_config
sudo_provider = ldap
ldap_uri = $LDAP_URI
ldap_sudo_search_base = ou=SUDOers,${freeipa_dn%?}
ldap_sasl_mech = GSSAPI
ldap_sasl_authid = host/$HOSTNAME
ldap_sasl_realm = $freeipa_realm
krb5_server = $KRB5_SERVER
EOF

fi

sed -i -e "/\[domain\/.*\]/ r $ldap_config" /etc/sssd/sssd.conf
sed -i -e "s/services = .*/\0, sudo/" /etc/sssd/sssd.conf

authconfig --nisdomain ${freeipa_domain} --update

if [[ $(rpm -qa systemd | wc -l) -gt 0 ]];
then
  domain_service=`ls /usr/lib/systemd/system/*-domainname.service | rev | cut -d'/' -f 1 | rev`
  systemctl start $domain_service
  systemctl enable $domain_service
fi

grep -q sudoers /etc/nsswitch.conf
if [[ $? -eq 0 ]];
then
  sed -i -e "s/^sudoers.*/sudoers:    files sss/" /etc/nsswitch.conf
else
  echo sudoers:    files sss >> /etc/nsswitch.conf
fi

chkconfig sssd on
service sssd restart
