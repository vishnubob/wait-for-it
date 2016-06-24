#!/usr/bin/env bash
#   Use this script to test if a given TCP host/port are available
# https://github.com/vishnubob/wait-for-it

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -b | --busybox              Use busybox timeout command, i.e. timeout needs -t flag
    -w | --wget                 Use wget command to check http endpoints
    -c | --curl                 Use curl command to check http endpoints
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Do not output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit 1
}

wait_for()
{
    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $HOST:$PORT"
    else
        echoerr "$cmdname: waiting for $HOST:$PORT without a timeout"
    fi
    start_ts=$(date +%s)
    while :
    do
        if [[ $CURL -eq 1 ]]; then
            curl --output /dev/null --silent --fail http://$HOST:$PORT >/dev/null 2>&1
            result=$?
        elif [[ $WGET -eq 1 ]]; then
            wget http://$HOST:$PORT/ >/dev/null 2>&1
            result=$?
        elif [[ $ISBUSY -eq 1 ]]; then
            nc -z $HOST $PORT
            result=$?
        else
            (echo > /dev/tcp/$HOST/$PORT) >/dev/null 2>&1
            result=$?
        fi
        if [[ $result -eq 0 ]]; then
            end_ts=$(date +%s)
            echoerr "$cmdname: $HOST:$PORT is available after $((end_ts - start_ts)) seconds"
            break
        fi
        sleep 1
    done
    return $result
}

if hash timeout 2>/dev/null; then
    # timeout command is available
    : # noop, because I don't know how to reverse the conditional :(
else
    # no timeout, e.g. in osx.  Use perl alternative
    function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }
fi

wait_for_wrapper()
{
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    timeout $BUSYTIMEFLAG $TIMEOUT $0 --child $CHILD_ARGS &
    PID=$!
    trap "kill -INT -$PID" INT
    wait $PID
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for $HOST:$PORT"
    fi
    return $RESULT
}

# process arguments
BUSYTIMEFLAG=""
CHILD_ARGS=""
while [[ $# -gt 0 ]]
do
    case "$1" in
        *:* )
        hostport=(${1//:/ })
        HOST=${hostport[0]}
        PORT=${hostport[1]}
        CHILD_ARGS="$CHILD_ARGS $HOST:$PORT"
        shift 1
        ;;
        --child)
        CHILD=1 
        CHILD_ARGS="$CHILD_ARGS --child"
        shift 1
        ;;
        -q|--quiet)
        QUIET=1
        CHILD_ARGS="$CHILD_ARGS --quiet"
        shift 1
        ;;
        -w|--wget)
        WGET=1
        CHILD_ARGS="$CHILD_ARGS --wget"
        shift 1
        ;;
        -c|--curl)
        CURL=1
        CHILD_ARGS="$CHILD_ARGS --curl"
        shift 1
        ;;
        -b|--busybox)
        ISBUSY=1
        BUSYTIMEFLAG="-t"
        CHILD_ARGS="$CHILD_ARGS --busybox"
        shift 1
        ;;
        -s|--strict)
        STRICT=1
        CHILD_ARGS="$CHILD_ARGS --strict"
        shift 1
        ;;
        -h)
        HOST="$2"
        if [[ $HOST == "" ]]; then break; fi
        CHILD_ARGS="$CHILD_ARGS HOST=$HOST"
        shift 2
        ;;
        --host=*)
        HOST="${1#*=}"
        CHILD_ARGS="$CHILD_ARGS HOST=$HOST"
        shift 1
        ;;
        -p)
        PORT="$2"
        if [[ $PORT == "" ]]; then break; fi
        CHILD_ARGS="$CHILD_ARGS PORT=$PORT"
        shift 2
        ;;
        --port=*)
        PORT="${1#*=}"
        CHILD_ARGS="$CHILD_ARGS PORT=$PORT"
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if [[ $TIMEOUT == "" ]]; then break; fi
        CHILD_ARGS="$CHILD_ARGS --timeout=$TIMEOUT"
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        CHILD_ARGS="$CHILD_ARGS --timeout=$TIMEOUT"
        shift 1
        ;;
        --)
        shift
        CLI="$@"
        CHILD_ARGS="$CHILD_ARGS -- $CLI"
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "$HOST" == "" || "$PORT" == "" ]]; then
    echoerr "Error: you need to provide a host and port to test."
    usage
fi

TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}
CURL=${CURL:-0}
WGET=${WGET:-0}
ISBUSY=${ISBUSY:-0}

if [[ $CHILD -gt 0 ]]; then
    wait_for
    RESULT=$?
    exit $RESULT
else
    if [[ $TIMEOUT -gt 0 ]]; then
        wait_for_wrapper
        RESULT=$?
    else
        wait_for
        RESULT=$?
    fi
fi

if [[ $CLI != "" ]]; then
    if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec $CLI
else
    exit $RESULT
fi