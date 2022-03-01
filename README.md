# wait-for-it.sh Github Action

`wait-for-it.sh` is a pure bash script to wait on the availability of a host and TCP port.  

Since it is a pure
bash script, it does not have any external dependencies.

This Github Action is based on a fork of the original [wait-for-it.sh](https://github.com/vishnubob/wait-for-it), and simply adds the `Dockerfile` and `action.yaml` needed to configure the shell script for use.

## Usage
```
-   id: wait-for-it
    runs: elijahboston/wait-for-it
    with:
        host: localhost
        port: 80
        timeout: 60
        strict: false
        quiet: false
```

Most parameters are optional, only the host is required:
```
-   id: wait-for-it
    runs: elijahboston/wait-for-it
    with:
        host: localhost
```
