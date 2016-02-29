#!/bin/bash                                                                                                           │drwxr-xr-x 3 root    root    4,0K févr. 24 12:29 docker
                                                                                                                      │drwxrwxr-x 8 excilys excilys 4,0K févr. 25 16:00 .git
docker build -t cdb_jenkins .                                                                                                  │-rw-rw-r-- 1 excilys excilys  672 févr. 12 17:56 .gitignore
docker tag cdb_jenkins rlarroque/cdb_jenkins                                                                                            │drwxrwxr-x 4 excilys excilys 4,0K févr. 18 15:22 .metadata
docker push rlarroque/cdb_jenkins
