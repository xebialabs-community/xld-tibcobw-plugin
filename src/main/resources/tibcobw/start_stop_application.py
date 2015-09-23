#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.
#

import itertools
from com.xebialabs.deployit.plugin.api.deployment.specification import Operation

def to_deployed(delta):
    return delta.deployedOrPrevious

def to_delta(candidate_filter):
    return set(filter(candidate_filter, deltas.deltas))

def stop_step(delta):
    return steps.os_script(
        description="Stop application %s" % to_deployed(delta).applicationName,
        order=10,
        script="tibcobw/appmanage",
        freemarker_context={'command': 'stop', 'targetDeployed': to_deployed(delta)},
        target_host=to_deployed(delta).container.host)

def start_step(delta):
    return steps.os_script(
        description="Start application %s" % to_deployed(delta).applicationName,
        order=90,
        script="tibcobw/appmanage",
        freemarker_context={'command': 'start', 'targetDeployed': to_deployed(delta)},
        target_host=to_deployed(delta).container.host)

def generate_steps(delta):
    if to_deployed(delta).startAdapterAfterDeploy:
        mod = [stop_step(delta), start_step(delta)]
    else:
        mod = [stop_step(delta)]
    return {
        Operation.CREATE : [start_step(delta)],
        Operation.MODIFY : mod,
        Operation.DESTROY: [stop_step(delta)],
        Operation.NOOP:    []
    }.get(delta.operation,"NOT FOUND")


def add_steps_to_context(generated_steps):
    # reduce the stop & start step per application.
    reduced_steps =dict((step.getDescription(), step) for step in itertools.chain(*generated_steps))
    # add the steps to the context.
    [context.addStep(step) for step in reduced_steps.values()]


add_steps_to_context(map(generate_steps, to_delta(lambda delta: (to_deployed(delta).type in ["tibco.DeployedEar", 'tibco.DeployedConfiguration']))))

