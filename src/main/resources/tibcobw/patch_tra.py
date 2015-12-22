#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.
#

#import itertools
#from com.xebialabs.deployit.plugin.api.deployment.specification import Operation

container = deployed.container
nodes = [ deployed.firstNode ]
if deployed.secondNode is not None:
    nodes.append(deployed.secondNode)
for node in nodes:
    context.addStep(steps.os_script(
            description = "Patch TRA file for application %s on host %s" % (deployed.applicationName , node.host),
            order=78,
            target_host=node.host,
            script="tibcobw/tra/patch",
            freemarker_context = {
                "targetDeployed" : deployed,
                "node" : node
            }
        ))

