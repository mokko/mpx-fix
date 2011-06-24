<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="mpx xs func mpxvok"
    xmlns:mpx="http://www.mpx.org/mpx"
    xmlns:func="http://www.mpx.org/mpxfunc"
    xmlns:mpxvok="http://www.mpx.org/mpxvok"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">

    <xsl:template match="mpx:multimediaobjekt">
        <!--xsl:message>Das ist mume obj = resource</xsl:message-->
        <xsl:copy>
            <xsl:call-template name="freigabe"/>
            <xsl:call-template name="priorität"/>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!--
        Andreas Richter in Mail am 16. Mai:
        Die Präferenz eines Bildes wird nach der Signatur und nach einem
        Bindestrich mit einem Großbuchstaben angegeben:

        VII c 234 a,b -[A-Z] x.jpg

        "A" ist das "mandatory image" und soll in LIDO als "preferred" angezeigt werden.

        alle weiteren zu diesem DS gehörenden Bilder bekommen dann -B, -C,...

        Das x bezeichnet Bilder für den Export.

        TODO
        Wir warten auf eine neue Freigabepolitik für in M+ eingegebene
        Datensätze. Möglicherweise nehmen wir "Foto-Neg. Nr." und schreiben
        da etwas rein, wie "Web" für Webfreigabe.

    -->


    <!-- context is mpx: multimediaobjekt -->
    <xsl:template name="freigabe">
        <!-- general policy: restrictive - everything is restricted unless it is explicitedly allowed -->
        <xsl:attribute name="freigabe">
            <xsl:choose>
                <!-- Karteikarten '-KK' nicht ins Web -->
                <xsl:when test="matches(mpx:multimediaDateiname,'-KK')  ">
                    <xsl:message>KK -> keine Freigabe</xsl:message>
                    <xsl:value-of select=" 'intern' "/>
                </xsl:when>
                <!--xsl:when test=""/
                <xsl:otherwise>
                    <xsl:message>Mume: Freigabe = web</xsl:message>
                    <xsl:value-of select=" 'web' "/>
                </xsl:otherwise>
                -->
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <!-- context is mpx: multimediaobjekt -->
    <xsl:template name="priorität">
        <xsl:choose>
            <xsl:when test="matches(mpx:multimediaDateiname,'-A')  ">
                <xsl:message>F3: Priorität = 1</xsl:message>
                <xsl:attribute name="priorität">
                    <xsl:value-of select=" '1' "/>
                </xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>