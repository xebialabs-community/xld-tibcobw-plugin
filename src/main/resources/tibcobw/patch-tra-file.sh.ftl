<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->



export EXT_OPTS="<#if targetDeployed.javaAgent??>-javaagent\\:${targetDeployed.javaAgent} </#if>\
<#if targetDeployed.agentPath??>-agentpath\\:${targetDeployed.agentPath} </#if>\
<#if targetDeployed.loggc>-Xloggc\\:${targetDeployed.loggcPath}/${targetDeployed.applicationName}-gc.log<#if targetDeployed.UseGCLogFileRotation> -XX\\:+UseGCLogFileRotation -XX\:GCLogFileSize\\=${targetDeployed.GCLogFileSize} -XX\\:NumberOfGCLogFiles\\=${targetDeployed.NumberOfGCLogFiles}</#if> </#if>\
<#if targetDeployed.HeapDumpOnOutOfMemoryError>-XX\\:+HeapDumpOnOutOfMemoryError -XX\\:HeapDumpPath\\=${targetDeployed.HeapDumpPath} </#if>\
<#if targetDeployed.MiscExtProperties??>${targetDeployed.MiscExtProperties}</#if>"

EXT_OPTS=$(echo $EXT_OPTS | sed 's/ +$//')

echo EXT_OPTS=$EXT_OPTS

export SSH_CMD="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
echo "java.extended.properties=$EXT_OPTS" | $SSH_CMD ${targetDeployed.firstNode.host.address} "cat >> ${targetDeployed.firstNode.traPath}/domain/${targetDeployed.container.domainPath}/application/${targetDeployed.applicationName}-modified/${targetDeployed.applicationName}-modified-Process_Archive*.tra "
<#if targetDeployed.secondNode??>
echo "java.extended.properties=$EXT_OPTS" | $SSH_CMD ${targetDeployed.secondNode.host.address} "cat >> ${targetDeployed.secondNode.traPath}/domain/${targetDeployed.container.domainPath}/application/${targetDeployed.applicationName}-modified/${targetDeployed.applicationName}-modified-Process_Archive*.tra "
</#if>
