#!/usr/bin/env python

import unittest
import shlex
from subprocess import Popen, PIPE
import os
import sys
import socket
import re

MISSING_ARGS_TEXT = "Error: you need to provide a host and port to test."
HELP_TEXT = "Usage:"  # Start of help text
DIVIDE_LINE = '-'*71  # Output line of dashes


class TestWaitForIt(unittest.TestCase):
    """
        TestWaitForIt tests the wait-for-it.sh shell script.
        The wait-for-it.sh script is assumed to be in the parent directory to
        the test script.
    """

    def execute(self, cmd):
        """Executes a command and returns exit code, STDOUT, STDERR"""
        args = shlex.split(cmd)
        proc = Popen(args, stdout=PIPE, stderr=PIPE)
        out, err = proc.communicate()
        exitcode = proc.returncode
        return exitcode, out.decode('utf-8'), err.decode('utf-8')

    def open_local_port(self, timeout=5):
        s = socket.socket()
        s.bind(('', 0))
        s.listen(timeout)
        return s, s.getsockname()[1]

    def check_args(self, args, stdout_regex, stderr_regex, should_succeed):
        command = self.wait_script + " " + args
        exitcode, out, err = self.execute(command)

        # Check stderr
        msg = ("Failed check that STDERR:\n" +
               DIVIDE_LINE + "\n" + err + "\n" + DIVIDE_LINE +
               "\nmatches:\n" +
               DIVIDE_LINE + "\n" + stderr_regex + "\n" + DIVIDE_LINE)
        self.assertIsNotNone(re.match(stderr_regex, err, re.DOTALL), msg)

        # Check STDOUT
        msg = ("Failed check that STDOUT:\n" +
               DIVIDE_LINE + "\n" + out + "\n" + DIVIDE_LINE +
               "\nmatches:\n" +
               DIVIDE_LINE + "\n" + stdout_regex + "\n" + DIVIDE_LINE)
        self.assertIsNotNone(re.match(stdout_regex, out, re.DOTALL), msg)

        # Check exit code
        self.assertEqual(should_succeed, exitcode == 0)

    def setUp(self):
        script_path = os.path.dirname(sys.argv[0])
        parent_path = os.path.abspath(os.path.join(script_path, os.pardir))
        self.wait_script = os.path.join(parent_path, "wait-for-it.sh")

    def test_no_args(self):
        """
            Check that no aruments returns the missing args text and the
            correct return code
        """
        self.check_args(
            "",
            "^$",
            MISSING_ARGS_TEXT,
            False
        )
        # Return code should be 1 when called with no args
        exitcode, out, err = self.execute(self.wait_script)
        self.assertEqual(exitcode, 	1)

    def test_help(self):
        """ Check that help text is printed with --help argument """
        self.check_args(
           "--help",
           "",
           HELP_TEXT,
           False
        )

    def test_no_port(self):
        """ Check with missing port argument """
        self.check_args(
            "--host=localhost",
            "",
            MISSING_ARGS_TEXT,
            False
        )

    def test_no_host(self):
        """ Check with missing hostname argument """
        self.check_args(
            "--port=80",
            "",
            MISSING_ARGS_TEXT,
            False
        )

    def test_host_port(self):
        """ Check that --host and --port args work correctly """
        soc, port = self.open_local_port()
        self.check_args(
            "--host=localhost --port={0} --timeout=1".format(port),
            "",
            "wait-for-it.sh: waiting 1 seconds for localhost:{0}".format(port),
            True
        )
        soc.close()

    def test_combined_host_port(self):
        """
            Tests that wait-for-it.sh returns correctly after establishing a
            connectionm using combined host and ports
        """
        soc, port = self.open_local_port()
        self.check_args(
            "localhost:{0} --timeout=1".format(port),
            "",
            "wait-for-it.sh: waiting 1 seconds for localhost:{0}".format(port),
            True
        )
        soc.close()


    def test_port_failure_with_timeout(self):
        """
            Note exit status of 124 is exected, passed from the timeout command
        """
        self.check_args(
            "localhost:8929 --timeout=1",
            "",
            ".*timeout occurred after waiting 1 seconds for localhost:8929",
            False
        )

    def test_command_execution(self):
        """
            Checks that a command executes correctly after a port test passes
        """
        soc, port = self.open_local_port()
        self.check_args(
            "localhost:{0} -- echo \"CMD OUTPUT\"".format(port),
            "CMD OUTPUT",
            ".*wait-for-it.sh: localhost:{0} is available after 0 seconds".format(port),
            True
        )
        soc.close()

    def test_failed_command_execution(self):
        """
            Check command failure. The command in question outputs STDERR and
            an exit code of 2
        """
        soc, port = self.open_local_port()
        self.check_args(
            "localhost:{0} -- ls not_real_file".format(port),
            "",
            ".*No such file or directory\n",
            False
        )
        soc.close()

    def test_command_after_connection_failure(self):
        """
            Test that a command still runs even if a connection times out
            and that the return code is correct for the comand being run
        """
        self.check_args(
            "localhost:8929 --timeout=1 -- echo \"CMD OUTPUT\"",
            "CMD OUTPUT",
            ".*timeout occurred after waiting 1 seconds for localhost:8929",
            True
        )

if __name__ == '__main__':
    unittest.main()
