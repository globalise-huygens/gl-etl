<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:csv="https://di.huc.knaw.nl/ns/csv"
    xmlns:cs="http://nineml.com/ns/coffeesacks"
    xmlns:sx="java:nl.mpi.tla.saxon"
    xmlns:gl="https://globalise.huygens.knaw.nl/"
    xmlns:functx="http://www.functx.com"
    exclude-result-prefixes="xs math csv cs sx gl functx" version="3.0">

    <xsl:import href="csv2xml-semi.xsl"/>

    <xsl:param name="root">
        <!--<entity name="person" prefix="crm" suffix="E21_Person"/>-->
        <entity name="place" prefix="crm" suffix="E53_Place" input="location"/>
    </xsl:param>
    
    <xsl:variable name="spath" select="cs:load-grammar('./spath.ixml')"/>
    
    <xsl:param name="nr" select="0"/>

    <xsl:template name="main">
        <!-- step 1: turn CSV to XML -->
        <xsl:variable name="csv" select="csv:getCSV($csv)"/>
        <xsl:variable name="fields">
            <xsl:for-each select="$csv//r[if ($nr>1) then (@l=$nr) else (true())][normalize-space(c[@n='Primary_Ontological_Long_Path'])!='']">
                <xsl:variable name="r" select="."/>
                <field xml:id="{normalize-space($r/c[@n='ID'])}"
                    name="{normalize-space($r/c[@n='Field_Name'])}"
                    group="{if (normalize-space($r/c[@n='field_group'])!='') then (normalize-space($r/c[@n='field_group'])) else (generate-id($r))}"
                    class="crm:{normalize-space($r/c[@n='CRM Class'])}" row="{$r/@l}" xsl:expand-text="yes">
                    <data_sample>{normalize-space($r/c[@n='Data_Sample'])}</data_sample>
                    <!--<ontological_path>{normalize-space($r/c[@n='Whole_ontological_path'])}</ontological_path>-->
                    <path nr="1" field="{normalize-space($r/c[@n='Primary_Field'])}" value="{normalize-space($r/c[@n='Set_Value_Primary_Field'])}" type="{normalize-space($r/c[@n='Primary_Field_Type'])}">
                        <ontological_path>
                            <xsl:message expand-text="yes" use-when="$dbg">DBG:[{$r/@l}]spath[1][{normalize-space($r/c[@n='Primary_Ontological_Long_Path'])}]</xsl:message>
                            <xsl:variable name="p" select="$spath(normalize-space($r/c[@n='Primary_Ontological_Long_Path']))"/>
                            <xsl:apply-templates select="$p" mode="spath">
                                <xsl:with-param name="src" select="concat(normalize-space($r/c[@n='ID']),'.r',$r/@l,'.p1')" tunnel="yes"/>
                            </xsl:apply-templates>
                        </ontological_path>
                        <Expected_Value_Type>{normalize-space($r/c[@n='Primary_Expected_Value_Type (from Primary_Field)'])}</Expected_Value_Type>
                        <xsl:if test="normalize-space($r/c[@n='Primary_Expected_Value_Type (from Primary_Field)'])='Reference Model'">
                            <Expected_Resource_Model>{normalize-space($r/c[@n='Primary_Expected_Resource_Model'])}</Expected_Resource_Model>
                        </xsl:if>
                        <xsl:if test="normalize-space($r/c[@n='Primary_Expected_Value_Type (from Primary_Field)'])='Collection'">
                            <Expected_Collection_Model>{normalize-space($r/c[@n='Primary_Expected_Collection_Model'])}</Expected_Collection_Model>
                        </xsl:if>   
                    </path>
                    <xsl:if test="normalize-space($r/c[@n = 'Secondary_Field']) != ''">
                        <path nr="2" field="{normalize-space($r/c[@n='Secondary_Field'])}"
                            value="{normalize-space($r/c[@n='Set_Value_Secondary_Field'])}" type="{normalize-space($r/c[@n='Secondary_Field_Type'])}">
                            <ontological_path>
                                <xsl:message expand-text="yes" use-when="$dbg">DBG:[{$r/@l}]spath[2][{normalize-space($r/c[@n='Secondary_Ontological_Long_Path'])}]</xsl:message>
                                <xsl:variable name="p" select="$spath(normalize-space($r/c[@n='Secondary_Ontological_Long_Path']))"/>
                                <xsl:apply-templates select="$p" mode="spath">
                                    <xsl:with-param name="src" select="concat(normalize-space($r/c[@n='ID']),'.r',$r/@l,'.p2')" tunnel="yes"/>
                                </xsl:apply-templates>
                            </ontological_path>
                            <Expected_Value_Type>{normalize-space($r/c[@n='Secondary_Expected_Value_Type'])}</Expected_Value_Type>
                            <xsl:if test="normalize-space($r/c[@n='Secondary_Expected_Value_Type'])='Reference Model'">
                                <Expected_Resource_Model>{normalize-space($r/c[@n='Secondary_Expected_Resource_Model'])}</Expected_Resource_Model>
                            </xsl:if>
                            <xsl:if test="normalize-space($r/c[@n='Secondary_Expected_Value_Type'])='Collection'">
                                <Expected_Collection_Model>{normalize-space($r/c[@n='Secondary_Expected_Collection_Model'])}</Expected_Collection_Model>
                            </xsl:if>
                        </path>
                    </xsl:if>
                    <xsl:if test="normalize-space($r/c[@n = 'Tertiary_Field']) != ''">
                        <path nr="3" field="{normalize-space($r/c[@n='Tertiary_Field'])}"
                            value="{normalize-space($r/c[@n='Set_Value_Tertiary_Field'])}" type="{normalize-space($r/c[@n='Tertiary_Field_Type'])}">
                            <ontological_path>
                                <xsl:message expand-text="yes" use-when="$dbg">DBG:spath[3][{normalize-space($r/c[@n='Tertiary_Ontological_Long_Path'])}]</xsl:message>
                                <xsl:variable name="p" select="$spath(normalize-space($r/c[@n='Tertiary_Ontological_Long_Path']))"/>
                                <xsl:apply-templates select="$p" mode="spath">
                                    <xsl:with-param name="src" select="concat(normalize-space($r/c[@n='ID']),'.r',$r/@l,'.p3')" tunnel="yes"/>
                                </xsl:apply-templates>
                            </ontological_path>
                            <Expected_Value_Type>{normalize-space($r/c[@n='Tertiary_Expected_Value_Type'])}</Expected_Value_Type>
                            <xsl:if test="normalize-space($r/c[@n='Tertiary_Expected_Value_Type'])='Reference Model'">
                                <Expected_Resource_Model>{normalize-space($r/c[@n='Tertiary_Expected_Resource_Model'])}</Expected_Resource_Model>
                            </xsl:if>
                            <xsl:if test="normalize-space($r/c[@n='Tertiary_Expected_Value_Type'])='Collection'">
                                <Expected_Collection_Model>{normalize-space($r/c[@n='Tertiary_Expected_Collection_Model'])}</Expected_Collection_Model>
                            </xsl:if>
                        </path>
                    </xsl:if>
                    <xsl:if test="normalize-space($r/c[@n = 'Quaternary_Field']) != ''">
                        <path nr="4" field="{normalize-space($r/c[@n='Quaternary_Field'])}"
                            value="{normalize-space($r/c[@n='Set_Value_Quaternary_Field'])}" type="{normalize-space($r/c[@n='Quaternary_Field_Type'])}">
                            <ontological_path>
                                <xsl:message expand-text="yes" use-when="$dbg">DBG:[{$r/@l}]spath[4][{normalize-space($r/c[@n='Quaternary_Ontological_Long_Path'])}]</xsl:message>
                                <xsl:variable name="p" select="$spath(normalize-space($r/c[@n='Quaternary_Ontological_Long_Path']))"/>
                                <xsl:apply-templates select="$p" mode="spath">
                                    <xsl:with-param name="src" select="concat(normalize-space($r/c[@n='ID']),'.r',$r/@l,'.p4')" tunnel="yes"/>
                                </xsl:apply-templates>
                            </ontological_path>
                            <Expected_Value_Type>{normalize-space($r/c[@n='Quaternary_Expected_Value_Type'])}</Expected_Value_Type>
                            <xsl:if test="normalize-space($r/c[@n='Quaternary_Expected_Value_Type'])='Reference Model'">
                                <Expected_Resource_Model>{normalize-space($r/c[@n='Quaternary_Expected_Resource_Model'])}</Expected_Resource_Model>
                            </xsl:if>
                            <xsl:if test="normalize-space($r/c[@n='Quaternary_Expected_Value_Type'])='Collection'">
                                <Expected_Collection_Model>{normalize-space($r/c[@n='Quaternary_Expected_Collection_Model'])}</Expected_Collection_Model>
                            </xsl:if>
                        </path>
                    </xsl:if>
                </field>
            </xsl:for-each>
        </xsl:variable>
        <!-- step 2: merge the collection steps -->
        <xsl:variable name="collections">
            <xsl:apply-templates select="$fields" mode="collections"/>
        </xsl:variable>
        <!-- step 3: nest the trees -->
        <xsl:variable name="trees">
            <xsl:apply-templates select="$collections" mode="trees"/>
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
        </sparql>
    </xsl:template>
    
    <!-- mode[spath]: add provenance  -->
    
    <xsl:template match="node() | @*" mode="spath">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    

    <xsl:template match="entity|property|var" mode="spath">
        <xsl:param name="src" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="src" select="$src"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode[collections]: process collection paths -->
    
    <xsl:function name="gl:collection-path">
        <xsl:param name="path"/>
        <xsl:message use-when="$dbg" expand-text="yes">?DBG: path[nr={number($path/@nr)}]</xsl:message>
        <xsl:choose>
            <xsl:when test="number($path/@nr) gt 1">
                <xsl:variable name="col" select="max($path/preceding-sibling::path[Expected_Value_Type='Collection'][number(@nr) lt number($path/@nr)]/number(@nr))"/>
                <xsl:message use-when="$dbg" expand-text="yes">?DBG: col[{number($col)}]</xsl:message>
                <xsl:choose>
                    <xsl:when test="normalize-space(string($col))!=''">
                        <xsl:variable name="cpath" select="gl:collection-path($path/preceding-sibling::path[@nr = $col])"/> 
                        <ontological_path cols="{string-join(($cpath/@cols,$col),' ')}">
                            <path>
                                <xsl:comment expand-text="yes">?DBG: cpath[{string-join(($cpath/@cols,$col),' ')}]</xsl:comment>
                                <xsl:copy-of select="$cpath/descendant-or-self::path[exists(parent::ontological_path)]/node()"/>
                                <xsl:comment expand-text="yes">?DBG: path[{$path/@nr}]</xsl:comment>
                                <xsl:variable name="clp" select="$cpath//property[empty(following-sibling::property)]"/>
                                <xsl:variable name="cle" select="$clp/following-sibling::entity"/>
                                <xsl:variable name="pfp" select="($path//path/property)[1]"/>
                                <xsl:variable name="pfe" select="($pfp/following-sibling::entity)[1]"/>
                                <xsl:choose>
                                    <xsl:when test="$clp/concat(@prefix,':',@suffix) = $pfp/concat(@prefix,':',@suffix) and $cle/concat(@prefix,':',@suffix) = $pfe/concat(@prefix,':',@suffix)">
                                        <xsl:message use-when="$dbg" expand-text="yes">?DBG: skip[{$pfp/concat(@prefix,':',@suffix)}/{$pfe/concat(@prefix,':',@suffix)}]</xsl:message>
                                        <xsl:variable name="p" select="($path//path/property)[2]"/>
                                        <xsl:comment expand-text="yes">skipped[{string-join($p/preceding-sibling::*/concat(@prefix,':',@suffix,if (var) then concat('[',var/@ident,']') else ''),'/')}]</xsl:comment>
                                        <xsl:copy-of select="($p,$p/following-sibling::node())"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message use-when="$dbg" expand-text="yes">?DBG: keep path as it is</xsl:message>
                                        <xsl:copy-of select="$path/descendant-or-self::path[exists(parent::ontological_path)]/node()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </path>
                        </ontological_path>
                    </xsl:when>
                    <xsl:otherwise>
                        <ontological_path>
                            <xsl:sequence select="$path/descendant-or-self::path[exists(parent::ontological_path)]"/>
                        </ontological_path>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <ontological_path>
                    <xsl:sequence select="$path/descendant-or-self::path[exists(parent::ontological_path)]"/>
                </ontological_path>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="node() | @*" mode="collections">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
        
    <xsl:template match="path/ontological_path" mode="collections">
        <xsl:message use-when="$dbg" expand-text="yes">?DBG: opath[nr={number(parent::path/@nr)}]</xsl:message>
        <xsl:copy-of select="gl:collection-path(parent::path)"/>
    </xsl:template>
    
    <!-- mode[trees]: nest the paths -->
    
    <xsl:template match="node() | @*" mode="trees">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ontological_path/path" mode="trees">
        <xsl:variable name="id" select="ancestor::field/@xml:id"/>
        <xsl:variable name="row" select="ancestor::field/@row"/>
        <xsl:variable name="field" select="ancestor::field/@name"/>
        <xsl:variable name="group" select="ancestor::field/@group"/>
        <xsl:variable name="nr" select="ancestor::path/@nr"/>
        <xsl:variable name="type" select="ancestor::path/Expected_Value_Type"/>
        <xsl:variable name="value" select="ancestor::path/@value"/>  
        <xsl:message use-when="$dbg" expand-text="yes">?DBG: trees.path[nr={number(ancestor::path/@nr)}]</xsl:message>
        <xsl:copy>
            <xsl:attribute name="xml:id" select="concat($id,'.r',$row,'.p',$nr)"/>
            <xsl:attribute name="field" select="$field"/>
            <xsl:attribute name="type" select="$type"/>
            <entity>
                <xsl:apply-templates select="$root/entity/@*" mode="#current"/>                    
                <xsl:apply-templates select="(property)[1]" mode="#current">
                    <xsl:with-param name="id" select="$id" tunnel="yes"/>
                    <xsl:with-param name="row" select="$row" tunnel="yes"/>
                    <xsl:with-param name="nr" select="$nr" tunnel="yes"/>
                    <xsl:with-param name="field" select="$field" tunnel="yes"/>
                    <xsl:with-param name="group" select="$group" tunnel="yes"/>
                    <xsl:with-param name="type" select="$type" tunnel="yes"/>
                    <xsl:with-param name="value" select="$value" tunnel="yes"/>                            
                </xsl:apply-templates>
            </entity>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="entity[@prefix = 'rdf'][@suffix = 'literal']" mode="trees">
        <xsl:param name="field" tunnel="yes"/>
        <xsl:param name="group" tunnel="yes"/>
        <xsl:param name="type" tunnel="yes"/>
        <literal src="{@src}" type="{$type}">
            <field group="{$group}" name="{$field}"/>
        </literal>
    </xsl:template>
    
    <xsl:template match="entity" mode="trees">
        <xsl:param name="field" tunnel="yes"/>
        <xsl:param name="group" tunnel="yes"/>
        <xsl:param name="type" tunnel="yes"/>
        <xsl:param name="value" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="var" mode="#current"/>
            <xsl:choose>
                <xsl:when test="(following-sibling::*)[1]/self::property">
                    <xsl:apply-templates select="(following-sibling::*)[1]" mode="#current"/>
                </xsl:when>
                <xsl:when test="empty((following-sibling::*)[1]/self::property)"/>
            </xsl:choose>
            <xsl:apply-templates select="node() except var" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="var" mode="trees">
        <xsl:param name="field" tunnel="yes"/>
        <xsl:param name="group" tunnel="yes"/>
        <xsl:param name="type" tunnel="yes"/>
        <xsl:param name="value" tunnel="yes"/>
        <xsl:message expand-text="yes">?DBG: var[{$group}][{@ident}] end?[{empty((parent::entity/following-sibling::*)[1]/self::property)}] type[{$type}]</xsl:message>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="group" select="$group"/>
            <xsl:if test="empty((parent::entity/following-sibling::*)[1]/self::property)">
                <xsl:choose>
                    <xsl:when test="$type = 'Concept'">
                        <concept>
                            <xsl:choose>
                                <xsl:when test="matches(normalize-space($value),'[a-z]+:.*')">
                                    <uri xsl:expand-text="yes">{$value}</uri>
                                </xsl:when>
                                <xsl:when test="normalize-space($value)!=''">
                                    <lookup ident="{$value}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <field group="{$group}" name="{$field}"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </concept>
                    </xsl:when>
                    <xsl:when test="$type = 'Reference Model'">
                        <object>
                            <md5 group="{$group}" name="{$field}"/>
                            <label group="{$group}" name="{$field}"/>
                        </object>
                    </xsl:when>
                    <xsl:when test="$type = 'Collection'">
                        <!-- will continue in next path -->
                    </xsl:when>
                    <xsl:otherwise>
                        <field group="{$group}" name="{$field}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="property" mode="trees">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:choose>
                <xsl:when test="(following-sibling::*)[1]/self::entity">
                    <xsl:apply-templates select="(following-sibling::*)[1]" mode="#current"/>
                </xsl:when>
                <xsl:when test="(following-sibling::*)[1]/self::literal">
                    <xsl:apply-templates select="(following-sibling::*)[1]" mode="#current"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
        
</xsl:stylesheet>
