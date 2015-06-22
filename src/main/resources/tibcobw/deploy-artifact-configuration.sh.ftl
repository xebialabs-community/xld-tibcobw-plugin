<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->
<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -serialize -${command} -deployConfig ${targetDeployed.file} -app ${targetDeployed.applicationName} -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

