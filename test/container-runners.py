#!/usr/bin/env python

# Unit tests to run wait-for-it.py unit tests in several different docker images

import unittest
import os
import docker
from parameterized import parameterized

client = docker.from_env()
app_path = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..'))
volumes = {app_path: {'bind': '/app', 'mode': 'ro'}}

class TestContainers(unittest.TestCase):
    """
        Test multiple container types with the test cases in wait-for-it.py
    """

    @parameterized.expand([
        "python:3.5-buster",
        "python:3.5-stretch",
        "dougg/alpine-busybox:alpine-3.11.3_busybox-1.30.1",
        "dougg/alpine-busybox:alpine-3.11.3_busybox-1.31.1"
    ])
    def test_image(self, image):
        print(image)
        command="/app/test/wait-for-it.py"
        container = client.containers.run(image, command=command, volumes=volumes, detach=True)
        result = container.wait()
        logs = container.logs()
        container.remove()
        self.assertEqual(result["StatusCode"], 0)

if __name__ == '__main__':
    unittest.main()
