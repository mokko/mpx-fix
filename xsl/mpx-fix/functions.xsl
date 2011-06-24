<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    exclude-result-prefixes="mpx xs func mpxvok"
    xmlns="http://www.mpx.org/mpx" xmlns:mpx="http://www.mpx.org/mpx"
    xmlns:func="http://www.mpx.org/mpxfunc"
    xmlns:mpxvok="http://www.mpx.org/mpxvok"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">

    <!--
        *****************
        * FUNCTIONS *
        *****************
    -->
    <xsl:function name="func:identifyObjektByIdentNr" as="xs:string">
        <xsl:param name="identNr"/>
        <xsl:param name="root"/>
        
        
        <xsl:variable name="objId"
            select="$root/mpx:museumPlusExport/mpx:sammlungsobjekt[mpx:identNr = normalize-space($identNr)]/@objId"/>
        <xsl:choose>
            <xsl:when test="count($objId) = 1">
                <!-- This is a clear case. There is only one PK record with that name -->
                <xsl:value-of select="$objId"/>
            </xsl:when>
            <xsl:when test="count($objId) > 1">
                <!--
                    This is an ambiguous case. There is more than one PK record with that name!
                    Could be two Gerd Müllers. No serious way to know which one, except if I had
                    the objects associated with the PKs
                -->
                <xsl:message>
                    <xsl:value-of
                        select="'Warn: objId not identified since ambiguous:',$objId, $identNr"/>
                </xsl:message>
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="count($objId) = 0">
                <xsl:value-of select="''"/>
                <xsl:message>
                    <xsl:value-of
                        select="'Warn: objId not identified since no record found: M',$objId, '|',$identNr,'|' "
                    />
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'Warn:I should not get here' "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="func:identifyPerKörByName" as="xs:string">
        <!--
            look thru all the perKör in this file, identify those with the same name and
            report back a kueId as well as meaningful error and diagnostic messages
            
            or as integer?
        -->
        <xsl:param name="name"/>
        <xsl:param name="root"/>
        
        <!--xsl:variable name="kueId"
            select="$root/mpx:museumPlusExport/mpx:personKörperschaft[mpx:nennform = $name]/@kueId"/ replace(replace (mpx:nennform,'\$',''),'§','')-->
        <xsl:variable name="kueId"
            select="$root/mpx:museumPlusExport/mpx:personKörperschaft[
            mpx:name = normalize-space($name) or
            mpx:name = normalize-space(concat($name,'$')) or
            mpx:name = normalize-space(concat($name,'§')) or
            mpx:nennform = normalize-space($name)
            ]/@kueId"/>
        <xsl:choose>
            <xsl:when test="count($kueId) = 1">
                <!-- This is a clear case. There is only one PK record with that name -->
                <xsl:value-of select="$kueId"/>
            </xsl:when>
            <xsl:when test="count($kueId) > 1">
                <!--
                    This is an ambiguous case. There is more than one PK record with that name!
                    Could be two Gerd Müllers. No serious way to know which one, except if I had
                    the objects associated with the PKs
                -->
                <xsl:message>
                    <xsl:value-of
                        select="'Warn: Name not identified since ambiguous:',$kueId, $name"/>
                </xsl:message>
                <xsl:value-of select="''"/>
            </xsl:when>
            <xsl:when test="count($kueId) = 0">
                <xsl:value-of select="''"/>
                <xsl:message>
                    <xsl:value-of
                        select="'Warn: Name not identified since no record found: M',$kueId, '|',$name,'|' "
                    />
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'Warn:I should not get here' "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="func:existsInVoc" as="xs:boolean">
        <xsl:param name="dictname"/>
        <xsl:param name="inputterm"/>
        <!-- Check if a term exists in a dictionary and return true or false -->
        <!-- These definitions should exist only once! -->
        <xsl:variable name="dictloc"
            select="document('file:mpxvok.xml')"/>
        <xsl:variable name="displaylang" select="'de'"/>
        
        <xsl:choose>
            <xsl:when test="exists ($dictloc/mpxvok:mpxvok/mpxvok:context[@name eq $dictname])">
                <xsl:variable name="dictConcepts"
                    select="$dictloc/mpxvok:mpxvok/mpxvok:context[@name eq $dictname]/mpxvok:concept"/>
                <xsl:choose>
                    <xsl:when
                        test="$inputterm = $dictConcepts/mpxvok:synonym or $inputterm = $dictConcepts/mpxvok:pref">
                        <xsl:value-of select="'true'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'false'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'false'"/>
                <xsl:message>
                    <xsl:value-of select="'Error: Cannot find dictionary!'"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="func:normalize-vok">
        <xsl:param name="dictname"/>
        <xsl:param name="inputterm"/>
        <xsl:param name="id"/>
        <!-- These definitions should exist only once! -->
        <xsl:variable name="dictloc"
            select="document('file:mpxvok.xml')"/>
        <xsl:variable name="displaylang" select="'de'"/>
        <xsl:variable name="debug" select="'no'"/>
        
        
        <!--
            this func expects a term as a string, it looks it up in a dictionary and returns the prefTrem in displaylang
            I report errors and warnings thru xsl:message, e.g. if term not found, return the original term plus a warning.
        -->
        
        <!-- TODO: test if dict with dictname exists, if not report error -->
        <xsl:choose>
            <xsl:when test="exists ($dictloc/mpxvok:mpxvok/mpxvok:context[@name eq $dictname])">
                <xsl:variable name="dictConcepts"
                    select="$dictloc/mpxvok:mpxvok/mpxvok:context[@name eq $dictname]/mpxvok:concept"/>
                <xsl:choose>
                    <xsl:when
                        test="$inputterm = $dictConcepts/mpxvok:synonym or
                        $inputterm = $dictConcepts/mpxvok:pref">
                        <!--
                            If term is found as prefTerm or synonym, return the prefTerm in displaylang.
                            I need the message only for debugging
                        -->
                        <xsl:variable name="new"
                            select="$dictConcepts[mpxvok:pref = $inputterm or mpxvok:synonym = $inputterm]/mpxvok:pref[@lang eq $displaylang]"/>
                        <xsl:value-of select="$new"/>
                        <xsl:if test="$debug eq 'yes'">
                            <xsl:message>
                                <xsl:value-of
                                    select="'Fix 14: Normalize Vok (',$inputterm,'-',$new, $id,')'"
                                />
                            </xsl:message>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- if term not found, return orig term and a warning-->
                        <xsl:value-of select="$inputterm"/>
                        <xsl:message>
                            <xsl:value-of
                                select="' Warn: Cannot normalize term (',$inputterm,$dictname, $id,')!'"
                            />
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:value-of select="'Error: Cannot find dictionary!'"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>
