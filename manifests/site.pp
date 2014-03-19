group { "puppet":
  ensure => present,
}

# Hash Generator: http://www.insidepro.com/hashes.php?lang=eng
$pass2 = 'XXX'
$pass2mysql5hash = '*F1932B6BFE93D66B43F9A3EB5ECF8A5C90C32053'

########### Mysql Setup
class { '::mysql::server':
  root_password => $pass2,
  users => {
    'root@%' => {
      ensure => 'present',
      password_hash => $pass2mysql5hash
    }
  },
  databases => {
    'myDB' => {
      ensure => 'present',
      charset => 'utf8'
    }
  },
  grants => {
    'root@%/*.*' => {
      ensure => 'present',
      options => ['GRANT'],
      privileges => ['ALL'],
      table => '*.*',
      user => 'root@%'
    }
  },
  override_options => {
    'mysqld' => {
      'bind-address' => undef, # allow remote login
    }
  },
  restart => true,
}
include '::mysql::server'

########### Apache Setup
class { 'apache':
  mpm_module => prefork,
  default_vhost => false
}

apache::vhost { 'http':
  port => '80',
  docroot => '/var/www',
  custom_fragment => '
    DBDriver mysql
    DBDParams "dbname=myDB,user=root,pass=XXX"
    DBDMin  4
    DBDKeep 8
    DBDMax  20
    DBDExptime 300  
    <Location /private>
      AuthFormProvider dbd
      AuthType form
      AuthName private
      Session On
      SessionCookieName session path=/
      #SessionCryptoPassphrase secret
      ErrorDocument 401 /login.html
      # mod_authz_core configuration
      Require valid-user
      # mod_authn_dbd SQL query to authenticate a user
      AuthDBDUserPWQuery "SELECT password FROM user WHERE username = %s"
    </Location>'
}

include apache::mod::prefork
include apache::mod::php
apache::mod { 'authn_core': }
apache::mod { 'auth_form': }
apache::mod { 'session': }
apache::mod { 'request': }
apache::mod { 'session_cookie': }
apache::mod { 'authn_dbd': }
apache::mod { 'dbd': }

class apache_links {
  $apachehome = '/home/vagrant/apache'
  file { 'apachehome':
    path => $apachehome,
    ensure => directory,
    require => Class['apache']
  }

  file { '/home/vagrant/apache/htdocs':
    ensure => 'link',
    target => '/var/www',
    require => File['apachehome']
  }

  file { '/home/vagrant/apache/conf':
    ensure => 'link',
    target => '/etc/apache2',
    require => File['apachehome']
  }
}
include apache_links

class apache_auth_test {
  file { '/home/vagrant/apache/htdocs/login.html':
    source => "/vagrant/resources/login.html",
    require => Class['apache_links']
  }

  file { 'apache_test_dir':
    path => '/home/vagrant/apache/htdocs/private',
    ensure => directory,
    require => Class['apache_links']
  }

  file { '/home/vagrant/apache/htdocs/private/index.php':
    source => "/vagrant/resources/index.php",
    require => File['apache_test_dir']
  }
}
include apache_auth_test