#!/usr/bin/env sh

opt_docker_image="zeek-grpc-http2"
opt_docker_file="zeekurity-zeek:lts/Dockerfile"
opt_docker_build="false"
opt_docker_run="false"
opt_docker_vol_data="-v ${PWD}/../../data:/data"
opt_docker_entrypoint=

USAGE="Usage:  ${CMD:=${0##*/}} [(-v|--verbose)] [--name=TEXT] [(-o|--output) FILE] [ARGS...]"

exit2 () { printf >&2 "%s:  %s: '%s'\n%s\n" "$CMD" "$1" "$2" "$USAGE"; exit 2; }
check () { { [ "$1" != "$EOL" ] && [ "$1" != '--' ]; } || exit2 "missing argument" "$2"; }  # avoid infinite loop

# parse command-line options
set -- "$@" "${EOL:=$(printf '\1\3\3\7')}"  # end-of-list marker
while [ "$1" != "$EOL" ]; do
  opt="$1"; shift
  case "$opt" in

    #EDIT HERE: defined options
         --name    ) check "$1" "$opt"; opt_docker_image="$1"; shift;;
         --file    ) check "$1" "$opt"; opt_docker_file="$1"; shift;;
         --data  ) check "$1" "$opt"; opt_docker_vol_data="v $1:/data"; shift;;
         --entrypoint ) check "$1" "$opt"; opt_docker_entrypoint="--entrypoint $1"; shift;;
         --build   ) opt_docker_build='true';;
         --run     ) opt_docker_run='true';;
    # -o | --output  ) check "$1" "$opt"; opt_output="$1"; shift;;
    -v | --verbose ) opt_verbose='true';;
    -h | --help    ) printf "%s\n" "$USAGE"; exit 0;;

    # process special cases
    --) while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done;;   # parse remaining as positional
    --[!=]*=*) set -- "${opt%%=*}" "${opt#*=}" "$@";;                  # "--opt=arg"  ->  "--opt" "arg"
    -[A-Za-z0-9] | -*[!A-Za-z0-9]*) exit2 "invalid option" "$opt";;    # anything invalid like '-*'
    -?*) other="${opt#-?}"; set -- "${opt%$other}" "-${other}" "$@";;  # "-abc"  ->  "-a" "-bc"
    *) set -- "$@" "$opt";;                                            # positional, rotate to the end
  esac
done; shift # $EOL

if [[ $opt_verbose == 'true' ]]; then
    printf "name = '%s'\noutput = '%s'\nverbose = '%s'\n\$@ = (%s)\n" \
    "$opt_docker_image" "$opt_docker_file" "$opt_verbose" "$*"
    set -x
fi

if [[ $opt_docker_build == 'true' ]]; then
    docker build -t $opt_docker_image -f $opt_docker_file $(dirname $opt_docker_file)
fi

if [[ $opt_docker_run == 'true' ]]; then
    # docker run -it --rm --name $opt_docker_image-container $opt_docker_image $*
    docker run -it --rm $opt_docker_vol_data $opt_docker_entrypoint $opt_docker_image
fi