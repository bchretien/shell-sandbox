#!/bin/sh
# Share internet connection. For instance, to share the Ethernet connection
# over Wi-Fi:
# ./share_wifi.sh start wlan0 eth0
#
# Based on: http://cs.iupui.edu/~pengw/writing/wifi-ap-on-laptop.html
# Modified and tested for: Arch Linux

DEFAULT_SSID="My_SSID"
DEFAULT_PASSWORD="My_Password"

usage () {
    echo "`basename $0` <start|stop> <ap if> <outbound if> "\
        "[ssid=DEFAULT_SSID] [psk=DEFAULT_PASSWORD]" >&2
}

setup_hostapd () {
    local ap_if=$1
    local ssid=$2
    local psk=$3

    cat > ~/hostapd.conf <<-END
    interface=$ap_if
    driver=nl80211

    logger_syslog=-1
    logger_syslog_level=2
    logger_stdout=-1
    logger_stdout_level=2

    dump_file=/tmp/hostapd.dump

    ctrl_interface=/var/run/hostapd
    ctrl_interface_group=wheel

    ssid=$ssid

    hw_mode=g
    channel=3

    max_num_sta=255

    macaddr_acl=0
    accept_mac_file=/etc/hostapd/hostapd.accept
    deny_mac_file=/etc/hostapd/hostapd.deny

    auth_algs=1

    ignore_broadcast_ssid=0

    wpa=2 # RSN only

    wpa_passphrase=$psk
    wpa_key_mgmt=WPA-PSK
    #wpa_pairwise=TKIP
    rsn_pairwise=CCMP

    END

    [ -f /etc/hostapd/hostapd.conf ] && sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak
    sudo mv ~/hostapd.conf /etc/hostapd/
    sudo chown root:root /etc/hostapd/hostapd.conf
}

restore_hostapd () {
    [ -f /etc/hostapd/hostapd.conf.bak ] && sudo cp /etc/hostapd/hostapd.conf.bak /etc/hostapd/hostapd.conf  
}

setup_dhcp4 () {
    local ap_if=$1

    cat > ~/dhcpd <<-END
    #
    # Arguments to be passed to the DHCP server daemon
    #

    # ipv4 runtime parameters
    DHCP4_ARGS="-q $ap_if"

    # ipv6 runtime parameters
    DHCP6_ARGS="-q"
    END
    [ -f /etc/conf.d/dhcpd ] && sudo cp /etc/conf.d/dhcpd /etc/conf.d/dhcpd.bak
    sudo mv ~/dhcpd /etc/conf.d/
    sudo chown root:root /etc/conf.d/dhcpd

    cat > ~/dhcpd.conf <<-END
    # dhcpd.conf
    #
    # Sample configuration file for ISC dhcpd
    #

    option domain-name "voidstar.info";

    default-lease-time 600;
    max-lease-time 7200;

    log-facility local7;


    subnet 10.1.1.0 netmask 255.255.255.0 {
    option domain-name "voidstar.info";
    option domain-name-servers 8.8.8.8;
    max-lease-time 3600;
    default-lease-time 600;

    range 10.1.1.10 10.1.1.240;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.1.1.255;
    option routers 10.1.1.1;
}
END
[ -f /etc/dhcpd.conf ] && sudo cp /etc/dhcpd.conf /etc/dhcpd.conf.bak
sudo mv ~/dhcpd.conf /etc/
sudo chown root:root /etc/dhcpd.conf

}

restore_dhcp4 () {
    [ -f /etc/dhcpd.conf.bak ] && sudo cp /etc/dhcpd.conf.bak /etc/dhcpd.conf
}

sudo -v

action=$1
ap_if=$2
if [ -n "$3" ]; then
    outbound_if=$3
else
    usage
    exit 1
fi

[ -n "$4" ] && ssid=$4 || ssid=$DEFAULT_SSID
[ -n "$5" ] && psk=$5 || psk=$DEFAULT_PASSWORD

if [[ ${#psk} -lt 8 ]] || [[ ${#psk} -gt 63 ]]; then
    echo "psk must be between 8 and 63 characters" >& 2
    exit 2
fi

case "$1" in

    "start")
        setup_hostapd "$ap_if" "$ssid" "$psk"
        sudo systemctl start hostapd
        sudo ip addr add 10.1.1.1/24 dev "$ap_if"
        setup_dhcp4 "$ap_if"
        sudo systemctl start dhcpd4
        sudo systemctl restart iptables
        sudo iptables -t nat -A POSTROUTING -s 10.1.1.0/24 -o "$outbound_if" -j MASQUERADE
        ;;

    "stop")
        sudo iptables -t nat -D POSTROUTING -s 10.1.1.0/24 -o "$outbound_if" -j MASQUERADE
        sudo systemctl restart iptables
        sudo systemctl stop dhcpd4
        restore_dhcp4
        sudo ip addr del 10.1.1.1/24 dev "$ap_if"
        sudo systemctl stop hostapd
        restore_hostapd
        ;;

    *)
        usage
        exit 1
esac

