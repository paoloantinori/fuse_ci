# Fuse Scripts
---------------

A sample multimodule Maven Project that can be used as a quickstart to setup a development project based on **JBoss Fuse**.

### Description

The project is divided in 2 main sections:  
1. Modules
2. CI

#### 1. Modules
Modules is where you place your custom code, in form of maven modules. The only requirements that you have is that those module are OSGi compatible, to deploy correctly on Fuse.  

Attached to this project you find 2 dummy Camel based modules, there just to allow you to track back references to them in he other part of the quickstart.

#### 2. CI
CI is a collection of modules and plain scripts that automate the provisioning and release of you project.  

It's divided in:
1. config
2. deploy_scripts
3. features
4. karaf_scripts
5. offline_maven_repo

##### 2.1 config
In config you put all the properties that you'd like to keep independent from the Maven build job.  
In the base example we have just a single `.properties` file that we use to override values that are defined **also** in the Maven job.  
We use this mechanism to allow a hook to override values directly at the filesystem level. In our implementation the script that contains the default Karaf constants values is automatically loading the script specified with the Maven variable `overridden.properties.path` and loading it, it will have the capability to override default values.

##### 2.2 deploy_scripts
In this section you will find example `bash` scripts that show you how to trigger the process end to end.

##### 2.3 features
In this Maven project you define your features files. Features files are **Karaf unit of deployment** and are a convenient way to organize you bundle and your configuration.  Each time you add a new Maven module to your project, your probably want to add a correspondent xml node in your features files, with the description of the components that you want to logically group.

##### 2.4 karaf_scripts
In this Maven project we put most of the Karaf interaction commands, in form of `.karaf` scripts.  
In these scripts you may specify the container that you want to create, the fabric profiles, their specific configuration and you also define which of your defined **features** you want to deploy to which specific **Fabric profiles**.  
You may invoke these scripts from withing Karaf shell with their absolute file system path or via their Maven coordinates. You will find examples of usage inside the `deploy_scripts`

##### 2.5 offline_maven_repo
In this Maven project you will find the configuration needed to produce a `.zip` archive containing all the Maven artifacts that your project will require. In this way, you will be able to deploy your project without the requirement of having internet connectivity or access to a Nexus Maven repository.  
The way to define which artifacts you want to pack is to define the correspondent **features** that you want to include.

-------------------
#### To  build the project
    mvn clean install -DskipTests -Dmaven.test.skip
#### To depoy
Study the scripts inside `ci/deploy_scripts`

