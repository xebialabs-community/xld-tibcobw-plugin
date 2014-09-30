# Preface #

This document describes the functionality provided by the Tibco Business Work plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

# Overview #

The Tibco Business Work plugin is a XL Deploy plugin that adds capability for deploying  :

* a Tibco Ear to a HAWK domain and its XML configuration
* a EMS Script on a EMS Server

# Requirements #

* **XL Deploy requirements**
	* **XLD**: version 4.5.1+

## Types ##

+ tibcobw.Ear.
+ tibcobw.Configuration.
+ tibcobw.EmsScript.

# Sample computed task #

This is below a typical computed task by the Tibco Business Work plugin during an upgrade.

![Deployment task](update-task.png)


# TODO #

* Implement configure queue (instead of using EmsScript)
* Implement configure topic (instead of using EmsScript)
* Implement configure queue factory (instead of using EmsScript)

