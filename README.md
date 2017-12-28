puppet-role_salep
===================

Puppet role definition for deployment of treebase using docker

Parameters
-------------
Sensible defaults for Naturalis in init.pp

```



```


Classes
-------------
- role_dockertreebase::init

Dependencies
-------------
gareth/docker


Puppet code
```
class { role_dockertreebase: }
```
Result
-------------
Running treebase server with empty db


Limitations
-------------
This module has been built on and tested against Puppet 4 and higher.

The module has been tested on:
- Ubuntu 16.04LTS

Dependencies releases tested: 
- gareth/docker 5.3.0







Authors
-------------
Author Name <hugo.vanduijn@naturalis.nl>

