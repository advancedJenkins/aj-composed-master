# aj-Jenkins-Server-Compose

With this repository, you can establish **aj-composed-server** server - for loading a well-established Jenkins server.

In order to establish a  **aj-composed-server**, follow the below instructions on the server you want to host it:

1. Make sure you have the following commands installed: **git**, **docker** & **docker-compose**.
1. clone this repository (https://github.com/advancedJenkins/aj-composed-server) to a local folder and cd to it.
1. Run _**./aj.sh init**_ to see that the path to the SSH private key file is correct and to set all values.
1. Run _**./aj.sh start**_ to load the server. 
1. The first load will take at least 10 minutes, so please wait until the prompt is back.
1. Once the load is over, browse to [http://localhost:8080](http://localhost:8080) and login with admin/admin credentials.

Once the server is up, you can modify it (e.g. add LDAP configuration, add seed jobs, add credentials and much more) following the instructions as in [aj-bloody-jenkins](https://github.com/advancedJenkins/aj-bloody-jenkins) and all files in the 'customization' folder.

The _**./aj.sh**_ script have the following actions: **start**, **stop**, **restart**, **info**, **init**, **upgrade**, **status**, **apply**, **version**.

The loaded server is already configured to work with [aj-Jenkins-Pipeline](https://github.com/advancedJenkins/aj-jenkins-pipelines) so you can start working with it.
