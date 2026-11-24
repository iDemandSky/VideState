#!/usr/bin/env bash
# Builds the Larvae output and serves it with Rojo, for macOS, Linux, and Windows with Git Bash.
# Windows users can run serve.bat instead. If either process exits, the output is refreshed and
# serving restarts after a short delay. Press Ctrl+C to stop.

cd "$(dirname "$0")" || exit 1

ember_bin="$HOME/.ember/bin"
retry_delay=5
project_file=".larvae/build.project.json"

find_tool() {
    if [ -x "$ember_bin/$1" ]; then
        echo "$ember_bin/$1"
    elif [ -x "$ember_bin/$1.exe" ]; then
        echo "$ember_bin/$1.exe"
    fi
}

larvae="$(find_tool larvae)"
rojo="$(find_tool rojo)"

if [ -z "$larvae" ] || [ -z "$rojo" ]; then
    echo "The pinned Larvae or Rojo shim is missing. Run 'embr install' from the project folder first." >&2
    exit 1
fi

watcher_pid=""
server_pid=""

stop_children() {
    for pid in "$watcher_pid" "$server_pid"; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null
        fi
    done

    watcher_pid=""
    server_pid=""
}

trap 'stop_children; exit 0' INT TERM

while true; do
    echo
    echo "[VideState] Refreshing Larvae output..."

    if ! "$larvae" process; then
        echo "Larvae process failed. Retrying in $retry_delay seconds." >&2
        sleep "$retry_delay"
        continue
    fi

    if [ ! -f "$project_file" ]; then
        echo "Larvae did not create $project_file. Retrying in $retry_delay seconds." >&2
        sleep "$retry_delay"
        continue
    fi

    echo "[VideState] Starting Larvae watch and Rojo serve..."

    "$larvae" process --watch &
    watcher_pid=$!

    "$rojo" serve "$project_file" &
    server_pid=$!

    while kill -0 "$watcher_pid" 2>/dev/null && kill -0 "$server_pid" 2>/dev/null; do
        sleep 1
    done

    if ! kill -0 "$watcher_pid" 2>/dev/null; then
        echo "Larvae watch exited." >&2
    else
        echo "Rojo serve exited." >&2
    fi

    stop_children

    echo "[VideState] Refreshing and restarting in $retry_delay seconds."
    sleep "$retry_delay"
done
