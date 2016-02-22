<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->
workDir=$(pwd)
<#if targetDeployed.store??>
echo "create ${resource} ${targetDeployed.name} store=${targetDeployed.store}, prefetch=${targetDeployed.prefetch}" > xld_run.ems
<#else>
echo "create ${resource} ${targetDeployed.name} prefetch=${targetDeployed.prefetch}" > xld_run.ems
</#if>
echo " " >> xld_run.ems
echo "commit" >> xld_run.ems
echo "quit" >> xld_run.ems

cat xld_run.ems

${targetDeployed.container.home}/bin/tibemsadmin -server "${targetDeployed.container.serverUrl}" -user ${targetDeployed.container.username} <#if targetDeployed.container.password?? >-password ${targetDeployed.container.password}</#if> -script $workDir/xld_run.ems
