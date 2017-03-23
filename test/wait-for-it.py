import unittest
import subprocess
import shlex
from subprocess import Popen, PIPE
import os
import sys


class TestWaitForIt(unittest.TestCase):

    
    def execute(self,cmd):
        """Executes a command and returns exit code, STDOUT, STDERR"""
        args = shlex.split(cmd)
        proc = Popen(args, stdout=PIPE, stderr=PIPE)
        out, err = proc.communicate()
        exitcode = proc.returncode
        return exitcode, out, err
    
    def setUp(self):
        script_path = os.path.dirname(sys.argv[0])
        parent_path = os.path.abspath(os.path.join(script_path, os.pardir))
        self.wait_script = os.path.join(parent_path,"wait-for-it.sh")

    def test_no_args_return_code(self):
        # Return code should be 1 when called with no args
        exitcode, out, err = self.execute(self.wait_script)
        self.assertEqual(exitcode,1)        
        
    def test_help(self):
        exitcode, out, err = self.execute(self.wait_script+" --help")
        # STDERR should begin with "Usage:"
        self.assertTrue(err.startswith("Usage:"))
        # exit code should be 1
        self.assertEqual(exitcode,1)



if __name__ == '__main__':
    unittest.main()
