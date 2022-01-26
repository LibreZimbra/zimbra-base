# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (C) Enrico Weigelt, metux IT consult <info@metux.net>

[ "$ZIMBRA_ROOT"            ] || ZIMBRA_ROOT="/opt/zimbra"
[ "$ZIMBRA_USER"            ] || ZIMBRA_USER="zimbra"
[ "$ZIMBRA_GROUP"           ] || ZIMBRA_GROUP="zimbra"
[ "$ZIMBRA_BINDIR"          ] || ZIMBRA_BINDIR="$ZIMBRA_ROOT/bin"
[ "$ZM_CONFDIR"             ] || ZM_CONFDIR="$ZIMBRA_ROOT/conf"
[ "$ZM_CA_DIR"              ] || ZM_CA_DIR="$ZM_CONFDIR/ca"
[ "$ZM_LDAP_BINDIR"         ] || ZM_LDAP_BINDIR="$ZIMBRA_ROOT/common/bin"
[ "$ZM_LDAP_LIBEXECDIR"     ] || ZM_LDAP_LIBEXECDIR="$ZIMBRA_ROOT/common/libexec"
[ "$ZM_LDAP_ZIMBRA_DN"      ] || ZM_LDAP_ADMIN_DN="uid=zimbra,cn=admins,cn=zimbra"
[ "$ZM_JKS_PASSWORD"        ] || ZM_JKS_PASSWORD="librelibre" # must be at least 6 chars

zm_log_info() {
    echo "<INFO> $*" >&2
}

zm_log_err() {
    echo "<ERR> $*" >&2
}

zm_chown() {
    chown -R "$ZIMBRA_USER:$ZIMBRA_GROUP" "$@"
}

zm_server_create() {
    local nodename="$1"
    local uuid=`uuid`

    # FIXME: should support specific zimbraIPMode
    zm_log_info "creating server entry: $nodename"
    (
        echo "dn: cn=$nodename,cn=servers,cn=zimbra"
        echo "changetype: add"
        echo "objectClass: zimbraServer"
        echo "cn: $nodename"
        echo "zimbraId: $uuid"
        echo "zimbraIPMode: ipv4"
    ) | zm_ldapmodify
}

zm_server_enable_service() {
    local nodename="$1"
    local service="$2"

    zm_log_info "updating server entry: $nodename"
    (
        echo "dn: cn=$nodename,cn=servers,cn=zimbra"
        echo "changetype: modify"
        echo "add: zimbraServiceInstalled"
        echo "zimbraServiceInstalled: $service"
        echo "-"
        echo "add: zimbraServiceEnabled"
        echo "zimbraServiceEnabled: $service"
    ) | zm_ldapmodify
}

zm_localconfig_set() {
    local name="$1"
    shift
    local value="$@"
    zm_log_info "setting localconfig $name=$value"
    LOGNAME=$ZIMBRA_USER $ZIMBRA_BINDIR/zmlocalconfig -f -e "$name=$value"
    zm_chown $ZM_CONFDIR/localconfig.xml
}

zm_init_datatmp() {
    mkdir -p $ZIMBRA_ROOT/data/tmp
    zm_chown $ZIMBRA_ROOT/data/tmp
}

zm_globalconf_set() {
    local attr="$1"
    local val="$2"

    if [ ! "$val" ]; then
        zm_log_info "removing global config: $attr"
        (
            echo "dn: cn=config,cn=zimbra"
            echo "changetype: modify"
            echo "delete: $attr"
        ) | zm_ldapmodify
    else
        zm_log_info "setting global config: $attr = $val"
        (
            echo "dn: cn=config,cn=zimbra"
            echo "changetype: modify"
            echo "replace: $attr"
            echo "$attr: $val"
        ) | zm_ldapmodify
    fi
}

zm_convert_p12_jks() {
    local p12="$1"
    local jks="$2"
    zm_log_info "installing p12 $p12 into jks $jks"

    keytool -importkeystore \
            -srckeystore "$p12" \
            -srcstoretype PKCS12 \
            -srcstorepass "" \
            -destkeystore "$jks" \
            -deststorepass "$ZM_JKS_PASSWORD"
    return $?
}
