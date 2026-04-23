#!/bin/bash

VERSION_BIN="260423"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="kman"
VERSION=0
BACKUP=0
BACKUP_LIST=0
DEBUG=0
DEBUG_OPTS=""
LINK=0
EVAL=0
VERSION_KUBEADM=0
VERSION_STABLE=0
PM_CONFIG=0
PM_LIST=0
PM_INSTALL=0
IMAGE_LIST=0
IMAGE_PULL=0
ENV_LIST=0
ENV_SHOW=0
ENV_SHOW_RE=""
ENV_EDIT=0
HELP=0
QUIET=0

ARGC=$#
declare -a ARGS1
declare -a OPTS2
ARGS2=""

s=0

: ${A:=${SN%.sh}}
: ${APN:=$(echo $A|cut -d- -f2)}
: ${API:=$(echo $A|cut -d- -f3-)}
: ${EDIR:="/usr/local/etc/kman.d"}
: ${LDIR:="/usr/local/bin/alias-kman"}
: ${DDIR:="/var/backup/kman"}
: ${COMM:=$(readlink -f ${BASH_SOURCE})}

while [ $# -gt 0 ]; do
  case $1 in
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    -g)
      DEBUG=1
      DEBUG_OPTS="--v=5"
      shift
      ;;
    -V)
      VERSION_KUBEADM=1
      shift
      ;;
    -Vs)
      VERSION_STABLE=1
      shift
      ;;
    -pc)
      PM_CONFIG=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pl)
      PM_LIST=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pi)
      PM_INSTALL=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -il)
      IMAGE_LIST=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -ip)
      IMAGE_PULL=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -l)
      ENV_LIST=1
      shift
      ;;
    -s)
      ENV_SHOW=1
      ENV_SHOW_RE="$2"
      QUIET=1
      shift; shift
      ;;
    -E)
      ENV_EDIT=1
      shift
      ;;
    -L)
      LINK=1
      shift
      ;;
    -x)
      EVAL=1
      shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    --)
      shift
      ARGS2=$*
      break
      ;;
    *)
      OPTS2+=("$1")
      shift
      ;;
  esac
done

if [[ $ARGC -eq 0 && "$A" = "kman" ]]; then
  ENV_LIST=1
  QUIET=1
fi

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -version                  # version"
  echo "$SN -install                  # install with rsync"
  echo "$SN -anpb [host_pattern] [-x] # install with ansible"
  echo ""
  echo "$SN -B                        # backup"
  echo "$SN -Bl                       # backup list"
  echo ""
  echo "$SN -L [-x]                   # link show,run"
  echo ""
  echo "$SN -V                        # version kubeadm"
  echo "$SN -Vs                       # version stable"
  echo ""
  echo "$SN -pc [ver]                 # package manager config"
  echo "$SN -pl [ver]                 # package manager list"
  echo "$SN -pi [ver]                 # package manager install"
  echo ""
  echo "$SN -il [ver]                 # image list"
  echo "$SN -ip [ver]                 # image pull"
  echo ""
  echo "$SN -l                        # env list"
  echo "$SN -s [re]                   # env show"
  echo "$SN -E                        # env edit"
  echo ""
  echo "$SN                           # env list"
  echo ""
  echo "common opts:"
  echo "  -g  - debug"
  echo "  -V  - k8s version"
  echo "  -Ed - env   dir (edir: $EDIR)"
  echo "  -Ld - link  dir (ldir: $LDIR)"
  echo ""
  echo "env files: /usr/local/etc/kman.env $EDIR/\$A"
  echo ""
  echo "env variables used in env file:"
  echo "  \$V  - k8s version"
  echo ""
  echo "note:"
  echo "  km -L -x            # link"
  echo ""
  echo "  ap-apn-api -E       # env edit"
  echo ""
  echo "  --- install: kubeadm,kubectl"
  echo "  ap-apn-api -pc      # pm config"
  echo "  ap-apn-api -pl      # pm list"
  echo "  ap-apn-api -pi      # pm install"
  exit 0
fi

#
# stage: CONFIG
#
for f in /usr/local/etc/kman.env $EDIR/$A; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

if [ "$V" = "" ]; then
  V=$(kubeadm version -o yaml | grep gitVersion | awk '{print $2}' | sed 's/^v//')
fi

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  exit 0
fi

#
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-RSYNC"

  if [ -f kman.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999224-kman/999224-000030_kman_script /pub/pkb/pb/playbooks/999224-kman/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai kman.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi

  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: command not found: anpb"
    exit 1
  fi

  if [ $EVAL -eq 0 ]; then
    set -ex
    anpb kman_install.yml -e h=$INSTALL_ANPB_HP --check --diff
    { set +ex; } 2>/dev/null
  else
    set -ex
    anpb kman_install.yml -e h=$INSTALL_ANPB_HP
    { set +ex; } 2>/dev/null
  fi

  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info   = $INFO"
  echo "cwd    = $(pwd -P)"
  echo "efile  = ${EFILE:-[none]}"
  echo "App    = ${A:-[none]}"
  echo "APN    = ${APN:-[none]}"
  echo "API    = ${API:-[none]}"
  echo "Ver    = ${V:-[none]}"
  echo "wdir   = ${WDIR:-[none]}"
  echo "edir   = ${EDIR:-[none]}"
  echo "ldir   = ${LDIR:-[none]}"
fi

#
# stage: LINK
#
if [ $LINK -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LINK"

  if [ ! -d $EDIR ]; then
    echo $ID: directory not found: $EDIR
    exit 1
  fi
  if [ ! -d $LDIR ]; then
    echo $ID: directory not found: $LDIR
    exit 1
  fi

  ls $EDIR/ | \
  while read E; do
    LSRC=${COMM}
    if [ ! -f $LDIR/$E ]; then
      if [ $EVAL -ne 0 ]; then
        set -ex
        ln -svr $LSRC $LDIR/$E
        { set +ex; } 2>/dev/null
      else
        echo "ln -svr $LSRC $LDIR/$E"
      fi
    else
      echo "# ln -svr $LSRC $LDIR/$E"
    fi
  done
fi

#
# stage: VERSION-KUBEADM
#
if [ $VERSION_KUBEADM -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: VERSION-KUBEADM"

  set -ex
  kubeadm $DEBUG_OPTS version -o yaml
  { set +ex; } 2>/dev/null
fi

#
# stage: VERSION-STABLE
#
if [ $VERSION_STABLE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: VERSION-STABLE"

  (
  set -ex
  curl -sSL https://dl.k8s.io/release/stable.txt
  { set +ex; } 2>/dev/null
  ) | more -e
fi

#
# stage: PM-CONFIG
#
if [ $PM_CONFIG -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PM-CONFIG"

  if [ "$V" = ""  ]; then
    echo "$ID: error: require ver"
    exit 1
  fi

  VB=${V%.*}
  RB="/etc/apt/sources.list.d/debian-k8s-$VB.list"

  if [ ! -f "$RB" ]; then
    set -ex
    echo "deb [trusted=yes] http://apt/sw/repos/k8s-deb/mirror/pkgs.k8s.io/core:/stable:/v$VB/deb /" > $RB
    { set +ex; } 2>/dev/null
    echo
  fi

  set -ex
  cat $RB
  { set +ex; } 2>/dev/null
fi

#
# stage: PM-LIST
#
if [ $PM_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PM-LIST"

  if [ "$V" = ""  ]; then
    echo "$ID: error: require ver"
    exit 1
  fi

  VB=${V%.*}
  RB="/etc/apt/sources.list.d/debian-k8s-$VB.list"

  if [ ! -f "$RB" ]; then
    echo package manager config not found: $RB
  else
    set -ex
    cat $RB
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-get -qq update
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-cache madison kubeadm kubectl kubelet
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-cache madison kubeadm kubectl kubelet | grep $V
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt list --installed kubeadm kubectl kubelet
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-mark showhold
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: PM-INSTALL
#
if [ $PM_INSTALL -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PM-INSTALL"

  if [ "$V" = ""  ]; then
    echo "$ID: error: require ver"
    exit 1
  fi

  VB=${V%.*}
  RB="/etc/apt/sources.list.d/debian-k8s-$VB.list"

  if [ ! -f "$RB" ]; then
    echo package manager config not found: $RB
    exit 1
  fi

  set -ex
  cat $RB
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-get -qq update
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-cache madison kubeadm kubectl | grep $V
  { set +ex; } 2>/dev/null
  echo

  set -ex
  export DEBIAN_FRONTEND=noninteractive
  apt -y --allow-change-held-packages install kubeadm=$V-1.1 kubectl=$V-1.1
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt list --installed kubeadm kubectl kubelet
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-mark hold kubeadm kubectl
  apt-mark showhold
  { set +ex; } 2>/dev/null
fi

#
# stage: IMAGE-LIST
#
if [ $IMAGE_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-LIST"

  set -ex
  kubeadm $DEBUG_OPTS config images list ${V:+--kubernetes-version=$V}
  { set +ex; } 2>/dev/null
fi

#
# stage: IMAGE-PULL
#
if [ $IMAGE_PULL -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-PULL"

  if [ ! $(type -t skopeo) ]; then
    echo "$ID: command not found: skopeo"
    exit 1
  fi

  kubeadm $DEBUG_OPTS config images list ${V:+--kubernetes-version=$V} | \
  while read i; do
    set -ex
    echo $i
    { set +ex; } 2>/dev/null
  done
fi

#
# stage: ENV-LIST
#
if [ $ENV_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-LIST"

  if [ ! -d $EDIR ]; then
    echo directory not found: $EDIR
  else
    set -ex
    ls -log $EDIR/
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: ENV-SHOW
#
if [ $ENV_SHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (re: *$ENV_SHOW_RE*)"

  if [ "$A" != "kman" -a  "$ENV_SHOW_RE" = "" ]; then
    if [ ! -f $EDIR/$A ]; then
      echo file not found: $EDIR/$A
    else
      (
      set -ex
      cat $EDIR/$A
      { set +ex; } 2>/dev/null
      ) | cat
    fi
  else
    for f in $EDIR/*$ENV_SHOW_RE*; do
      if [ -f $f ]; then
        set -ex
        cat $f  2>&1
        { set +ex; } 2>/dev/null
        echo
      fi
    done
  fi
fi

#
# stage: ENV-EDIT
#
if [ $ENV_EDIT -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-EDIT"

  if [ ! -d $EDIR ]; then
    echo directory not found: $EDIR
  else
    set -ex
    vi $EDIR/$A
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: BACKUP
#
if [ $BACKUP -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP"

  if [ ! -d $DDIR ]; then
    set -x
    mkdir -pv $DDIR
    { set +x; } 2>/dev/null
  fi

  F=$DDIR/kman-$(hostname -s)-$(date "+%y%m%d%H%M").tar

  set -x
  cd /usr/local
  tar cf $F etc/kman* bin/kman*
  gzip -f $F
  { set +x; } 2>/dev/null
fi

#
# stage: BACKUP-LIST
#
if [ $BACKUP_LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-LIST"

  set -x
  tree --noreport -F -h -C -L 1 $DDIR
  { set +x; } 2>/dev/null
fi
