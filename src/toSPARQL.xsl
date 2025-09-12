<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:csv="https://di.huc.knaw.nl/ns/csv"
    xmlns:cs="http://nineml.com/ns/coffeesacks"
    xmlns:sx="java:nl.mpi.tla.saxon"
    xmlns:gl="https://globalise.huygens.knaw.nl/"
    xmlns:functx="http://www.functx.com"
    xmlns:util="github.com/knaw-huc/util-server"
    exclude-result-prefixes="xs math csv cs sx gl functx util" version="3.0">

    <xsl:output method="xml" cdata-section-elements="query" encoding="UTF-8"/>
    
    <xsl:import href="csv2xml.xsl"/>
    
    <xsl:include href="utils.xsl"/>
    
    <xsl:variable name="NL" select="system-property('line.separator')"/>
    <xsl:variable name="TAB" select="'  '"/>

    <!--<xsl:param name="ns" select="'./Test_XML_Package/SPIFFY/atom/LAF_192.xml'"/>-->
    <xsl:param name="ns" select="'./data/GLBM_2.xml'"/>
    
    <xsl:param name="root">
        <!--<entity name="person" prefix="crm" suffix="E21_Person"/>-->
        <entity name="place" prefix="crm" suffix="E53_Place" input="location"/>
    </xsl:param>
    
    <xsl:param name="lookup-uri" select="'./lookup.xml'"/>
    <xsl:param name="lookup-doc" select="doc($lookup-uri)"/>
    
    <xsl:param name="out" select="'./'"/>
    
    <xsl:function name="gl:lookup">
        <xsl:param name="id"/>
        <xsl:sequence select="$lookup-doc//lookup[@id=$id]/@uri"/>
    </xsl:function>

    <xsl:function name="gl:lookup-value">
        <xsl:param name="field"/>
        <xsl:param name="value"/>
        <xsl:sequence select="$lookup-doc//lookup[@field=$field][@value=$value]/@uri"/>
    </xsl:function>
    
    <xsl:template name="main">
        
        <!-- load the data row CSV -->
        <xsl:variable name="row" select="csv:getCSV($csv)//r"/>
        
        <!-- step 4: load only the fields that are filled in this row -->
        <xsl:variable name="trees">
            <xsl:for-each select="(/sparql/field,/sparql/fields/field)">
                <xsl:variable name="f" select="@name"/>
                <xsl:choose>
                    <xsl:when test="normalize-space($row/c[@n=$f])!=''">
                        <xsl:message use-when="$dbg" expand-text="yes">?DBG: keep field[r{$f/../@row}][{$f}][{normalize-space($row/c[@n=$f])}]</xsl:message>
                        <xsl:sequence select="current()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message use-when="$dbg" expand-text="yes">?DBG: skip field[r{$f/../@row}][{$f}][{normalize-space($row/c[@n=$f])}]</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <!-- TODO: step 5 set the field values were needed -->
        
        
        <!-- step 6: create the big tree -->
        <xsl:variable name="tree">
            <tree>
                <xsl:for-each-group select="$trees//ontological_path/path/entity" group-by="concat(@prefix,':',@suffix,'@',var/@ident)">
                    <xsl:apply-templates select="current-group()[1]" mode="tree">
                        <xsl:with-param name="grp" select="current-group()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each-group>
            </tree>
        </xsl:variable>
        <!-- step 7: create the xquery -->
        <xsl:variable name="query">
            <query>
                <xsl:copy-of select="$NL"/>
                <xsl:for-each select="doc($ns)//ontology">
                    <xsl:if test="normalize-space(ontology_prefix) != '' and normalize-space(ontology_URI) != ''">
                        <xsl:text expand-text="yes">PREFIX {ontology_prefix}: &lt;{ontology_URI}>{$NL}</xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <!--<xsl:text expand-text="yes">PREFIX aaao: &lt;https://ontology.swissartresearch.net/aaao/>{$NL}</xsl:text>-->
                <xsl:text expand-text="yes">PREFIX geos: &lt;http://www.opengis.net/ont/geosparql#>{$NL}</xsl:text>
                <xsl:text expand-text="yes">CONSTRUCT {{{$NL}</xsl:text>
                <xsl:apply-templates select="$tree" mode="sparql">
                    <xsl:with-param name="indent" select="$TAB"/>
                </xsl:apply-templates>
                <!--<xsl:text expand-text="yes">{$TAB}?{$root/entity/@name} rdf:type {$root/entity/@prefix}:{$root/entity/@suffix};{$NL}</xsl:text>
                    <xsl:apply-templates select="$tree/entity/*" mode="sparql">
                        <xsl:with-param name="indent" select="$TAB"/>
                    </xsl:apply-templates>                    
                    <xsl:for-each select="$tree//var">
                        <xsl:text expand-text="yes">{$TAB}?var_{replace(@ident,'[^a-zA-Z0-9]','_')} rdf:type {parent::entity/@prefix}:{parent::entity/@suffix}.{$NL}</xsl:text>
                    </xsl:for-each>-->
                <xsl:text expand-text="yes">}}{$NL}</xsl:text>
                <xsl:text expand-text="yes">WHERE {{{$NL}</xsl:text>
                <xsl:text expand-text="yes">{$TAB}?{$root/entity/@name} rdf:type &lt;http://example.globalise.nl/temp/{$root/entity/@input}> .{$NL}</xsl:text>
                <xsl:for-each select="$tree//field">
                    <xsl:text expand-text="yes">{$TAB}OPTIONAL {{ ?{$root/entity/@name} &lt;http://example.globalise.nl/temp/{$root/entity/@input}/{replace(@name,'[^a-zA-Z0-9]','_')}> ?fld_{replace(concat(@name,'@',@group),'[^a-zA-Z0-9]','_')} . }}{$NL}</xsl:text>
                </xsl:for-each>
                <xsl:for-each-group select="$tree//var" group-by="concat(@ident,'@',@group)">
                    <xsl:choose>
                        <xsl:when test="current-group()//uri">
                            <xsl:text expand-text="yes">{$TAB}VALUES ?var_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} {{&lt;{(current-group()//uri)[1]}>}}{$NL}</xsl:text>
                        </xsl:when>
                        <xsl:when test="current-group()//lookup">
                            <xsl:text expand-text="yes">{$TAB}VALUES ?var_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} {{&lt;{gl:lookup((current-group()//lookup/@ident)[1])}>}}{$NL}</xsl:text>
                        </xsl:when>
                        <xsl:when test="current-group()//md5">
                            <xsl:text expand-text="yes">{$TAB}VALUES ?var_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} {{&lt;md5:{util:md5(normalize-space((current-group()//md5/@value,$row/c[@n=current-group()//md5/@ident])[1]))}>}}{$NL}</xsl:text>
                        </xsl:when>
                        <xsl:when test="current-group()//field">
                            <xsl:text expand-text="yes">{$TAB}OPTIONAL {{ ?{$root/entity/@name} &lt;http://example.globalise.nl/temp/{$root/entity/@input}/{replace((current-group()//field)[1]/@name,'[^a-zA-Z0-9]','_')}> ?var_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} . }}{$NL}</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text expand-text="yes">{$TAB}VALUES ?var_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} {{&lt;uuid:{util:uuid()}>}}{$NL}</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each-group>
                <xsl:for-each-group select="$tree//label" group-by="concat(@name,'@',@group)">
                    <xsl:text expand-text="yes">{$TAB}OPTIONAL {{ ?{$root/entity/@name} &lt;http://example.globalise.nl/temp/{$root/entity/@input}/{replace(current-group()[1]/@name,'[^a-zA-Z0-9]','_')}> ?lbl_{replace(current-grouping-key(),'[^a-zA-Z0-9]','_')} . }}{$NL}</xsl:text>
                </xsl:for-each-group>
                <xsl:text expand-text="yes">{$TAB}FILTER(?place = &lt;http://example.globalise.nl/temp/location/0021f4b9-4b37-44d5-9473-098ac370d44d>){$NL}</xsl:text>
                <xsl:text expand-text="yes">}}{$NL}</xsl:text>
            </query>            
        </xsl:variable>
        <sparql>
            <xsl:choose>
                <xsl:when test="count($trees/field) gt 1">
                    <fields>
                        <xsl:copy-of select="$trees"/>
                    </fields>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$trees"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="$tree"/>
            <xsl:copy-of select="$query"/>
        </sparql>
<!--        <xsl:result-document href="{concat($out,'/','query.sparql')}" method="text" encoding="utf-8">-->
        <xsl:result-document href="{$out}" method="text" encoding="utf-8">
            <xsl:copy-of select="$query/query"/>
            <xsl:text expand-text="yes">{$NL}</xsl:text>
        </xsl:result-document>        
    </xsl:template>
    
    <!-- mode[tree]: merge all the trees into one tree -->
    
    <xsl:template match="entity" mode="tree">
        <xsl:param name="grp" tunnel="yes"/>
        <entity srcs="{string-join(distinct-values($grp/@src),' ')}" prefix="{@prefix}" suffix="{@suffix}">
            <xsl:for-each-group select="$grp/var" group-by="concat(@ident,'@',@group)">
                <var srcs="{string-join(distinct-values($grp/@src),' ')}" group="{current-group()[1]/@group}" ident="{current-group()[1]/@ident}">
                    <xsl:copy-of select="current-group()/*"/>
                </var>
            </xsl:for-each-group>
            <xsl:for-each-group select="$grp/field" group-by="concat(@name,'@',@group)">
                <field srcs="{string-join(distinct-values($grp/@src),' ')}" group="{current-group()[1]/@group}" name="{current-group()[1]/@name}">
                    <xsl:copy-of select="current-group()/*"/>
                </field>
            </xsl:for-each-group>
            <xsl:for-each-group select="$grp/property" group-by="concat(@prefix, ':', @suffix)">
                <xsl:apply-templates select="current-group()[1]" mode="#current">
                    <xsl:with-param name="grp" select="current-group()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each-group>
        </entity>
    </xsl:template>
    
    <xsl:template match="property" mode="tree">
        <xsl:param name="grp" tunnel="yes"/>
        <!--<xsl:comment expand-text="yes">property[{string-join(@*,', ')}]</xsl:comment>-->
        <property srcs="{string-join(distinct-values($grp/@src),' ')}" prefix="{@prefix}" suffix="{@suffix}">
            <xsl:for-each-group select="$grp/entity"
                group-by="concat(@prefix, ':', @suffix, '@', (concat(var/@ident,'@',var/@group),generate-id())[1])">
                <xsl:apply-templates select="current-group()[1]" mode="tree">
                    <xsl:with-param name="grp" select="current-group()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each-group>
            <xsl:for-each-group select="$grp/literal" group-by="@type">
                <xsl:apply-templates select="current-group()[1]" mode="tree">
                    <xsl:with-param name="grp" select="current-group()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each-group>
        </property>
    </xsl:template>
    
    <xsl:template match="literal" mode="tree">
        <xsl:param name="grp" tunnel="yes"/>
        <literal srcs="{string-join(distinct-values($grp/@src),' ')}" type="{@type}">
            <xsl:for-each-group select="$grp/field" group-by="concat(@name,'@',@group)">
                <field group="{current-group()[1]/@group}" name="{current-group()[1]/@name}"/>
            </xsl:for-each-group>
        </literal>
    </xsl:template>
    
    <!-- mode[sparql]: turn tree into a SPARQL CONSTRUCT query -->
    
    <xsl:template match="entity" mode="sparql">
        <xsl:param name="indent" select="$TAB"/>
        <xsl:variable name="e" select="."/>
        <xsl:variable name="var" as="xs:string">
            <xsl:choose>
                <xsl:when test="exists(var)">
                    <xsl:sequence select="concat('var_',replace(concat(var/@ident,'@',var/@group),'[^a-zA-Z0-9]','_'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$root/entity/@name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="normalize-space(@srcs)!=''">
            <xsl:text expand-text="yes">{$indent}{$TAB}#srcs: {@srcs}{$NL}</xsl:text>            
        </xsl:if>
        <xsl:text expand-text="yes">{$indent}{$TAB}?{$var} rdf:type {$e/@prefix}:{$e/@suffix}.{$NL}</xsl:text>
        <xsl:if test="exists($e/var//label)">
            <xsl:text expand-text="yes">{$indent}{$TAB}?{$var} rdfs:label {concat('?lbl_',replace(concat(($e/var//label)[1]/@name,'@',($e/var//label)[1]/@group),'[^a-zA-Z0-9]','_'))}.{$NL}</xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="indent" select="concat($indent,$TAB)"/>
            <xsl:with-param name="sub" select="concat('?',$var)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:function name="functx:substring-before-last-match" as="xs:string?">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="regex" as="xs:string"/>
        
        <xsl:sequence select="
            replace($arg,concat('^(.*)',$regex,'.*'),'$1')
            "/>
        
    </xsl:function>
    
    <xsl:template match="text()" mode="sparql"/>
    
    <xsl:template match="property" mode="sparql">
        <xsl:param name="sub"/>
        <xsl:param name="indent" select="$TAB"/>
        <xsl:variable name="p" select="."/>
        <xsl:text expand-text="yes">{$indent}{$TAB}{$sub} {$p/@prefix}:{$p/@suffix}{$NL}</xsl:text>
        <xsl:variable name="vals" as="node()*">
            <xsl:apply-templates select="." mode="sparql-value"/>
        </xsl:variable>
        <xsl:for-each select="$vals/tokenize(.)">
            <xsl:text expand-text="yes">{$indent}{$TAB}{$TAB}{.}</xsl:text>                
            <xsl:text expand-text="yes">{if (position()=last()) then ('.') else (',')}{$NL}</xsl:text>
        </xsl:for-each>
        <!--<xsl:for-each select="$vals">
            <xsl:text expand-text="yes">{$indent}{$TAB}{.} rdf:type {@prefix}:{@suffix}.{$NL}</xsl:text>
        </xsl:for-each>-->
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="indent" select="functx:substring-before-last-match($indent,$TAB)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="entity" mode="sparql-value">
        <uri prefix="{@prefix}" suffix="{@suffix}">
            <xsl:choose>
                <xsl:when test="var">
                    <xsl:text expand-text="yes">?var_{replace(concat(var/@ident,'@',var/@group),'[^a-zA-Z0-9]','_')}</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text expand-text="yes">&lt;uuid:{util:uuid()}></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </uri>
    </xsl:template>
    
    <xsl:template match="literal" mode="sparql-value">
        <literal type="{@type}">
            <xsl:apply-templates mode="#current"/>
        </literal>
    </xsl:template>
    
    <xsl:template match="field" mode="sparql-value">
        <xsl:sequence select="concat('?fld_',replace(concat(@name,'@',@group),'[^a-zA-Z0-9]','_'))"/>
    </xsl:template>
    
</xsl:stylesheet>
