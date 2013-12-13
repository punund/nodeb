#!/bin/bash

fatecho() {  echo -e '\E[31m' "\n$1\n" '\e[0m' ; }

DEBUG= # 'v' for verbose t?ar

export nbPort=80
export nbUser=node
export nbWeb=
export nbSsl=

dir=`dirname $(readlink -f $0)`

while getopts "p:tu:w:sv" opt; do
  case $opt in
    u)
      nbUser=$OPTARG
      ;;
    p)
      nbPort=$OPTARG
      ;;
    s)
      nbSsl=1
      ;;
    t)
      if [ -e nodeb_templates ] ; then
        fatecho \"nodeb_templates\" exists, delete it first. Not executing. >&2
      else
        cp -a $dir/../templates nodeb_templates/
        echo nodeb_templates/ created.
      fi
      exit 0
      ;;
    v)
     verbose=1
     ;;
    w)
     nbWeb=$OPTARG
     ;;
    \?)
      cat <<-EOH >&2

  Valid options:

  -p <port to monitor> (default 80) 
  -s also generate nginx config for SSL server
  -t copy templates to nodeb_templates/ for customization and exit
  -u <user to run processes as> (default "node")
  -v show generated files to stdout
  -w <production website address>. If given, nginx config files will be created

EOH
      exit 1
      ;;
  esac
done

pdir=$PWD

TDIR=`mktemp -d`
RDIR=`mktemp -d`

trap "rm -fr $TDIR $RDIR" SIGHUP SIGINT SIGTERM SIGQUIT EXIT

$dir/../node_modules/.bin/coffee -e '
  pkg = require "./package.json"

  console.log """
    set -a
    Source="#{pkg.name}"
    Package="#{pkg.name}"
    Version="#{pkg.version}"
    Priority=extra
    Maintainer="#{pkg.author}"
    Architecture=all
    Depends="${nodejs:Depends}"
    Description="#{pkg.description}"
    Exec="#{pkg.scripts.start}"
    """
    ' | (source /dev/stdin

if [ -z "$Exec" -o -z "$Package" ] ; then
  fatecho '*** Error: package.json must contain at least "name" and "scripts":{"start":...} values. ***' >&2
  exit 1
fi

export Command=${Exec%% *}
export CommandArgs=${Exec#* }

# some vars to preserve in nginx files

for keepit in uri is_args args host http_upgrade remote_addr proxy_add_x_forwarded_for ; do
  export $keepit=\$${keepit}
done

[[ node = $Command ]] || Command=node_modules/.bin/$Command

Name=node-$Package

if [ -d nodeb_templates ] ; then
  cd nodeb_templates
else
  cd $dir/../templates
fi

for src in *; do
  dst=${src//,//}
  dst=${dst/PACKAGE/$Package}
  dstdir=`dirname $dst`

  mkdir -p $RDIR/$dstdir
  envsubst < $src > $RDIR/$dst
  if [[ $verbose ]] ; then 
    echo -e '\E[37;44m'
    echo -e $dst '\E[0m'
    cat $RDIR/$dst
  fi
done

[[ $nbWeb ]] || rm -fr $RDIR/etc/nginx/
[[ $nbSsl ]] || rm -fr $RDIR/etc/nginx/*-ssl

cat > $TDIR/control <<EOD
Source: $Package
Package: $Package
Version: $Version
Priority:  extra
Maintainer: $Maintainer
Architecture: all
Depends: nodejs
Description: $Description
EOD

cat > $TDIR/postinst <<EOD
chown -R $nbUser /opt/$Package
if [ \! -d /opt/$Package/node_modules ] ; then
  echo "Running npm...."
  cd /opt/$Package
  sudo -H -u $nbUser npm i
fi
echo "Starting $Name"
start $Name
EOD

cat > $TDIR/preinst <<EOD
if [ \! -x /usr/bin/nodejs ] ; then
  echo
  echo /usr/bin/nodejs is required. Abort.
  echo 
  exit 1
fi  
if id $nbUser > /dev/null 2>&1 ; then
  ln -f -s /usr/bin/nodejs /usr/bin/node
else
  echo
  echo Please create user "$nbUser" first.  Abort.
  echo 
  exit 1
fi
EOD

cat > $TDIR/prerm <<EOD
echo "Stopping $Name"
stop $Name
exit 0
EOD

cd $TDIR
tar -c${DEBUG}f control.tar *

cd $RDIR
tar -c${DEBUG}f $TDIR/data.tar *

cd $pdir
tar -C $pdir \
  --xform="s:^.:opt/$Package:" \
  --exclude-backups --exclude-vcs \
  --exclude=nodeb_templates \
  --exclude=*.deb \
  -r${DEBUG}f $TDIR/data.tar .

cd $TDIR
gzip control.tar
gzip data.tar

echo 2.0 > debian-binary

debfile=$pdir/$Package.deb
ar r$DEBUG $debfile debian-binary control.tar.gz data.tar.gz 2>/dev/null

fatecho "$debfile created."
)
