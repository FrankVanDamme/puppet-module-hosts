# == Class: hosts
#
# Manage /etc/hosts
#
class hosts (
  Boolean $collect_all                         = false,
  Boolean $enable_ipv4_localhost               = true,
  Boolean $enable_ipv6_localhost               = true,
  Boolean $enable_fqdn_entry                   = true,
  Boolean $use_fqdn                            = true,
  Variant[Array,String] $fqdn_host_aliases     = $facts[networking][hostname],
  String $fqdn_ip                              = $facts[networking][ipaddress],
  Variant[Array,String] $localhost_aliases     = [
      'localhost',
      'localhost4',
      'localhost4.localdomain4'
  ],
  Array $localhost6_aliases                    = [
    'localhost6',
    'localhost6.localdomain6'
  ],
  Boolean $purge_hosts                          = false,
  String $target                                = '/etc/hosts',
  Hash $host_entries                            = {},
) {


  if $enable_ipv4_localhost == true {
    $localhost_ensure     = 'present'
    $localhost_ip         = '127.0.0.1'
    $my_localhost_aliases = $localhost_aliases
  } else {
    $localhost_ensure     = 'absent'
    $localhost_ip         = '127.0.0.1'
    $my_localhost_aliases = undef
  }

  if $enable_ipv6_localhost == true {
    $localhost6_ensure     = 'present'
    $localhost6_ip         = '::1'
    $my_localhost6_aliases = $localhost6_aliases
  } else {
    $localhost6_ensure     = 'absent'
    $localhost6_ip         = '::1'
    $my_localhost6_aliases = undef
  }

  if $enable_fqdn_entry == true {
    $fqdn_ensure          = 'present'
    $my_fqdn_host_aliases = $fqdn_host_aliases
  } else {
    $fqdn_ensure          = 'absent'
    $my_fqdn_host_aliases = []
  }

  Host {
    target => $target,
  }

  host { 'localhost':
    ensure => 'absent',
  }

  host { 'localhost.localdomain':
    ensure       => $localhost_ensure,
    host_aliases => $my_localhost_aliases,
    ip           => $localhost_ip,
  }

  host { 'localhost6.localdomain6':
    ensure       => $localhost6_ensure,
    host_aliases => $my_localhost6_aliases,
    ip           => $localhost6_ip,
  }

  if $facts[networking][fqdn] == true {
    @@host { $facts[networking][fqdn]:
      ensure       => $fqdn_ensure,
      host_aliases => $my_fqdn_host_aliases,
      ip           => $fqdn_ip,
    }

    case $collect_all {
      # collect all the exported Host resources
      true:  {
        Host <<| |>>
      }
      # only collect the exported entry above
      default: {
        Host <<| title == $facts[networking][fqdn] |>>
      }
    }
  }

  resources { 'host':
    purge => $purge_hosts,
  }

  $host_entries_real = delete($host_entries,$facts[networking][fqdn])
  create_resources(host,$host_entries_real)
}
