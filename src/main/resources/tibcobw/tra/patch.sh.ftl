<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->

set -e 

function java_property { #file.properties #property #value
    PROP=$(echo $2 | sed 's/\./\\./g')
    sed -i "s#^$PROP=.*#$2=$3#g" $1
    grep -q "^$PROP=" $1 || echo "$2=$3" >> $1
}

<#assign container=targetDeployed.container />
<#assign traHome="${node.traPath}/${node.traVersion}"/>

TMPXML=$(mktemp /tmp/${targetDeployed.applicationName}-XXXXXXX.xml)

${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -serialize -export -app ${targetDeployed.applicationName} -out $TMPXML -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

DEPL_NAME=$(xmlstarlet sel -t -v '/_:application/_:repoInstanceName' $TMPXML| sed 's/%%DOMAIN%%-//')
TRA_FILE=${node.traPath}/domain/${targetDeployed.container.domainPath}/application/$DEPL_NAME/$DEPL_NAME-Process_Archive*.tra

<#if targetDeployed.agentPath??>
     <#list targetDeployed.agentPath as agent>
         AGENT_PATH="-agentpath:${agent} $AGENT_PATH"
     </#list>
</#if>

<#if targetDeployed.javaAgent??>
     <#list targetDeployed.javaAgent as agent>
         JAVAAGENT_PATH="-javaagent:${agent} $JAVAAGENT_PATH"
     </#list>
</#if>

export EXT_OPTS="$JAVAAGENT_PATH$AGENT_PATH\
<#if targetDeployed.loggc>-Xloggc:${targetDeployed.loggcPath}/${targetDeployed.applicationName}-gc.log<#if targetDeployed.UseGCLogFileRotation> -XX:+UseGCLogFileRotation -XX:GCLogFileSize=${targetDeployed.GCLogFileSize}M -XX:NumberOfGCLogFiles=${targetDeployed.NumberOfGCLogFiles}</#if> </#if>\
<#if targetDeployed.HeapDumpOnOutOfMemoryError>-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${targetDeployed.HeapDumpPath} </#if>\
<#if targetDeployed.MaxPermSize??>-XX:MaxPermSize=${targetDeployed.MaxPermSize}M </#if>\
<#if targetDeployed.MiscExtProperties??>${targetDeployed.MiscExtProperties}</#if>"

EXT_OPTS=$(echo $EXT_OPTS | sed 's/ +$//'| sed 's/\([:,=]\)/\\\1/g')

echo EXT_OPTS=$EXT_OPTS

java_property $TRA_FILE java.extended.properties "$EXT_OPTS"

<#if targetDeployed.JmxEnabled>
java_property $TRA_FILE Jmx.Enabled true
</#if>

<#if targetDeployed.TraMap??>
     <#list targetDeployed.TraMap?keys as key>
         java_property $TRA_FILE ${key} "${targetDeployed.TraMap[key]}"
     </#list>
</#if>
