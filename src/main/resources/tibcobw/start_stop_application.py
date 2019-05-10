#
# Copyright 2019 XEBIALABS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
        Operation.CREATE: [start_step(delta)],
        Operation.MODIFY: mod,
        Operation.DESTROY: [stop_step(delta)],
        Operation.NOOP: []
    }.get(delta.operation, "NOT FOUND")


def add_steps_to_context(generated_steps):
    # reduce the stop & start step per application.
    reduced_steps = dict((step.getDescription(), step) for step in itertools.chain(*generated_steps))
    # add the steps to the context.
    [context.addStep(step) for step in reduced_steps.values()]


add_steps_to_context(map(generate_steps, to_delta(lambda delta: (to_deployed(delta).type in ["tibco.DeployedEar", 'tibco.DeployedConfiguration']))))
