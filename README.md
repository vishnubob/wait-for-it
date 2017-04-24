# HELP NEEDED

### March 13, 2017 update

Since I posted this request for help, I've had a dozen or so responses which I am now sorting through.  Applicants need to fill out [this](https://goo.gl/forms/GKCBFxaloaU47aky1) survey by March 17th.  I will select, notify and announce the new volunteer(s) on March 19th.  Once this is done, me and my team will work through the backlog of issues amd pull requests.  Thanks for your paitence.

### Old request follows:

Hi there!  I wrote `wait-for-it` in order to help me orchestrate containers I operate at my day job.  I thought it was a neat little script, so I published it.  I assumed I would be its only user, but that's not what happened!  `wait-for-it` has received more stars then all of my other public repositories put together.  I had no idea this tool would solicit such an audience, and I was equally unprepared to carve out the time required to address my user's issues and patches.  I would like to solicit a volunteer from the community who would be willing to be a co-maintainer of this repository.  If this is something you might be interested in, please email me at `waitforit@polymerase.org`.  Thanks!

## wait-for-it

`wait-for-it.sh` is a pure bash script that will wait on the availability of a host and TCP port.  It is useful for synchronizing the spin-up of interdependent services, such as linked docker containers.  Since it is a pure bash script, it does not have any external dependencies.

## Usage

```
wait-for-it.sh host:port [-s] [-t timeout] [-- command args]
-h HOST | --host=HOST       Host or IP under test
-p PORT | --port=PORT       TCP port under test
                            Alternatively, you specify the host and port as host:port
-s | --strict               Only execute subcommand if the test succeeds
-q | --quiet                Don't output any status messages
-t TIMEOUT | --timeout=TIMEOUT
                            Timeout in seconds, zero for no timeout
-c COMMAND-ARG              Command argument (multiple -c allowed)
-- COMMAND ARGS             Execute command with args after the test finishes
```

## Examples

For example, let's test to see if we can access port 80 on www.google.com, and if it is available, echo the message `google is up`.

```
$ ./wait-for-it.sh www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting 15 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
google is up
```

You can set your own timeout with the `-t` or `--timeout=` option.  Setting the timeout value to 0 will disable the timeout:

```
$ ./wait-for-it.sh -t 0 www.google.com:80 -- echo "google is up"
wait-for-it.sh: waiting for www.google.com:80 without a timeout
wait-for-it.sh: www.google.com:80 is available after 0 seconds
google is up
```

The subcommand will be executed regardless if the service is up or not.  If you wish to execute the subcommand only if the service is up, add the `--strict` argument. In this example, we will test port 81 on www.google.com which will fail:

```
$ ./wait-for-it.sh www.google.com:81 --timeout=1 --strict -- echo "google is up"
wait-for-it.sh: waiting 1 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 1 seconds for www.google.com:81
wait-for-it.sh: strict mode, refusing to execute subprocess
```

If you don't want to execute a subcommand, leave off the `--` argument.  This way, you can test the exit condition of `wait-for-it.sh` in your own scripts, and determine how to proceed:

```
$ ./wait-for-it.sh www.google.com:80
wait-for-it.sh: waiting 15 seconds for www.google.com:80
wait-for-it.sh: www.google.com:80 is available after 0 seconds
$ echo $?
0
$ ./wait-for-it.sh www.google.com:81
wait-for-it.sh: waiting 15 seconds for www.google.com:81
wait-for-it.sh: timeout occurred after waiting 15 seconds for www.google.com:81
$ echo $?
124
```

If you are running inside Docker container, and want to lock down the command line while allowing configurability of the trigger port, use the `-c` options to specify the command line in the ENTRYPOINT.
This way, you're not requiring (or allowing) the command line to be reconfigured in container configuration.

```
ENTRYPOINT [ "./wait-for-it.sh", "--strict", "-c", "echo", "-c", "google is up" ]
CMD [ "www.google.com:80", "--timeout=1" ]
```

## Thanks

I wrote this script for my employer, [Ginkgo Bioworks](http://www.ginkgobioworks.com/), who was kind enough to let me release it as an open source tool.  We are always looking to [hire](https://jobs.lever.co/ginkgobioworks) talented folks who are interested in working in the field of synthetic biology.
