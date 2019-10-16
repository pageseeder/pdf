<?xml version="1.0" encoding="UTF-8"?>

  <!--
    This stylesheet defines the rules to turn PS standard XML into FO XML format.
    TODO: check bookmark rules at the bottom of this stylesheet.
    
    @author Jean-Baptiste Reure
    @author Philip Rutherford
    @author Willy Ekasalim
    
    @version 3 May 2012
    
    Copyright (C) 2012 Weborganic Systems Pty. Ltd.
  -->
  
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ps="http://www.pageseeder.com/editing/2.0"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:psf="http://www.pageseeder.com/function"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="ps psf xs">

<!-- ================================ Table ============================================= -->

<!-- Template for PageSeeder Table element

.. admonition:: xpath:table

   | <fo:block>
   |   <fo:table table-layout="fixed" border-collapse="collapse" inline-progression-dimension.optimum="100%">
   |     <fo:table-column column-width=""/>
   |     <fo:table-body>
   |       ...
   |     </fo:table-body>
   |   </fo:table>
   | </fo:block>

-->
  <xsl:template match="table">
    <fo:block>
      <xsl:variable name="config"      select="psf:load-config(.)" />
      <xsl:variable name="role-props"  select="psf:load-style-properties-more($config, 'table', 'property', string(@role))" />
      <xsl:variable name="table-props" select="psf:load-style-properties-more($config, 'table', 'property', '')" />
      <xsl:sequence select="psf:style-properties-overwrite($role-props, $table-props)"/>
      <!--  currently, fop 0.95 does not support caption -->
      <!-- 
      <fo:table-and-caption>
      <xsl:if test="caption">
	      <fo:table-caption>
	        <fo:block>
	            <xsl:value-of select="caption"/>
	        </fo:block>
	      </fo:table-caption>
      </xsl:if-->
      <fo:table border-collapse="collapse" table-layout="fixed" inline-progression-dimension.optimum="100%">
    		<xsl:copy-of select="@width"/>
    		<xsl:copy-of select="@height"/>
        <xsl:for-each select="row">
          <xsl:if test="position()=1">
            <xsl:variable name="columns" select="../col"/>
            <xsl:choose>
              <xsl:when test="$columns">
                <xsl:for-each select="$columns">
                  <fo:table-column>
                    <xsl:variable name="crole-props"  select="psf:load-style-properties-more($config, 'table-col', 'property', string(@role))" />
                    <xsl:variable name="col-props"    select="psf:load-style-properties-more($config, 'table-col', 'property', '')" />
                    <xsl:sequence select="psf:style-properties-overwrite($crole-props, $col-props)"/>
                    <xsl:choose>
                      <!-- % or px, if nothing then default to px -->
                      <xsl:when test="ends-with(@width, '%')"><xsl:attribute name="column-width" select="concat('proportional-column-width(',replace(@width, '\D', ''),')')" /></xsl:when>
                      <xsl:when test="ends-with(@width, 'px')"><xsl:attribute name="column-width" select="@width" /></xsl:when>
                      <xsl:when test="@width"><xsl:attribute name="column-width" select="concat(replace(@width, '\D', ''), 'px')"/></xsl:when>
                      <xsl:otherwise><xsl:attribute name="column-width">proportional-column-width(1)</xsl:attribute></xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@span">
                      <xsl:attribute name="number-columns-repeated" select="@span"/>
                    </xsl:if>
                    <xsl:if test="@align">
                      <xsl:attribute name="text-align" select="@align"/>
                    </xsl:if>
                  </fo:table-column>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
		            <xsl:for-each select="cell | hcell">
		              <xsl:variable name="element-name" select="concat('table-', local-name())"/>
		              <xsl:variable name="width-style-property" select="psf:load-style-properties-more(psf:load-config(.), $element-name, 'property', string(@role))[@name='width']" />
		              <xsl:variable name="width">
		                <xsl:choose>
		                  <xsl:when test="@width"><xsl:value-of select="@width" /></xsl:when>
		                  <xsl:when test="$width-style-property"><xsl:value-of select="$width-style-property/@value" /></xsl:when>
		                  <xsl:otherwise>1%</xsl:otherwise>
		                </xsl:choose>
		              </xsl:variable>
                  <xsl:variable name="colspan" select="if (@colspan) then @colspan else 1" />
                  <xsl:for-each select="1 to $colspan">
  		              <fo:table-column>
                      <xsl:choose>
                        <!-- % or px, if nothing then default to px -->
                        <xsl:when test="ends-with($width, '%')"><xsl:attribute name="column-width" select="concat('proportional-column-width(',replace($width, '\D', ''),')')" /></xsl:when>
                        <xsl:when test="ends-with($width, 'px')"><xsl:attribute name="column-width" select="$width" /></xsl:when>
                        <xsl:otherwise><xsl:attribute name="column-width" select="concat(replace($width, '\D', ''), 'px')"/></xsl:otherwise>
                      </xsl:choose>
                    </fo:table-column>
                  </xsl:for-each>
		            </xsl:for-each>
		          </xsl:otherwise>
		        </xsl:choose>
          </xsl:if>
        </xsl:for-each>
        <fo:table-body>
          <xsl:apply-templates />
        </fo:table-body>
      </fo:table>
      <!-- </fo:table-and-caption> -->
    </fo:block>
  </xsl:template>

  <xsl:template match="caption" />
   
<!-- Template for PageSeeder Row element

.. admonition:: xpath:row

   | <fo:table-row>
   |   <fo:table-cell space-before.optimum="5pt" space-after.optimum="5pt">
   |     <fo:block text-align="left" margin-left="0.08cm" space-before="0.08cm" margin-right="0.08cm">
   |       ...
   |     </fo:block>
   |   </fo:table-cell>
   | </fo:table-row>

-->  
  <xsl:template match="row">
    <fo:table-row>
      <xsl:variable name="part" select="@part"/>
      <xsl:variable name="config"      select="psf:load-config(.)" />
      <xsl:variable name="role-props"  select="psf:load-style-properties-more($config, 'table-row', 'property', string(@role))" />
      <xsl:variable name="def-props"   select="psf:load-style-properties-more($config, 'table-row', 'property', '')" />
      <xsl:sequence select="psf:style-properties-overwrite($role-props, $def-props)"/>
      <xsl:for-each select="cell | hcell">
        <xsl:variable name="name" select="if ($part = 'header') then 'hcell' else name()"/>
        <!-- adding in for colspan support -->
        <fo:table-cell space-before.optimum="5pt" space-after.optimum="5pt">
          <xsl:variable name="role-props"  select="psf:load-style-properties-more($config, concat('table-',$name), 'property', string(@role))" />
          <xsl:variable name="def-props"   select="psf:load-style-properties-more($config, concat('table-',$name), 'property', '')" />
          <xsl:sequence select="psf:style-properties-overwrite($role-props, $def-props)"/>
          <xsl:if test="@colspan">
            <xsl:attribute name="number-columns-spanned"><xsl:value-of select="@colspan"/></xsl:attribute>
          </xsl:if>
			    <xsl:if test="@valign">
            <xsl:attribute name="display-align">
              <xsl:choose>
                <xsl:when test="@valign='top'">before</xsl:when>
                <xsl:when test="@valign='middle'">center</xsl:when>
                <xsl:when test="@valign='bottom' or @valign='baseline'">after</xsl:when>
              </xsl:choose>
    				</xsl:attribute>
    			</xsl:if>
  			  <!-- adding in for rowspan support -->
          <xsl:if test="@rowspan">
            <xsl:attribute name="number-rows-spanned">
              <xsl:value-of select="@rowspan"/>
            </xsl:attribute>
          </xsl:if>
          <!-- add border support -->
          <xsl:if test="ancestor::table[@border]">
            <xsl:attribute name="border-style">solid</xsl:attribute>
            <xsl:attribute name="border-color">black</xsl:attribute>
            <xsl:attribute name="border-width"><xsl:value-of select="(ancestor::table/@border)[1]"/>px</xsl:attribute>
          </xsl:if>
          <fo:block margin-left="0.08cm" space-before="0.08cm" margin-right="0.08cm">
            <xsl:attribute name="font-weight">bold</xsl:attribute>
            <xsl:variable name="role-props"  select="psf:load-style-properties-more($config, concat($name, '-role-', @role), 'property', '')" />
            <xsl:variable name="def-props"   select="psf:load-style-properties-more($config, $name, 'property', '')" />
            <xsl:sequence select="psf:style-properties-overwrite($role-props, $def-props)"/>
            <xsl:variable name="align" select="if (@align) then @align else ../../col[count(preceding-sibling::*)+1 = count(current()/preceding-sibling::*)+1]/@align" />
            <xsl:if test="$align">
              <xsl:attribute name="text-align">
                <xsl:choose>
                  <xsl:when test="$align='center'">center</xsl:when>
                  <xsl:when test="$align='right'">end</xsl:when>
                  <xsl:when test="$align='justify'">justify</xsl:when>
                  <xsl:otherwise>start</xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
          </fo:block>
        </fo:table-cell>
      </xsl:for-each>
    </fo:table-row>
  </xsl:template>
  
<!-- ============================== fragment ================================== -->
<!-- Template for PageSeeder fragment

.. admonition:: xpath:fragment

   | <fo:block id="1" break-before="page">
   |   ...
   | </fo:block>

-->
  <xsl:template match="*[psf:is-fragment(.)][not(self::properties-fragment)]">
    <!-- if this is the first fragment of this document, add the anchor -->
    <xsl:variable name="dad-doc" select="self::*[empty(preceding-sibling::*[psf:is-fragment(.)])]/parent::section[empty(preceding-sibling::section)]/parent::document" />
    <xsl:if test="$dad-doc and empty($dad-doc/preceding::document[@id = $dad-doc/@id] | $dad-doc/ancestor::document[@id = $dad-doc/@id])">
      <fo:block id="psf-{$dad-doc/@id}" />
    </xsl:if>
    <!-- check for section title -->
    <xsl:apply-templates select="preceding-sibling::*[1][self::title]" />
    <fo:block id="psf-{@id}">
      <xsl:variable name="cust-props" select="if (@type) then psf:load-style-properties(., concat(name(), '-', @type)) else ()" />
      <xsl:variable name="def-props"  select="psf:load-style-properties(., name())" />
      <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  
<!-- ============================== properties-fragment ================================== -->
<!-- Template for PageSeeder properties fragment

.. admonition:: xpath:properties-fragment

   | <fo:table>
   |   ...
   | </fo:table>

-->
  <xsl:template match="properties-fragment[property]">
    <!-- if this is the first fragment of this document, add the anchor -->
    <xsl:variable name="dad-doc" select="self::*[empty(preceding-sibling::*[psf:is-fragment(.)])]/parent::section[empty(preceding-sibling::section)]/parent::document" />
    <xsl:if test="$dad-doc and empty($dad-doc/preceding::document[@id = $dad-doc/@id] | $dad-doc/ancestor::document[@id = $dad-doc/@id])">
      <fo:block id="psf-{$dad-doc/@id}" />
    </xsl:if>
    <!-- check for section title -->
    <xsl:apply-templates select="preceding-sibling::*[1][self::title]" />
    <fo:block id="psf-{@id}">
      <xsl:sequence select="psf:style-properties(., 'properties')"/>
      <fo:table border-collapse="collapse" table-layout="fixed" inline-progression-dimension.optimum="100%">
        <fo:table-column column-width="proportional-column-width(1)" />
        <fo:table-column column-width="proportional-column-width(1)" />
        <fo:table-body>
          <xsl:apply-templates />
        </fo:table-body>
      </fo:table>
    </fo:block>
  </xsl:template>
  
<!-- ============================== property ================================== -->
<!-- Template for PageSeeder property

.. admonition:: xpath:property

   | <fo:table-row>
   |   <fo:table-cell>...</fo:table-cell>
   |   <fo:table-cell>...</fo:table-cell>
   | </fo:table-row>

-->
  <xsl:template match="property">
    <fo:table-row>
      <xsl:sequence select="psf:style-properties(., 'property')" />
      <!-- property title -->
      <fo:table-cell space-before.optimum="5pt" space-after.optimum="5pt">
        <xsl:sequence select="psf:style-properties(., 'property-title-cell')" />
        <fo:block>
          <xsl:sequence select="psf:style-properties(., 'property-title')" />
          <xsl:value-of select="if (@title) then @title else @name" />
        </fo:block>
      </fo:table-cell>
      <!-- property value -->
      <fo:table-cell space-before.optimum="5pt" space-after.optimum="5pt">
        <xsl:sequence select="psf:style-properties(., 'property-value-cell')" />
        <fo:block>
          <xsl:sequence select="psf:style-properties(., 'property-value')" />
          <xsl:choose>
            <xsl:when test="@value"><xsl:value-of select="@value" /></xsl:when>
            <xsl:when test="*">
              <xsl:for-each select="*"><fo:block><xsl:apply-templates select="." /></fo:block></xsl:for-each>
            </xsl:when>
          </xsl:choose>
        </fo:block>
      </fo:table-cell>
    </fo:table-row>
  </xsl:template>

<!-- Template for PageSeeder Section (Table of Content)

.. admonition:: xpath:toc

   | <fo:block id="TOC">
   |   <fo:block>Contents</fo:block>
   |   <fo:block>
   |     <fo:block text-align-last="justify">
   |       <fo:basic-link internal-destination="doc">...</fo:basic-link>
   |       <fo:leader leader-pattern="dots"/>
   |       <fo:page-number-citation ref-id="TOC" />
   |     </fo:block>
   |   </fo:block>
   | </fo:block>

-->  
  <xsl:template match="toc">
    <xsl:variable name="toc" select="." />
    <!-- only first TOC is displayed -->
    <xsl:if test="not(preceding::toc) and toc-tree">
      <fo:block id="toc-{parent::document/@id}">
        <xsl:sequence select="psf:style-properties(., 'toc')"/>
        <fo:block>
          <xsl:for-each select=".//toc-part[@idref]">
            <xsl:variable name="level" select="number(@level)"/>
            <xsl:variable name="hide" select="psf:load-style-properties($toc, concat('toc-level', @level))[@name = 'ps-hide']/@value"/>
            <xsl:if test="not($hide = 'true') and $level gt 0">
              <fo:block>
                <xsl:sequence select="psf:style-properties($toc, concat('toc-level', @level))"/>
                <fo:basic-link>
                  <xsl:attribute name="internal-destination"><xsl:value-of select="@idref"/></xsl:attribute>
                  <xsl:value-of select="concat(@prefix,' ',@title)" />
                </fo:basic-link>
                <!-- Add a minimum leader length to make sure it start a new line when appropriate -->
                <fo:leader leader-length.minimum="0.5cm" leader-pattern="dots"/>
                <fo:page-number-citation keep-with-previous="always" ref-id="{@idref}" />
              </fo:block>
            </xsl:if>
          </xsl:for-each>
        </fo:block>
      </fo:block>
    </xsl:if>
  </xsl:template>

  <xsl:template name="level">
    <xsl:param name="title" />
    <xsl:param name="level" select="1" />
    <xsl:choose><xsl:when test="contains($title, '.')">
      <xsl:call-template name="level">
        <xsl:with-param name="level" select="$level+1" />
        <xsl:with-param name="title" select="substring-after($title, '.')" />
      </xsl:call-template>
    </xsl:when><xsl:otherwise>
      <xsl:value-of select="$level" />
    </xsl:otherwise></xsl:choose>
  </xsl:template>
  
  <xsl:template name="indent">
    <xsl:param name="title" />
    <xsl:if test="contains($title, '.')">
	  <xsl:text>&#160;&#160;&#160;&#160;</xsl:text>
      <xsl:call-template name="indent">
        <xsl:with-param name="title" select="substring-after($title, '.')" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ============================== anchor ================================== -->
  <xsl:template match="anchor[@name]">
    <!-- only if first one (to avoid duplicates) -->
    <xsl:if test="empty(preceding::anchor[@name = current()/@name])">
      <fo:block id="psa-{@name}" />
    </xsl:if>
  </xsl:template>

  <!-- ============================== Heading ================================= -->
  <!-- Template for PageSeeder Heading

  .. admonition:: xpath:heading

     | <fo:block id="1">
     |   1. ...
     | </fo:block>

  -->
  <!-- with prefix -->
  <xsl:template match="heading[string(@prefix) != '']">
    <xsl:variable name="prefix-properties"  select="psf:load-style-properties(., concat('heading-prefix-', @level))[string(@value) != '']" />
    <xsl:variable name="heading-properties" select="psf:load-style-properties(., concat('heading-',        @level))[string(@value) != '']" />
    <xsl:variable name="start-indent" select="$prefix-properties[@name = 'start-indent']/@value" />
    <xsl:variable name="text-indent"  select="$prefix-properties[@name = 'text-indent']/@value" />
    <xsl:choose>
      <xsl:when test="$start-indent and $text-indent">
        <fo:table border-style="none" table-layout="fixed" width="100%" start-indent="{$start-indent}">
          <fo:table-column column-width="{$text-indent}"/>
          <fo:table-column column-width="proportional-column-width(1)" />
          <fo:table-body start-indent="0">
            <fo:table-row>
              <fo:table-cell text-align="right" padding-right="5px">
                <fo:block>
                  <!-- add heading prefix style properties -->
                  <xsl:for-each select="$prefix-properties[@name != 'start-indent' and @name != 'text-indent']">
                    <xsl:attribute name="{@name}" select="@value" />
                  </xsl:for-each>
                  <!-- inherit format properties from heading -->
                  <xsl:for-each select="$heading-properties[@name != 'start-indent' and @name != 'text-indent']">
                    <xsl:if test="empty($prefix-properties[@name = current()/@name])">
                      <xsl:attribute name="{@name}" select="@value" />
                    </xsl:if>
                  </xsl:for-each>
                  <xsl:value-of select="@prefix" />
                </fo:block>
              </fo:table-cell>
              <fo:table-cell>
                <fo:block>
                  <xsl:if test="@id"><xsl:attribute name="id" select="@id" /></xsl:if>
                  <xsl:for-each select="$heading-properties"><xsl:attribute name="{@name}" select="@value" /></xsl:for-each>
                  <xsl:apply-templates/>
                </fo:block>
              </fo:table-cell>
            </fo:table-row>
          </fo:table-body>
        </fo:table>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="heading-noprefix" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- without prefix -->
  <xsl:template match="heading[string(@prefix) = '']" name="heading-noprefix">
    <fo:block>
      <xsl:if test="@id"><xsl:attribute name="id" select="@id" /></xsl:if>
      <xsl:sequence select="psf:style-properties(., concat('heading-', @level))"/>
      <!-- if no start-indent/text-indent defined -->
      <xsl:if test="@prefix">
        <xsl:value-of select="@prefix"/>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

<!-- ============================== Para ================================== -->

<!-- Template for PageSeeder Para

.. admonition:: xpath:para

   | <fo:block>
   |  ...
   | </fo:block>

-->
  <!-- with prefix -->
  <xsl:template match="para[string(@prefix) != '' and string(@indent) != '']">
    <xsl:variable name="prefix-properties"  select="psf:load-style-properties(., concat('para-prefix-', @indent))[string(@value) != '']" />
    <xsl:variable name="indent-properties"  select="psf:load-style-properties(., concat('para-',        @indent))[string(@value) != '']" />
    <xsl:variable name="para-properties"    select="psf:load-style-properties(., 'para'                         )[string(@value) != '']" />
    <xsl:variable name="start-indent" select="$prefix-properties[@name = 'start-indent']/@value" />
    <xsl:variable name="text-indent"  select="$prefix-properties[@name = 'text-indent']/@value" />
    <xsl:variable name="ps-indent-px" select="$para-properties[@name = 'ps-indent-px']/@value" />
    <fo:table border-style="none" table-layout="fixed" width="100%">
      <xsl:if test="$start-indent"><xsl:attribute name="start-indent" select="$start-indent" /></xsl:if>
      <fo:table-column column-width="{if ($text-indent) then $text-indent else concat(number(@indent) * number($ps-indent-px), 'px')}"/>
      <fo:table-column column-width="proportional-column-width(1)" />
      <fo:table-body start-indent="0">
        <fo:table-row>
          <fo:table-cell text-align="right" padding-right="5px">
            <fo:block>
              <!-- add para prefix style properties -->
              <xsl:for-each select="$prefix-properties[@name != 'start-indent' and @name != 'text-indent']">
                <xsl:attribute name="{@name}" select="@value" />
              </xsl:for-each>
              <!-- inherit properties from para indented -->
              <xsl:for-each select="$indent-properties[@name != 'start-indent' and @name != 'text-indent' and @name != 'ps-indent-px']">
                <xsl:if test="empty($prefix-properties[@name = current()/@name])">
                  <xsl:attribute name="{@name}" select="@value" />
                </xsl:if>
              </xsl:for-each>
              <!-- inherit properties from para -->
              <xsl:for-each select="$para-properties[@name != 'start-indent' and @name != 'text-indent' and @name != 'ps-indent-px']">
                <xsl:if test="empty($prefix-properties[@name = current()/@name] | $indent-properties[@name = current()/@name])">
                  <xsl:attribute name="{@name}" select="@value" />
                </xsl:if>
              </xsl:for-each>
              <xsl:value-of select="@prefix" />
            </fo:block>
          </fo:table-cell>
          <fo:table-cell>
            <fo:block>
              <xsl:for-each select="$indent-properties[@name != 'start-indent' and @name != 'text-indent' and @name != 'ps-indent-px']">
                <xsl:attribute name="{@name}" select="@value" />
              </xsl:for-each>
              <xsl:for-each select="$para-properties[@name != 'start-indent' and @name != 'text-indent' and @name != 'ps-indent-px']">
                <xsl:if test="empty($indent-properties[@name = current()/@name])">
                  <xsl:attribute name="{@name}" select="@value" />
                </xsl:if>
              </xsl:for-each>
              <xsl:apply-templates select="* | text()" />
            </fo:block>
          </fo:table-cell>
        </fo:table-row>
      </fo:table-body>
    </fo:table>
  </xsl:template>

  <!-- without prefix -->
  <xsl:template match="para[string(@prefix) = '']" name="para-noprefix">
    <xsl:variable name="indent-properties"  select="psf:load-style-properties(., concat('para-', @indent))[string(@value) != '']" />
    <xsl:variable name="para-properties"    select="psf:load-style-properties(., 'para')[string(@value) != '']" />
    <xsl:variable name="is-indented" select="string(@indent) != ''" />
    <fo:block>
      <xsl:if test="$is-indented">
        <!-- start indent, fallback on legacy ps-indent-px property -->
        <xsl:variable name="indent">
          <xsl:choose>
            <xsl:when test="$indent-properties[@name = 'start-indent']"><xsl:value-of select="$indent-properties[@name = 'start-indent']/@value" /></xsl:when>
            <xsl:when test="$para-properties[@name = 'start-indent']"><xsl:value-of select="$para-properties[@name = 'start-indent']/@value" /></xsl:when>
            <xsl:when test="$para-properties[@name = 'ps-indent-px']"><xsl:value-of select="number(@indent) * number($para-properties[@name = 'ps-indent-px']/@value)" />px</xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$indent"><xsl:attribute name="start-indent" select="$indent" /></xsl:if>
        <!-- all other properties for this level -->
        <xsl:for-each select="$indent-properties[@name != 'start-indent']">
          <xsl:attribute name="{@name}"><xsl:value-of select="@value" /></xsl:attribute>
        </xsl:for-each>
      </xsl:if>
      <!-- all para properties, ignore the ones already set for this level -->
      <xsl:for-each select="$para-properties[@name != 'ps-indent-px' and (not($is-indented) or @name != 'start-indent')]">
        <xsl:if test="not($is-indented) or empty($indent-properties[@name = current()/@name])">
          <xsl:attribute name="{@name}"><xsl:value-of select="@value" /></xsl:attribute>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates select="* | text()" />
    </fo:block>
  </xsl:template>

<!-- ============================== ParaLabel ================================== -->

<!-- Template for PageSeeder block

.. admonition:: xpath:block

   | <fo:block>
   |   <fo:block>
   |   ... the block name
   |   </fo:block>
   |  ...
   | </fo:block>

-->
  <xsl:template match="block">
    <xsl:variable name="name" select="concat('-', @label)"/>
    <fo:block>
      <xsl:variable name="cust-props" select="psf:load-style-properties(., concat('block', $name))" />
      <xsl:variable name="def-props"  select="psf:load-style-properties(., 'block')" />
      <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
      <!-- check if we should show the name of the label -->
      <xsl:variable name="show" select="not(psf:load-style-properties(., 'blockName')[@name = 'ps-hide']/@value = 'true') and
                                        not(psf:load-style-properties(., concat('blockName', $name))[@name = 'ps-hide']/@value = 'true')"/>
      <xsl:if test="$show">
        <fo:block>
          <xsl:variable name="cust-props" select="psf:load-style-properties(., concat('blockName', $name))" />
          <xsl:variable name="def-props"  select="psf:load-style-properties(., 'blockName')" />
          <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
          <xsl:value-of select="@label"/>
        </fo:block>
      </xsl:if>
      <xsl:apply-templates select="* | text()" />
    </fo:block>
  </xsl:template>

<!-- Template for PageSeeder Inline

.. admonition:: xpath:inline

   | <fo:inline>
   |   <fo:inline>
   |   ... the inline label name
   |   </fo:inline>
   |  ...
   | </fo:inline>

-->
  <xsl:template match="inline">
    <xsl:variable name="name" select="concat('-', @label)"/>
    <xsl:variable name="show" select="not(psf:load-style-properties(., 'inline')[@name = 'ps-hide']/@value = 'true') and 
                        not(psf:load-style-properties(., concat('inline',$name))[@name = 'ps-hide']/@value = 'true')"/>
    <xsl:if test="$show">
      <fo:inline>
        <xsl:variable name="cust-props" select="psf:load-style-properties(., concat('inline', $name))" />
        <xsl:variable name="def-props"  select="psf:load-style-properties(., 'inline')" />
        <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
        <xsl:variable name="showName" select="not(psf:load-style-properties(., 'inlineName')[@name = 'ps-hide']/@value = 'true') and 
                                not(psf:load-style-properties(., concat('inlineName',$name))[@name = 'ps-hide']/@value = 'true')"/>
        <xsl:if test="$showName">
  	      <fo:inline>
            <xsl:variable name="cust-props" select="psf:load-style-properties(., concat('inlineName', $name))" />
            <xsl:variable name="def-props"  select="psf:load-style-properties(., 'inlineName')" />
            <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
  	        <xsl:value-of select="@label"/>
  	      </fo:inline>
        </xsl:if>
        <xsl:apply-templates select="* | text()" />
      </fo:inline>
    </xsl:if>
  </xsl:template>

<!-- ============================== preformat ================================== -->  
<!-- Template for PageSeeder preformat 

.. admonition:: xpath:preformat

   | <fo:block>
   |   ...
   | </fo:block>

-->
  <xsl:template match="preformat">
  	<fo:block>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
  	  <xsl:apply-templates select="* | text()" />
  	</fo:block>
  </xsl:template>

<!-- ============================== Code ================================== -->  
<!-- Template for PageSeeder monospace 

.. admonition:: xpath:monospace

   | <fo:inline>
   |   ...
   | </fo:inline>

-->
  <xsl:template match="monospace">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>
  
<!-- ============================== Subscript ================================== -->

<!-- Template for PageSeeder subscript (sub)

.. admonition:: xpath:sub

   | <fo:inline>
   |   ...
   | </fo:inline>

-->  
  <xsl:template match="sub">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>

<!-- ============================== Superscript ================================== -->
<!-- Template for PageSeeder superscript (sup)

.. admonition:: xpath:sup

   | <fo:inline>
   |   ...
   | </fo:inline>

-->  
  <xsl:template match="sup">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>


<!-- ============================== Link ================================== -->
<!-- Template for PageSeeder link

.. admonition:: xpath:link[@href]

   | <fo:inline>
   |   <fo:base-link internal-destination=""> ... </fo:base-link>
   | </fo:inline>

-->  
  <xsl:template match="link[@href]">
    <fo:inline>
      <fo:basic-link>
        <xsl:sequence select="psf:style-properties(., local-name(.))"/>
        <xsl:choose>
          <xsl:when test="starts-with(@href,'#')">
            <xsl:attribute name="internal-destination">
              <xsl:value-of select="if (string-length(@href) = 1) then 'first-page' else concat('psa-', substring-after(@href,'#'))"/>
            </xsl:attribute>      
          </xsl:when>
          <xsl:when test="@href=''">
            <xsl:attribute name="internal-destination">first-page</xsl:attribute>      
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="external-destination" select="@href"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates/>
      </fo:basic-link>
    </fo:inline>
  </xsl:template>

<!-- ============================== List | nlist ================================== -->
<!-- Template for PageSeeder list or nlist

.. admonition:: xpath:list|nlist

   | <fo:list-block>
   |   ...
   | </fo:list-block>

-->
  <xsl:template match="list | nlist">
	  <fo:list-block>
      <xsl:variable name="cust-props" select="if (@type) then psf:load-style-properties(., concat(local-name(), @type)) else ()" />
      <xsl:variable name="def-props"  select="psf:load-style-properties(., local-name())" />
      <xsl:sequence select="psf:style-properties-overwrite($cust-props, $def-props)"/>
		  <xsl:apply-templates/>
	  </fo:list-block>
  </xsl:template>



<!-- Template for PageSeeder list or nlist.

.. admonition:: xpath:item

   | <fo:list-item>
   |   <fo:list-item-label>
   |     <fo:block> ... </fo:block>
   |     </fo:list-item-label>
   |     <fo:list-item-body>
   |     <fo:block> ... </fo:block>
   |   </fo:list-item-body>
   | </fo:list-item>

-->
  <xsl:template match="item">
    <fo:list-item>
      <xsl:sequence select="psf:style-properties(., 'list-item')"/>
      <xsl:variable name="color-style-property" select="psf:load-style-properties(., 'list-item')[@name='color']" />
      <xsl:variable name="color" select="if ($color-style-property) then $color-style-property/@value else '#1f4f76'" />
  		<fo:list-item-label>
  		  <fo:block>
  		  	<xsl:variable name="level" select="count(ancestor::nlist | ancestor::list)"/>
          <xsl:variable name="pos" select="count(preceding-sibling::item) + 1"/>
          <xsl:variable name="label" select="if (parent::nlist/@start) then $pos + xs:integer(parent::nlist/@start) - 1 else $pos"/>
  		  	<xsl:choose>
            <xsl:when test="parent::list">
              <xsl:choose>
                <xsl:when test="../@type='none'" />
                <xsl:when test="../@type='disc'"><fo:inline font-family="Symbol" color="{$color}">&#x2022;</fo:inline></xsl:when>
                <xsl:when test="../@type='circle'"><fo:inline font-size="7pt" font-family="ZapfDingbats" color="{$color}">&#x274D;</fo:inline></xsl:when>
                <xsl:when test="../@type='square'">
                  <xsl:attribute name="margin-top">-1pt</xsl:attribute>
                  <fo:inline font-size="6pt" font-family="ZapfDingbats" color="{$color}" >&#x25A0;</fo:inline>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="margin-top">-3pt</xsl:attribute>
                  <fo:inline font-family="Symbol" color="{$color}">&#x2022;</fo:inline>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="parent::nlist/@type = 'arabic'"><xsl:number value="$label" format="1."/></xsl:when>
            <xsl:when test="parent::nlist/@type = 'upperalpha'"><xsl:number value="$label" format="A."/></xsl:when>
            <xsl:when test="parent::nlist/@type = 'loweralpha'"><xsl:number value="$label" format="a."/></xsl:when>
            <xsl:when test="parent::nlist/@type = 'upperroman'"><xsl:number value="$label" format="I."/></xsl:when>
            <xsl:when test="parent::nlist/@type = 'lowerroman'"><xsl:number value="$label" format="i."/></xsl:when>
  				  <xsl:when test="$level=2"><xsl:number value="$label" format="a."/></xsl:when>
  				  <xsl:when test="$level=3"><xsl:number value="$label" format="i."/></xsl:when>
  				  <xsl:otherwise><xsl:number value="$label" format="1."/></xsl:otherwise>
  			 </xsl:choose>
  		  </fo:block>
  		</fo:list-item-label>
  		<fo:list-item-body start-indent="body-start()">
  		  <fo:block>
          <xsl:apply-templates/>
  		  </fo:block>
  		</fo:list-item-body>
	  </fo:list-item>
  </xsl:template>

<!-- ============================== Title ================================== -->
<!-- Template for PageSeeder list or nlist.  nitem include for backward compatibility only

.. admonition:: xpath:title

   | <fo:block> 
   |   ...
   | </fo:block>

-->  
  <xsl:template match="title">
    <xsl:if test="../*[not(self::title)]">
      <fo:block space-before.optimum="15pt">
        <fo:block>
          <xsl:sequence select="psf:style-properties(., 'section-title')" />
          <xsl:value-of select="." />
        </fo:block>
      </fo:block>
    </xsl:if>
  </xsl:template>

<!-- ============================== Bold ================================== -->
<!-- Template for PageSeeder bold

.. admonition:: xpath:bold

   | <fo:inline font-weight="bold">
   |   ...
   | </fo:inline>

-->  
  <xsl:template match="bold">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>

<!-- ============================== Italic ================================== -->
<!-- Template for PageSeeder italics

.. admonition:: xpath:italic

   | <fo:inline font-weight="italic">
   |   ...
   | </fo:inline>

--> 
  <xsl:template match="italic">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>

<!-- ============================== Underline ================================== -->
<!-- Template for PageSeeder underline

.. admonition:: xpath:underline

   | <fo:inline font-weight="underline">
   |   ...
   | </fo:inline>

--> 
  <xsl:template match="underline">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:apply-templates select="* | text()" />
    </fo:inline>
  </xsl:template>

<!-- ============================== Xref ================================== -->
<!-- Template for PageSeeder xref

.. admonition:: xpath:xref

   | <fo:inline>
   |   <fo:basicc-link internal-destination="">
   |     ...
   |   </fo:basic-link>
   | </fo:inline>

-->
  <xsl:template match="xref">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>
      <xsl:call-template name="xref-link"/>
    </fo:inline>
  </xsl:template>

<!-- Template for PageSeeder blockxref

.. admonition:: xpath:blockxref

   | <fo:inline>
   |   <fo:basic-link internal-destination="">
   |     ...
   |   </fo:basic-link>
   | </fo:inline>

-->
  <xsl:template match="blockxref">
    <xsl:choose>
      <xsl:when test="@type = 'transclude' and (document | fragment)">
        <xsl:apply-templates />
      </xsl:when>
      <xsl:when test="@type = 'embed' and (document | fragment)">
        <xsl:apply-templates />
      </xsl:when>
      <xsl:otherwise><!-- output like a normal XRef? -->
        <fo:block>
          <xsl:sequence select="psf:style-properties(., local-name(.))"/>
          <xsl:call-template name="xref-link"/>
        </fo:block>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
<!-- Template for PageSeeder xref or blockxref link -->
  <xsl:template name="xref-link">
    <xsl:choose>
      <xsl:when test="starts-with(@href,'#')">
        <fo:basic-link internal-destination="psf-{if (substring-after(@href,'#') = '') then @frag else substring-after(@href,'#')}">
          <xsl:choose>
            <xsl:when test=".=''"><xsl:value-of select="@title" /></xsl:when>
            <xsl:otherwise><xsl:apply-templates /></xsl:otherwise>
          </xsl:choose>
        </fo:basic-link>
      </xsl:when>
      <xsl:when test=".=''"><xsl:value-of select="@title" /></xsl:when>
      <xsl:otherwise><xsl:apply-templates /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- ============================== Br (newline) ================================== -->
<!-- Template for PageSeeder newline (e.g. br)

.. admonition:: xpath:br

   | &#160;<fo:blocks/>

--> 
  <xsl:template match="br">
    &#160;<fo:block/>
  </xsl:template>

<!-- ============================== Image ================================== -->
<!-- Template for PageSeeder image

.. admonition:: xpath:image

   | <fo:block>
   |   ...
   | </fo:block>

--> 
  <xsl:template match="image[parent::fragment]">
  	<fo:block>
      <xsl:call-template name="inline-image"/>
  	</fo:block>
  </xsl:template>

  <!--
  Template for PageSeeder image
-->

  <xsl:template name="inline-image" match="image">
    <fo:inline>
      <xsl:sequence select="psf:style-properties(., local-name(.))"/>     
	    <fo:external-graphic>
	      <xsl:attribute name="src">
	    <xsl:text>url(</xsl:text>
	      <xsl:choose>
	      <xsl:when test="starts-with(@src,'http://')">
	        <xsl:value-of select="@src" />
	      </xsl:when>
	      <xsl:when test="contains(@src,'..')">
	        <xsl:text>invalid</xsl:text>
	      </xsl:when>
	      <xsl:otherwise>
	        <xsl:value-of select="$base" /><xsl:value-of select="@src" />
	      </xsl:otherwise>
	      </xsl:choose>
	    <xsl:text>)</xsl:text>
	    </xsl:attribute>
	      <xsl:if test="@width">
	        <xsl:attribute name="content-width" select="concat(@width,'px')" />
	      </xsl:if>
	      <xsl:if test="@height">
	        <xsl:attribute name="content-height" select="concat(@height,'px')" />
	      </xsl:if>
	    </fo:external-graphic>
	  </fo:inline>
  </xsl:template>

<!-- ============================== PDF Bookmarks ================================== -->

<!--     
  <xsl:template match="heading"  mode="bookmark" />
  <xsl:template match="heading[empty(ancestor::blockxref)]" mode="bookmark">
    <fo:bookmark internal-destination="{generate-id()}">
      <fo:bookmark-title><xsl:value-of select="."/></fo:bookmark-title>
      <xsl:if test="number(@level) lt 6">
        <xsl:for-each select="(following-sibling::heading)">
          <xsl:apply-templates select="." mode="bookmark"/>
        </xsl:for-each>
      </xsl:if>
    </fo:bookmark>
  </xsl:template>
 -->
 	
	<!-- Ignore metadata elements in PageSeeder document -->
	<xsl:template match="documentinfo | fragmentinfo | locator | metadata"/>

  <!-- Section title is processed as part of fragment -->
  <xsl:template match="section">
    <xsl:apply-templates select="*[not(self::title)]" />
  </xsl:template>

</xsl:stylesheet>
