# == Class: role_dockertreebase
#
# === Authors
#
# Author Name <hugo.vanduijn@naturalis.nl>
#
# === Copyright
#
# Apache2 license 2017.
#
class role_dockertreebase (
  $compose_version      = '1.17.1',
  $repo_source          = 'https://github.com/naturalis/docker-treebase.git',
  $repo_ensure          = 'latest',
  $repo_dir             = '/opt/treebase',
  $db_password          = 'PASSWORD',
  $lets_encrypt_mail    = 'mail@example.com',
  $traefik_toml_file    = '/opt/traefik/traefik.toml',
  $traefik_acme_json    = '/opt/traefik/acme.json',
  $siteUrl              = 'treebase.org',
  $siteSansUrl          = 'www.treebase.org'
){

  include 'docker'
  include 'stdlib'

  Exec {
    path => '/usr/local/bin/',
    cwd  => "${role_dockertreebase::repo_dir}",
  }

  file { ['/data','/opt/traefik'] :
    ensure              => directory,
  }

  file { $traefik_toml_file :
    ensure   => file,
    content  => template('role_dockertreebase/traefik.toml.erb'),
    require  => File['/opt/traefik'],
    notify   => Exec['Restart containers on change'],
  }

  file { $traefik_acme_json :
    ensure   => present,
    mode     => '0600',
    require  => File['/opt/traefik'],
    notify   => Exec['Restart containers on change'],
  }

  file { "${role_dockertreebase::repo_dir}/.env":
    ensure   => file,
    content  => template('role_dockertreebase/prod.env.erb'),
    require  => Vcsrepo[$role_dockertreebase::repo_dir],
    notify   => Exec['Restart containers on change'],
  }

  class {'docker::compose': 
    ensure      => present,
    version     => $role_dockertreebase::compose_version
  }

  package { 'git':
    ensure   => installed,
  }

  vcsrepo { $role_dockertreebase::repo_dir:
    ensure    => $role_dockertreebase::repo_ensure,
    source    => $role_dockertreebase::repo_source,
    provider  => 'git',
    user      => 'root',
    revision  => 'master',
    require   => Package['git'],
  }

  docker_network { 'web':
    ensure   => present,
  }

  docker_compose { "${role_dockertreebase::repo_dir}/docker-compose.yml":
    ensure      => present,
    require     => [ 
      Vcsrepo[$role_dockertreebase::repo_dir],
      File[$traefik_acme_json],
      File["${role_dockertreebase::repo_dir}/.env"],
      File[$traefik_toml_file],
      Docker_network['web']
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => Exec['Pull containers']
  }

  exec {'Restart containers on change':
    refreshonly => true,
    command     => 'docker-compose up -d',
    require     => Docker_compose["${role_dockertreebase::repo_dir}/docker-compose.yml"],
  }

  # deze gaat per dag 1 keer checken
  # je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
  schedule { 'everyday':
     period  => daily,
     repeat  => 1,
     range => '5-7',
  }

}
