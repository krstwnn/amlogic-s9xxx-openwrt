#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: DIY script (After updating feeds — modify the default IP, hostname, theme, add/remove packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source configuration -------------------------------
#
# Set the default LAN IP address
default_ip="192.168.1.1"
ip_regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
# Override default IP if a valid custom IP is provided as the first argument
[[ -n "${1}" && "${1}" != "${default_ip}" && "${1}" =~ ${ip_regex} ]] && {
    echo "Modify default IP address to: ${1}"
    sed -i "/lan) ipad=\${ipaddr:-/s/\${ipaddr:-\"[^\"]*\"}/\${ipaddr:-\"${1}\"}/" package/base-files/*/bin/config_generate
}

# Set the default password for the 'root' user (change empty password to 'password')
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Append source repository information to etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCEREPO='github.com/immortalwrt/immortalwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCEBRANCH='master'" >>package/base-files/files/etc/openwrt_release

# Configure ccache for build acceleration
# Remove existing ccache settings
sed -i '/CONFIG_DEVEL/d' .config
sed -i '/CONFIG_CCACHE/d' .config
# Apply new ccache configuration
if [[ "${2}" == "true" ]]; then
    echo "CONFIG_DEVEL=y" >>.config
    echo "CONFIG_CCACHE=y" >>.config
    echo 'CONFIG_CCACHE_DIR="$(TOPDIR)/.ccache"' >>.config
else
    echo '# CONFIG_DEVEL is not set' >>.config
    echo "# CONFIG_CCACHE is not set" >>.config
    echo 'CONFIG_CCACHE_DIR=""' >>.config
fi
#
# ------------------------------- Main source configuration ends -------------------------------

# ------------------------------- Additional customizations -------------------------------
#
# Add luci-app-amlogic
rm -rf package/luci-app-amlogic
git clone -b main https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic

# 1. Mengubah Hostname (Nama Router)
sed -i 's/ImmortalWrt/KrstwnWRTx/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/KrstwnWRTx/g' package/base-files/files/bin/config_generate

# 2. Menambahkan Nama di Tampilan Terminal (Banner SSH)
echo "   -----------------------------------------------------" >> package/base-files/files/etc/banner
echo "           Build by Krstwnn | OpenWrt Amlogic          " >> package/base-files/files/etc/banner
echo "   -----------------------------------------------------" >> package/base-files/files/etc/banner

# 3. Mengubah Password Default Root
# (Membuat script yang akan otomatis berjalan saat router pertama kali dinyalakan)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-pass
#!/bin/sh
echo -e "root\nroot" | passwd root
exit 0
EOF

# 4. Menambahkan nama builder di informasi versi LuCI
sed -i 's/DISTRIB_DESCRIPTION="\(.*\)"/DISTRIB_DESCRIPTION="\1 by Krstwnn"/g' package/base-files/files/etc/openwrt_release

# Apply patches
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Additional customizations ends -------------------------------

