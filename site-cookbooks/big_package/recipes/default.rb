Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

%w[
  git-core subversion tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff htop sysstat
  python-setuptools 
  s3cmd
  ifstat
].each do |pkg|
  package pkg
end

%w[
   extlib fastercsv json yajl-ruby
   addressable fog cheat configliere wukong gorillib
].each do |gem_pkg|
  gem_package gem_pkg do
    action :install
  end
end
