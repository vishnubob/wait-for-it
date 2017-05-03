#!/usr/bin/env sh
#   Use this script to test if a given TCP host/port are available

set -e

cmdname=$(basename "$0")

echoerr() {
    if [ "$QUIET" -ne 1 ]; then
        printf "%s\n" "$*" 1>&2;
    fi
}

usage()
{
    exitcode="$1"
    cat << USAGE >&2
Usage:
    $cmdname host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
    exit "$exitcode"
}

wait_for()
{
    if [ "$TIMEOUT" -gt 0 ]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $HOST:$PORT"
    else
        echoerr "$cmdname: waiting for $HOST:$PORT without a timeout"
    fi
    start_ts=$(date +%s)
    while true
    do
        nc -z "$HOST" "$PORT" >/dev/null 2>&1
        result=$?
        if [ $result -eq 0 ]; then
            end_ts=$(date +%s)
            echoerr "$cmdname: $HOST:$PORT is available after $((end_ts - start_ts)) seconds"
            break
        fi
        sleep 1
    done
    return $result
}

wait_for_wrapper()
{
    # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
    if [ "$QUIET" -eq 1 ]; then
        timeout "$TIMEOUT" "$0" -q -child "$HOST":"$PORT" -t "$TIMEOUT" &
    else
        timeout "$TIMEOUT" "$0" --child "$HOST":"$PORT" -t "$TIMEOUT" &
    fi
    PID=$!
    trap 'kill -INT -$PID' INT
    wait $PID
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        echoerr "$cmdname: timeout occurred after waiting $TIMEOUT seconds for $HOST:$PORT"
    fi
    return $RESULT
}

TIMEOUT=15
STRICT=0
CHILD=0
QUIET=0
# process arguments
while [ $# -gt 0 ]
do
    case "$1" in
        *:* )
        HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
        PORT=$(printf "%s\n" "$1"| cut -d : -f 2)
        shift 1
        ;;
        --child)
        CHILD=1
        shift 1
        ;;
        -q | --quiet)
        QUIET=1
        shift 1
        ;;
        -s | --strict)
        STRICT=1
        shift 1
        ;;
        -h)
        HOST="$2"
        if [ "$HOST" = "" ]; then break; fi
        shift 2
        ;;
        --host=*)
        HOST=$(printf "%s" "$1" | cut -d = -f 2)
        shift 1
        ;;
        -p)
        PORT="$2"
        if [ "$PORT" = "" ]; then break; fi
        shift 2
        ;;
        --port=*)
        PORT="${1#*=}"
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if [ "$TIMEOUT" = "" ]; then break; fi
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        break
        ;;
        --help)
        usage 0
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage 1
        ;;
    esac
done

if [ "$HOST" = "" -o "$PORT" = "" ]; then
    echoerr "Error: you need to provide a host and port to test."
    usage 2
fi

if [ $CHILD -gt 0 ]; then
    wait_for
    RESULT=$?
    exit $RESULT
else
    if [ "$TIMEOUT" -gt 0 ]; then
        wait_for_wrapper
        RESULT=$?
    else
        wait_for
        RESULT=$?
    fi
fi

if [ "$*" != "" ]; then
    if [ $RESULT -ne 0 -a $STRICT -eq 1 ]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec "$@"
else
    exit $RESULT
fi
