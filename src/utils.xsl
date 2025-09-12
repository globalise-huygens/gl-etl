<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:util="github.com/knaw-huc/util-server"
    exclude-result-prefixes="xs math util"
    version="3.0">
    
    <xsl:param name="util-server" select="'http://util-server:8000'"/>
    
    <xsl:function name="util:uuid">
        <xsl:sequence select="unparsed-text(concat($util-server,'/uuid'))"/>
    </xsl:function>

    <xsl:function name="util:md5">
        <xsl:param name="value"/>
        <xsl:sequence select="unparsed-text(concat($util-server,'/md5?value=',encode-for-uri($value)))"/>
    </xsl:function>    
    
</xsl:stylesheet>