--[[=============================================================================
    Functions for parsing and managing xml

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_xml = "2015.03.02"
end

--[[=============================================================================
    GetParsedXmlNode(tXml, node)

    Description: 
    Find the specified node within the given table

    Parameters:
    tXml(table)  - Xml fragment containing the node we are looking for
    node(string) - The name of the node

    Returns:
    nil or the specified node within the table
===============================================================================]]
function GetParsedXmlNode(tXml, node)
	for k, v in pairs(tXml["ChildNodes"]) do
		if (v["Name"] == node) then
			return v["ChildNodes"]
		end
	end

	return nil
end

--[[=============================================================================
    GetParsedXmlValuesByKey(tXml, node, key, keyIsNumber)

    Description: 
    Find the specified node element within the given table

    Parameters:
    tXml(table)       - Xml fragment to find the value in
    node(string)      - The name of the node
    key(string)       - The name of the key
    keyIsNumber(bool) - Indicates whether the table index is a number or a string

    Returns:
    nil or a table of the found values within the Xml
===============================================================================]]
function GetParsedXmlValuesByKey(tXml, node, key, keyIsNumber)
	local tParams = {}

	keyIsNumber = keyIsNumber or false
	for k,v in pairs(tXml) do
		if (v["Name"] == node) then
			local keyValue
			
			-- get the key
			for nodeKey, nodeValue in pairs(v["ChildNodes"]) do
				if (nodeValue["Name"] == key) then
					if (keyIsNumber == true) then
						keyValue = tonumber(nodeValue.Value)
					else
						keyValue = tostring(nodeValue.Value)
					end
					break
				end
			end

			-- get other tags
			tParams[keyValue] = {}
			for nodeKey, nodeValue in pairs(v["ChildNodes"]) do
				if (nodeValue["Name"] ~= key) then
					tParams[keyValue][nodeValue.Name] = nodeValue.Value
				end
			end
		end
	end

	return tParams
end

--[[=============================================================================
    GetParsedXmlVaulesByKeyAttribute(tXml, node, key, keyIsNumber)

    Description: 
    Find the specified node attribute within the given table

    Parameters:
    tXml(table)       - Xml fragment to find the value in
    node(string)      - The name of the node
    key(string)       - The name of the key
    keyIsNumber(bool) - Indicates whether the table index is a number or a string

    Returns:
    nil or a table of the found values within the Xml
===============================================================================]]
function GetParsedXmlVaulesByKeyAttribute(tXml, node, key, keyIsNumber)
	local tParams = {}

	keyIsNumber = keyIsNumber or false
	for k,v in pairs(tXml["ChildNodes"]) do
		if (v["Name"] == node) then
			local keyValue

			if (keyIsNumber == true) then
				keyValue = tonumber(v["Attributes"][key])
			else
				keyValue = v["Attributes"][key]
			end
			
			tParams[keyValue] = v["Value"]
		end
	end

	return tParams
end

--[[=============================================================================
    BuildSimpleXml(tag, tData, escapeValue)

    Description: 
    Find the specified node within the given table

    Parameters:
    tag(string)       - Xml tag name to create
    tData(table)      - key value pairs that will be added as elements under tag
    escapeValue(bool) - Indicates whether the values should be escaped or not

    Returns:
    nil or an Xml fragment the specified node within the table
===============================================================================]]
function BuildSimpleXml(tag, tData, escapeValue)
	local xml = ""
	
	if (tag ~= nil) then
		xml = "<" .. tag .. ">"
	end
	
	for k,v in pairs(tData) do
		xml = xml .. "<" .. k
		if (type(v) == "table") then
			-- handle attributes
			for kAttrib, vAttrib in pairs(v.attributes) do
				xml = xml .. ' ' .. kAttrib .. '=\"' .. vAttrib .. '\"'
			end
			xml = xml .. ">" .. InsertValue(v.value, escapeValue) .. "</" .. k .. ">"
		else
			xml = xml .. ">" .. InsertValue(v, escapeValue) .. "</" .. k .. ">"
		end
	end
	
	if (tag ~= nil) then
		xml = xml .. "</" .. tag .. ">"
	end

	--DbgTrace("BuildSimpleXml(): " .. xml)

	return xml
end

--[[=============================================================================
    InsertValue(value, escapeValue)

    Description: 
    Return the given value if escapeValue is true it will escape any special
    characters in the value

    Parameters:
    value(string)     - value to be manipulated
    escapeValue(bool) - Indicates whether the values should be escaped or not

    Returns:
    The value given or an escaped value if specified
===============================================================================]]
function InsertValue(value, escapeValue)

	if (escapeValue) then
		value = C4:XmlEscapeString(tostring(value))
	end

	return value
end

--[[=============================================================================
    StartElement(tag)

    Description: 
    Wrap the given tag as an Xml element (i.e. <tag>)

    Parameters:
    tag(string) - The name of the item to be wrapped as a starting Xml element

    Returns:
    The value wrapped as Xml tag
===============================================================================]]
function StartElement(tag)
	return "<" .. tag .. ">"
end

--[[=============================================================================
    EndElement(tag)

    Description: 
    Wrap the given tag as an Xml end element (i.e. </tag>)

    Parameters:
    tag(string) - The name of the item to be wrapped as a ending Xml element

    Returns:
    The value wrapped as ending Xml tag
===============================================================================]]
function EndElement(tag)
	return "</" .. tag .. ">"
end

--[[=============================================================================
    AddElement(tag, data)

    Description: 
    Wrap the given tag and value as an Xml element (i.e. <tag>data</tag>)

    Parameters:
    tag(string)  - The name of the item to be wrapped as an Xml element
    data(string) - The value of the Xml element being created

    Returns:
    The value wrapped as Xml tag and value
===============================================================================]]
function AddElement(tag, data)
	LogTrace("tag = " .. tag)
	LogTrace("data = " .. data)
	
	return "<" .. tag .. ">" .. data .. "</" .. tag .. ">"
end
