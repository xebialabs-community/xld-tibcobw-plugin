<#--

    Copyright 2018 XEBIALABS

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-->

<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

TMPXML=$(mktemp /tmp/${targetDeployed.applicationName}-XXXXXXX.xml)

<#if targetDeployed.configurationMap??>

    ${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -serialize -export -app ${targetDeployed.applicationName} -out $TMPXML -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

    TMPFILE=$(mktemp)

    cat > $TMPFILE << EOF
<bindings>
    <binding name="${targetDeployed.applicationName}.par">
        <machine>${targetDeployed.firstNode.host.address}</machine>
        <product>
            <type>BW</type>
            <version>${targetDeployed.firstNode.bwVersion}</version>
            <location>${targetDeployed.firstNode.bwPath}/${targetDeployed.firstNode.bwVersion}</location>
        </product>
        <setting>
            <startOnBoot>${targetDeployed.startOnBoot?string}</startOnBoot>
            <enableVerbose>${targetDeployed.enableVerbose?string}</enableVerbose>
            <maxLogFileSize>${targetDeployed.maxLogFileSize}</maxLogFileSize>
            <maxLogFileCount>${targetDeployed.maxLogFileCount}</maxLogFileCount>
            <threadCount>${targetDeployed.threadCount}</threadCount>
            <java>
                <initHeapSize>${targetDeployed.initHeapSize}</initHeapSize>
                <maxHeapSize>${targetDeployed.maxHeapSize}</maxHeapSize>
                <threadStackSize>${targetDeployed.threadStackSize}</threadStackSize>
            </java>
        </setting>
        <ftWeight>${targetDeployed.firstNodeWeight}</ftWeight>
        <shutdown>
            <checkpoint>false</checkpoint>
            <timeout>0</timeout>
        </shutdown>
    </binding>

<#if targetDeployed.secondNode??>

    <binding name="${targetDeployed.applicationName}-1.par">
        <machine>${targetDeployed.secondNode.host.address}</machine>
        <product>
            <type>BW</type>
            <version>${targetDeployed.secondNode.bwVersion}</version>
            <location>${targetDeployed.secondNode.bwPath}/{targetDeployed.secondNode.bwVersion}</location>
        </product>
        <setting>
            <startOnBoot>${targetDeployed.startOnBoot?string}</startOnBoot>
            <enableVerbose>${targetDeployed.enableVerbose?string}</enableVerbose>
            <maxLogFileSize>${targetDeployed.maxLogFileSize}</maxLogFileSize>
            <maxLogFileCount>${targetDeployed.maxLogFileCount}</maxLogFileCount>
            <threadCount>${targetDeployed.threadCount}</threadCount>
            <java>
                <initHeapSize>${targetDeployed.initHeapSize}</initHeapSize>
                <maxHeapSize>${targetDeployed.maxHeapSize}</maxHeapSize>
                <threadStackSize>${targetDeployed.threadStackSize}</threadStackSize>
            </java>
        </setting>
        <ftWeight>${targetDeployed.secondNodeWeight}</ftWeight>
        <shutdown>
            <checkpoint>false</checkpoint>
            <timeout>0</timeout>
        </shutdown>
    </binding>

</#if>

</bindings>

EOF

<#if targetDeployed.runFaultTolerant>

    xmlstarlet ed -L  -u "/_:application/_:services/_:bw/_:isFt" -v "true" $TMPXML
    xmlstarlet ed -L  -a "/_:application/_:services/_:bw/_:isFt" --type elem -n "faultTolerant" $TMPXML
    xmlstarlet ed -L  --subnode "/_:application/_:services/_:bw/_:faultTolerant" --type elem -n "hbInterval" -v ${targetDeployed.heartbeatInterval} $TMPXML
    xmlstarlet ed -L  --subnode "/_:application/_:services/_:bw/_:faultTolerant" --type elem -n "activationInterval" -v ${targetDeployed.activationInterval} $TMPXML
    xmlstarlet ed -L  --subnode "/_:application/_:services/_:bw/_:faultTolerant" --type elem -n "preparationDelay" -v ${targetDeployed.activationDelay} $TMPXML

</#if>

<#if targetDeployed.checkpointDataRepository != "Local File" >
    <#if targetDeployed.checkpointTablePrefix??> 
        xmlstarlet edit -L -u '/_:application/_:services/_:bw/_:checkpoints/_:tablePrefix' -v '${targetDeployed.checkpointTablePrefix}' $TMPXML
    </#if>
    xmlstarlet sel -t -v '/_:application/_:services/_:bw/_:checkpoints/_:checkpoint[.="${targetDeployed.checkpointDataRepository}"]' $TMPXML
    XMLSTARLET_EXIT_CODE=$?
    if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
    then
        echo "[ERROR] checkpointDataRepository is incorrect" >&2
        exit 5
    fi
    xmlstarlet edit -L -u '/_:application/_:services/_:bw/_:checkpoints/@selected' -v '${targetDeployed.checkpointDataRepository}' $TMPXML
</#if>

    xmlstarlet ed -L -d  "/_:application/_:services/_:bw/_:bindings" $TMPXML || exit 1
    xmlstarlet ed -L -a "/_:application/_:services/_:bw/_:enabled" --type elem -n xi_include \
    	-i //xi_include --type attr -n xmlns:xi -v http://www.w3.org/2003/XInclude     \
    	-i //xi_include --type attr -n href -v $TMPFILE -r //xi_include -v xi:include $TMPXML || exit 1

    xmllint --xinclude $TMPXML --output $TMPXML || exit 1

    <#list targetDeployed.configurationMap?keys as key>
        echo "---------------------------------------"
        echo "Processing ${key} with value  ${targetDeployed.configurationMap[key]}"
        echo "Check if the value exists"
        XML_SEL=$(xmlstarlet sel -t -v '/_:application/_:NVPairs/_:*/_:name="${key}"' $TMPXML)
        XMLSTARLET_EXIT_CODE=$?
        if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
        then
            echo "[ERROR] xmlstarlet error" >&2
            exit 2
        fi
        
        if [ "x$XML_SEL" = "xtrue" ]
        then
            echo "Get the packaged (default) value for ${key}"
            xmlstarlet sel -t -v '/_:application/_:NVPairs/*[_:name="${key}"]/_:value' $TMPXML
            XMLSTARLET_EXIT_CODE=$?
            if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
            then
                echo "[WARNING] Cannot get the packaged value for ${key}, maybe value is empty"
            fi
            if [[ x"${targetDeployed.configurationMap[key]}" = x"{{"*${key}"}}" ]]
            then
                echo "Parameter ${key} isn't defined for deploy"
            else
                echo "Change the value"
                xmlstarlet edit -L -u '/_:application/_:NVPairs/*[_:name="${key}"]/_:value' -v '${targetDeployed.configurationMap[key]}' $TMPXML
                XMLSTARLET_EXIT_CODE=$?
                if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
                then
                    echo "[ERROR] Cannot change the packaged value for ${key} -> ${targetDeployed.configurationMap[key]}'"
                    exit 4
                fi
            fi
        else
            echo "Skip processing ${key}"
        fi
    </#list>
    <#list targetDeployed.configurationMapAdapterSDK?keys as key>
        echo "---------------------------------------"
        echo "Processing ${key} with value  ${targetDeployed.configurationMapAdapterSDK[key]}"
        echo "Check if the value exists"
	XML_SEL=$(xmlstarlet sel -t -v '/_:application/_:services/_:bw/_:NVPairs/_:*/_:name="${key}"' $TMPXML)
        XMLSTARLET_EXIT_CODE=$?
        if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
        then
            echo "[ERROR] xmlstarlet error" >&2
            exit 2
        fi
        if [ "x$XML_SEL" = "xtrue" ]
        then
            echo "Get the packaged (default) value for ${key}"
            xmlstarlet sel -t -v '/_:application/_:services/_:bw/_:NVPairs/*[_:name="${key}"]/_:value' $TMPXML
            XMLSTARLET_EXIT_CODE=$?
            if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
            then
                echo "[WARNING] Cannot get the packaged value for ${key}, maybe value is empty"
            fi
            if [[ x"${targetDeployed.configurationMapAdapterSDK[key]}" == x"{{"*${key}"}}" ]]
            then
                echo "Parameter ${key} isn't defined for deploy"
            else
                echo "Change the value"
                xmlstarlet edit -L -u '/_:application/_:services/_:bw/_:NVPairs/*[_:name="${key}"]/_:value' -v '${targetDeployed.configurationMapAdapterSDK[key]}' $TMPXML
                XMLSTARLET_EXIT_CODE=$?
                if [ $XMLSTARLET_EXIT_CODE -ne 0 ]
                then
                    echo "[ERROR] Cannot change the packaged value for ${key} -> ${targetDeployed.configurationMapAdapterSDK[key]}'"
                    exit 4
                fi
            fi
        else
            echo "Skip processing ${key}"
        fi

	                                     
    </#list>
    echo "===XML configuration has been generated $TMPXML==="
    ${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -serialize -${command} -deployConfig $TMPXML -app ${targetDeployed.applicationName} -user ${container.username} -pw ${container.password} -domain ${container.domainPath} -nostart
    
    APPMANAGE_EXIT_CODE=$?
    if [ $APPMANAGE_EXIT_CODE -ne 0 ]
    then
        tail -25 ${traHome}/domain/${container.domainPath}/logs/ApplicationManagement.log
	exit 2
    exit
    
    rm $TMPXML

<#else>
    echo "[WARNING] There is no configuration data, please use configurationMap propeprty to fix it or use tibco.Configuration artifact" >&2
</#if>
