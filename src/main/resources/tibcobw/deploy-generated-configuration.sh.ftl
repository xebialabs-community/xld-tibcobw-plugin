<#--

    THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
    FOR A PARTICULAR PURPOSE. THIS CODE AND INFORMATION ARE NOT SUPPORTED BY XEBIALABS.

-->


<#assign container=targetDeployed.container />
<#assign traHome="${container.tibcoHome}/tra/${container.version}"/>

TMPXML=$(mktemp /tmp/${targetDeployed.applicationName}-XXXXXXX.xml)

<#if targetDeployed.configurationMap??>

    ${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -export -app ${targetDeployed.applicationName} -out $TMPXML -user ${container.username} -pw ${container.password} -domain ${container.domainPath}

    TMPFILE=$(mktemp)

    cat > $TMPFILE << EOF
<bindings>
    <binding name="Process Archive">
        <machine>${targetDeployed.firstNode.host.address}</machine>
        <product>
            <type>BW</type>
            <version>${targetDeployed.firstNode.version}</version>
            <location>${targetDeployed.firstNode.path}</location>
        </product>
        <setting>
            <startOnBoot>false</startOnBoot>
            <enableVerbose>false</enableVerbose>
            <maxLogFileSize>20000</maxLogFileSize>
            <maxLogFileCount>5</maxLogFileCount>
            <threadCount>8</threadCount>
            <java>
                <initHeapSize>32</initHeapSize>
                <maxHeapSize>256</maxHeapSize>
                <threadStackSize>256</threadStackSize>
            </java>
        </setting>
        <ftWeight>${targetDeployed.firstNodeWeight}</ftWeight>
        <shutdown>
            <checkpoint>false</checkpoint>
            <timeout>0</timeout>
        </shutdown>
    </binding>

<#if targetDeployed.secondNode??>

    <binding name="Process Archive-1">
        <machine>${targetDeployed.secondNode.host.address}</machine>
        <product>
            <type>BW</type>
            <version>${targetDeployed.secondNode.version}</version>
            <location>${targetDeployed.secondNode.path}</location>
        </product>
        <setting>
            <startOnBoot>false</startOnBoot>
            <enableVerbose>false</enableVerbose>
            <maxLogFileSize>20000</maxLogFileSize>
            <maxLogFileCount>5</maxLogFileCount>
            <threadCount>8</threadCount>
            <java>
                <initHeapSize>32</initHeapSize>
                <maxHeapSize>256</maxHeapSize>
                <threadStackSize>256</threadStackSize>
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

    xmlstarlet ed -L -d  "/_:application/_:services/_:bw/_:bindings" $TMPXML || exit 1
    xmlstarlet ed -L  --insert "/_:application/_:services/_:bw/_:NVPairs" --type elem -n xi_include \
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
            echo "[ERROR] xmlstarlet error"i >&2
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
            echo "[ERROR] xmlstarlet error"i >&2
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
    ${traHome}/bin/AppManage --propFile ${traHome}/bin/AppManage.tra -${command} -deployConfig $TMPXML -app ${targetDeployed.applicationName} -user ${container.username} -pw ${container.password} -domain ${container.domainPath} || exit 2
    
    rm $TMPXML

<#else>
    echo "[WARNING] There is no configuration data, please use configurationMap propeprty to fix it or use tibco.Configuration artifact" >&2
</#if>
