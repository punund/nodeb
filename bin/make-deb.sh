#!/bin/bash

fatecho() {  echo -e "\n$1\n" }

DEBUG= # 'v' for verbose t?ar

export nbPort=80
export nbUser=node

dir=`dirname $(readlink -f $0)`

while getopts "p:tu:" opt; do
  case $opt in
    u)
      nbUser=$OPTARG
      ;;
    p)
      nbPort=$OPTARG
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
    \?)
      cat <<-EOH >&2

  Valid options:

  -p <port to monitor> (default 80) 
  -t copy templates to nodeb_templates/ for customization
  -u <user to run processes as> (default "node")

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
  echo
  echo '*** Error: package.json must contain at least "name" and "scripts":{"start":...} values. ***' >&2
  echo
  exit 1
fi

export Command=${Exec%% *}
export CommandArgs=${Exec#* }

if [ node \!= $Command ] ; then
  Command=node_modules/.bin/$Command
fi

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
  # echo ------
  # cat $RDIR/$dst
done

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

fatecho $debfile created.

)
