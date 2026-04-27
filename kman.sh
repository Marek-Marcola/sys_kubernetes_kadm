#!/bin/bash

VERSION_BIN="260428"

SN="${0##*/}"
ID="[$SN]"

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="kman"
INSTALL_SKOPEO=0
VERSION=0
BACKUP=0
BACKUP_LIST=0
DEBUG=""
LINK=0
EVAL=0
VERSION_KUBEADM=0
VERSION_STABLE=0
PACKAGE_CONFIG=0
PACKAGE_LIST=0
PACKAGE_INSTALL_KUBE=0
PACKAGE_INSTALL_KUBEADM=0
PACKAGE_INSTALL_KUBECTL=0
PACKAGE_INSTALL_KUBELET=0
PACKAGE_INSTALL_SKOPEO=0
IMAGE_LIST=0
IMAGE_LIST_REG=0
IMAGE_LIST_REG_RE=""
IMAGE_SAVE=0
IMAGE_PUSH=0
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
      PACKAGE_CONFIG=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pl)
      PACKAGE_LIST=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pka)
      PACKAGE_INSTALL_KUBE=1
      PACKAGE_INSTALL_KUBEADM=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pkc)
      PACKAGE_INSTALL_KUBE=1
      PACKAGE_INSTALL_KUBECTL=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -pkl)
      PACKAGE_INSTALL_KUBE=1
      PACKAGE_INSTALL_KUBELET=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -ps)
      PACKAGE_INSTALL_SKOPEO=1
      shift
      ;;
    -il)
      IMAGE_LIST=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -ilr)
      IMAGE_LIST_REG=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && IMAGE_LIST_REG_RE="$2" && shift
      [[ -n "$2" && $2 = "-a" ]] && IMAGE_LIST_REG_RE=".*" && shift
      shift
      ;;
    -is)
      IMAGE_SAVE=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && V="$2" && shift
      shift
      ;;
    -ip)
      IMAGE_PUSH=1
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
  echo "$SN -pc [ver]                 # package config"
  echo "$SN -pl [ver]                 # package list"
  echo "$SN -pka [ver] [-x]           # package install kubeadm"
  echo "$SN -pkc [ver] [-x]           # package install kubectl"
  echo "$SN -pkl [ver] [-x]           # package install kubelet"
  echo "$SN -ps [-x]                  # package install skopeo"
  echo ""
  echo "$SN -il  [ver]                # image list from kubeadm"
  echo "$SN -ilr [re|-a]              # image list from registry"
  echo "$SN -is  [ver]                # image save"
  echo "$SN -ip  [ver]                # image pull"
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
  echo "  --- install: kubeadm,skopeo"
  echo "  ap-apn-api -pc      # config"
  echo "  ap-apn-api -pl      # list"
  echo "  ap-apn-api -pka -x  # install kubeadm"
  echo "  ap-apn-api -ps  -x  # install skopeo"
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
  V=$(kubeadm version -o yaml 2>/dev/null | grep gitVersion | awk '{print $2}' | sed 's/^v//')
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

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb kman_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

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
  echo "regs   = ${REGISTRY_HOST:-[none]}"
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
  kubeadm ${DEBUG:+--v=5} version -o yaml
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
# stage: PACKAGE-CONFIG
#
if [ $PACKAGE_CONFIG -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PACKAGE-CONFIG"

  if [ "$V" = ""  ]; then
    echo "$ID: require: ver"
    exit 1
  fi

  VB=${V%.*}
  RB="/etc/apt/sources.list.d/debian-k8s-$VB.list"

  if [ ! -f "$RB" ]; then
    set -ex
    echo "deb [trusted=yes] http://apt/sw/repos/k8s-deb/mirror/pkgs.k8s.io/core:/stable:/v$VB/deb /" | tee $RB
    { set +ex; } 2>/dev/null
    echo
  fi

  set -ex
  cat $RB
  { set +ex; } 2>/dev/null
fi

#
# stage: PACKAGE-LIST
#
if [ $PACKAGE_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PACKAGE-LIST"

  if [ "$V" = ""  ]; then
    echo "$ID: require: ver"
    exit 1
  fi

  VB=${V%.*}
  RB="/etc/apt/sources.list.d/debian-k8s-$VB.list"

  set -ex
  tree --noreport -F -hD -C -L 1 /etc/apt/sources.list.d
  { set +ex; } 2>/dev/null
    echo

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
    apt-cache madison kubeadm kubectl kubelet skopeo
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-cache madison kubeadm kubectl kubelet | grep $V
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt list --installed kubeadm kubectl kubelet skopeo
    { set +ex; } 2>/dev/null
    echo

    set -ex
    apt-mark showhold
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: PACKAGE-INSTALL-KUBE
#
if [ $PACKAGE_INSTALL_KUBE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PACKAGE-INSTALL-KUBE (EVAL=$EVAL)"

  if [ "$V" = ""  ]; then
    echo "$ID: require: ver"
    exit 1
  fi

  set -ex
  apt-get -qq update
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-cache madison kubeadm kubectl kubelet | grep $V
  { set +ex; } 2>/dev/null
  echo

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--dry-run" || EVAL_OPT=""
  export DEBIAN_FRONTEND=noninteractive

  if [ $PACKAGE_INSTALL_KUBEADM -eq 1 ]; then
    set -ex
    apt-get -y --allow-change-held-packages $EVAL_OPT install kubeadm=$V-1.1
    { set +ex; } 2>/dev/null
    if [ $EVAL -eq 1 ]; then
      set -ex
      apt-mark hold kubeadm
      { set +ex; } 2>/dev/null
    fi
    echo
  fi

  if [ $PACKAGE_INSTALL_KUBECTL -eq 1 ]; then
    set -ex
    apt-get -y --allow-change-held-packages $EVAL_OPT install kubectl=$V-1.1
    { set +ex; } 2>/dev/null
    if [ $EVAL -eq 1 ]; then
      set -ex
      apt-mark hold kubectl
      { set +ex; } 2>/dev/null
    fi
    echo
  fi

  if [ $PACKAGE_INSTALL_KUBELET -eq 1 ]; then
    set -ex
    apt-get -y --allow-change-held-packages $EVAL_OPT install kubelet=$V-1.1
    { set +ex; } 2>/dev/null
    if [ $EVAL -eq 1 ]; then
      set -ex
      apt-mark hold kubelet
      { set +ex; } 2>/dev/null
    fi
    echo
  fi

  set -ex
  apt list --installed kubeadm kubectl kubelet
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-mark showhold
  { set +ex; } 2>/dev/null
fi

#
# stage: PACKAGE-INSTALL-SKOPEO
#
if [ $PACKAGE_INSTALL_SKOPEO -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: PACKAGE-INSTALL-SKOPEO (EVAL=$EVAL)"

  set -ex
  apt-get -qq update
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt-cache madison skopeo
  { set +ex; } 2>/dev/null
  echo

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--dry-run" || EVAL_OPT=""

  set -ex
  export DEBIAN_FRONTEND=noninteractive
  apt-get -y $EVAL_OPT install skopeo
  { set +ex; } 2>/dev/null
  echo

  set -ex
  apt list --installed skopeo
  { set +ex; } 2>/dev/null
fi

#
# stage: IMAGE-LIST
#
if [ $IMAGE_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-LIST"

  set -ex
  kubeadm ${DEBUG:+--v=5} config images list ${V:+--kubernetes-version=$V}
  { set +ex; } 2>/dev/null
fi

#
# stage: IMAGE-LIST-REG
#
if [ $IMAGE_LIST_REG -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-LIST-REG (re: $IMAGE_LIST_REG_RE)"

  if [ "$REGISTRY_HOST" = ""  ]; then
    echo "$ID: require: REGISTRY_HOST"
    exit 1
  fi

  for RH in $REGISTRY_HOST; do
    if [ "$IMAGE_LIST_REG_RE" != "" ]; then
      for R in $(curl --netrc-file $REGISTRY_AUTH -s -k -L $RH/v2/_catalog | tr -d '[]{}"' | awk -F: '{print $2}' | tr ',' ' '); do
        if [[ $R =~ $IMAGE_LIST_REG_RE ]]; then
          echo | xargs -L1 -t curl --netrc-file $REGISTRY_AUTH -s -k -L $RH/v2/$R/tags/list | jq
        fi
      done
    else
      echo | xargs -L1 -t curl --netrc-file $REGISTRY_AUTH -s -k -L $RH/v2/_catalog | jq
    fi
  done
fi

#
# stage: IMAGE-SAVE
#
if [ $IMAGE_SAVE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-SAVE (EVAL=$EVAL)"

  if [ ! $(type -t skopeo) ]; then
    echo "$ID: command not found: skopeo"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_CMD="echo" || EVAL_CMD=""

  kubeadm ${DEBUG:+--v=5} config images list ${V:+--kubernetes-version=$V} | \
  while read i; do
    IR=$(echo $i | sed 's#^[^/]*/##' | awk -F: '{print $1}' | sed 's#/#__SLASH__#g')
    IV=$(echo $i | sed 's#^[^/]*/##' | awk -F: '{print $2}')

    if [ ! -f $IR-$IV.tar ]; then
      set -ex
      $EVAL_CMD \
      skopeo ${DEBUG:+--debug} copy \
        --src-tls-verify=0 \
        docker://$i docker-archive:$IR-$IV.tar
      { set +ex; } 2>/dev/null
    else
      echo file already exists: $IR-$IV.tar
    fi
  done
fi

#
# stage: IMAGE-PUSH
#
if [ $IMAGE_PUSH -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-PUSH (EVAL=$EVAL)"

  if [ ! $(type -t skopeo) ]; then
    echo "$ID: command not found: skopeo"
    exit 1
  fi

  if [ -z "$REGISTRY_HOST" ]; then
    echo "$ID: require: REGISTRY_HOST"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_CMD="echo" || EVAL_CMD=""

  for RH in $REGISTRY_HOST; do
    kubeadm ${DEBUG:+--v=5} config images list ${V:+--kubernetes-version=$V} | \
    while read i; do
      IR=$(echo $i | sed 's#^[^/]*/##' | awk -F: '{print $1}')
      IV=$(echo $i | sed 's#^[^/]*/##' | awk -F: '{print $2}')

      set -ex
      $EVAL_CMD \
      skopeo ${DEBUG:+--debug} copy \
        --src-tls-verify=0 \
        --dest-tls-verify=0 \
        docker://$i docker://${RH#*://}/$IR:$IV
      { set +ex; } 2>/dev/null
    done
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
