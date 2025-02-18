#This is a script to add a Ubuntu server to a Windows Domain

$server = "10.14.2.211"


$scriptblock = {
#Installs the required packages
    sudo apt update
    sudo apt install realmd sssd adcli krb5-user samba-common packagekit
#Configure the kerberos file so the server can communicate with the domain
    echo "
        [libdefaults]
            default_realm = jens.jon
            dns_lookup_realm = false
            dns_lookup_kdc = true

        [realms]
            YOURDOMAIN.COM = {
            kdc = jondc.jens.jon
            admin_server = jondc.jens.jon
            }

        [domain_realm]
            .yourdomain.com = jens.jon
            yourdomain.com = jens.jon
        " > /etc/krb5.conf
#Joins the domain
    sudo realm join --user=Administrator jens.jon
}
Invoke-Command -HostName $server -ScriptBlock $scriptblock -Credential (Get-Credential) -Authentication Basic -Port 22
