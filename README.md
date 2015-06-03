# Preface #

This document describes the functionality provided by the [Tibco Business Work](http://www.tibco.com/products/automation/application-integration/activematrix-businessworks) plugin.

See the [**XL Deploy product description**](https://docs.xebialabs.com/xl-deploy/) for background information on XL Deploy and deployment concepts.

# Overview #

The Tibco Business Work plugin is a XL Deploy plugin that adds capability for deploying  :

* a Tibco Ear to a Tibco domain and its XML configuration
* a queue, a topic and an EMS Script on a EMS Server

# Requirements #

* **XL Deploy requirements**
	* **XLD**: version 4.5.1+

## Types ##

+ tibco.Ear
+ tibco.Domain
+ tibco.Node
+ tibco.Configuration
+ tibco.Queue
+ tibco.Topic
+ tibco.EmsScript
+ tibco.PrependLib
+ tibco.BwaaLib
+ tibco.BwaaAspect


# Sample computed task #

This is below a typical computed task by the Tibco Business Work plugin during an upgrade.

![Deployment task](update-task.png)


