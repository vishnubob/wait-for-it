# Tests for wait-for-it

* wait-for-it.py - pytests for wait-for-it.sh
* container-runners.py - Runs wait-for-it.py tests in multiple containers
* requirements.txt - pip requirements for container-runners.py

To run the basic tests:

```
python wait-for-it.py
```

Many of the issues encountered have been related to differences between operating system versions. The container-runners.py script provides an easy way to run the python wait-for-it.py tests against multiple system configurations:

```
pip install -r requirements.txt
python container-runners.py
```
