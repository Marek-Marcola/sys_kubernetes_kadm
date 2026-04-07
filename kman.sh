#!/bin/bash

VERSION_BIN="260408"

SN="${0##*/}"
ID="[$SN]"

INSTALL=0
VERSION=0
BACKUP=0
BACKUP_LIST=0
DEBUG=0
DEBUG_OPTS=""
LINK=0
VERSION_KUBEADM=0
VERSION_STABLE=0
IMAGE_LIST=0
ELIST=0
ESHOW=0
ESHOW_RE=""
EEDIT=0
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

while [ $# -gt 0 ]; do
  case $1 in
    --inst*|-inst*)
      INSTALL=1
      shift
      ;;
    --vers*|-vers*)
      VERSION=1
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
    -il)
      IMAGE_LIST=1
      [[ ${2:0:1} != "-" ]] && V="$2" && shift
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

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -install    # install"
  echo "$SN -version    # version"
  echo "$SN -V          # version kubeadm"
  echo "$SN -Vs         # version stable"
  echo "$SN -B          # backup"
  echo "$SN -Bl         # backup list"
  echo ""
  echo "$SN -L [-x]     # link show,run"
  echo ""
  echo "$SN -il [ver]   # image list"
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
  exit 0
fi

#
# stage: CONFIG
#
for f in /usr/local/etc/kman.env $EDIR/\$A; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . ${f}
  fi
done

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  exit 0
fi

#
# stage: INSTALL
#
if [ $INSTALL -eq 1 ]; then
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
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info   = ${INFO}"
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
    if grep -q EXEC=1 $EDIR/$E; then
      LSRC=${COMM%.sh}-exec.sh
    else
      LSRC=${COMM}
    fi
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
# stage: VERSION_KUBEADM
#
if [ $VERSION_KUBEADM -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: VERSION-KUBEADM"

  set -ex
  kubeadm $DEBUG_OPTS version -o yaml
  { set +ex; } 2>/dev/null
fi

#
# stage: VERSION_STABLE
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
# stage: IMAGE_LIST
#
if [ $IMAGE_LIST -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: IMAGE-LIST"

  if [ -n "$V" ]; then
    set -ex
    kubeadm $DEBUG_OPTS config images list --kubernetes-version=$V
    { set +ex; } 2>/dev/null
  else
    set -ex
    kubeadm $DEBUG_OPTS config images list
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: ENV-LIST
#
if [ $ELIST -eq 1 ]; then
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
if [ $ESHOW -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ENV-SHOW (re: *$ESHOW_RE*)"

  if [ "$A" != "kman" -a  "$ESHOW_RE" = "" ]; then
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
    for f in $EDIR/*$ESHOW_RE*; do
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
if [ $EEDIT -eq 1 ]; then
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
