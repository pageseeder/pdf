<?xml version="1.0" encoding="UTF-8"?>

  <!--
    This stylesheet mostly defines the pagination of the final PDF document.
    This means multiple regions and flows including headers, footers, and left and right areas.
    
    @author Jean-Baptiste Reure
    
    @version 3 May 2012
    
    Copyright (C) 2012 Weborganic Systems Pty. Ltd.
  -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:psf="http://www.pageseeder.com/function">

  <xsl:include href="psml-to-fo.xsl" />
  <xsl:include href="utilities.xsl" />

  <xsl:output name="xml" media-type="application/xml" indent="yes" />

  <!-- URL for the FO config file -->
  <xsl:param name="foconfigfileurl" select="''" />
  <!-- Base for relative paths  -->
  <xsl:param name="base" />

  <xsl:template match="/">
    <xsl:variable name="configs" select="distinct-values($foconfigs//foconfig/@config)" as="xs:string*"/>
    <!-- find first config used -->
    <!-- make sure the first one is computed correctly: it's the first one that defines a margin zone -->
    <xsl:variable name="first" select="psf:config-with-region(document)" />
    <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
      <fo:layout-master-set>
        <xsl:for-each select="$configs">
          <xsl:variable name="config" select="$foconfigs//foconfig[@config = current()]" />
          <!-- First page, only for main doc -->
          <xsl:if test=". = $first"> 
            <fo:simple-page-master master-name="{.}-first">
              <xsl:sequence select="psf:general-style-properties(., 'page', '', '')"/>
              <fo:region-body><xsl:sequence select="psf:general-style-region-properties(., 'body', '')"/></fo:region-body>
              <xsl:if test="$config//header[@first = 'true']">
                <fo:region-before region-name="{.}-odd-before-first"><xsl:sequence select="psf:general-style-region-properties(., 'header', 'first')"/></fo:region-before>
              </xsl:if>
              <xsl:if test="$config//footer[@first = 'true']">
                <fo:region-after region-name="{.}-odd-after-first"><xsl:sequence select="psf:general-style-region-properties(., 'footer', 'first')"/></fo:region-after>
              </xsl:if>
              <xsl:if test="$config//left[@first = 'true']">
                <fo:region-start region-name="{.}-odd-left-first"><xsl:sequence select="psf:general-style-region-properties(., 'left', 'first')"/></fo:region-start>
              </xsl:if>
              <xsl:if test="$config//right[@first = 'true']">
                <fo:region-end region-name="{.}-odd-right-first"><xsl:sequence select="psf:general-style-region-properties(., 'right', 'first')"/></fo:region-end>
              </xsl:if>
            </fo:simple-page-master>
          </xsl:if>
          <!-- Odd pages -->
          <fo:simple-page-master master-name="{.}-odd">
            <xsl:sequence select="psf:general-style-properties(., 'page', '', '')"/>
            <fo:region-body><xsl:sequence select="psf:general-style-region-properties(., 'body', '')"/></fo:region-body>
            <fo:region-before region-name="{.}-odd-before"><xsl:sequence select="psf:general-style-region-properties(., 'header', 'odd')"/></fo:region-before>
            <fo:region-after  region-name="{.}-odd-after" ><xsl:sequence select="psf:general-style-region-properties(., 'footer', 'odd')"/></fo:region-after>
            <fo:region-start  region-name="{.}-odd-left"  ><xsl:sequence select="psf:general-style-region-properties(., 'left', 'odd')"/></fo:region-start>
            <fo:region-end    region-name="{.}-odd-right" ><xsl:sequence select="psf:general-style-region-properties(., 'right', 'odd')"/></fo:region-end>
          </fo:simple-page-master>
          <!-- even pages -->
          <fo:simple-page-master master-name="{.}-even">
            <xsl:sequence select="psf:general-style-properties(., 'page', 'property', '')"/>
            <fo:region-body><xsl:sequence select="psf:general-style-region-properties(., 'body', '')"/></fo:region-body>
            <fo:region-before region-name="{.}-even-before"><xsl:sequence select="psf:general-style-region-properties(., 'header', 'even')"/></fo:region-before>
            <fo:region-after  region-name="{.}-even-after" ><xsl:sequence select="psf:general-style-region-properties(., 'footer', 'even')"/></fo:region-after>
            <fo:region-start  region-name="{.}-even-left"  ><xsl:sequence select="psf:general-style-region-properties(., 'left', 'even')"/></fo:region-start>
            <fo:region-end    region-name="{.}-even-right" ><xsl:sequence select="psf:general-style-region-properties(., 'right', 'even')"/></fo:region-end>
          </fo:simple-page-master>
        </xsl:for-each>
        <xsl:for-each select="$configs">
          <!-- First page is only for main doc -->
          <xsl:if test=". = $first">
            <fo:page-sequence-master master-name="{.}-go-first">
              <fo:repeatable-page-master-alternatives>
                <fo:conditional-page-master-reference master-reference="{.}-first" odd-or-even="any" page-position="first" />
                <fo:conditional-page-master-reference master-reference="{.}-odd"   odd-or-even="odd" />
                <fo:conditional-page-master-reference master-reference="{.}-even"  odd-or-even="even" />
              </fo:repeatable-page-master-alternatives>
            </fo:page-sequence-master>
          </xsl:if>
          <fo:page-sequence-master master-name="{.}-go">
            <fo:repeatable-page-master-alternatives>
              <fo:conditional-page-master-reference master-reference="{.}-odd"   odd-or-even="odd" />
              <fo:conditional-page-master-reference master-reference="{.}-even"  odd-or-even="even" />
            </fo:repeatable-page-master-alternatives>
          </fo:page-sequence-master>
        </xsl:for-each>
      </fo:layout-master-set>

      <!-- apply PDF bookmark ???? 
      <fo:bookmark-tree>
        <xsl:apply-templates select=".//*[psf:is-fragment(.)]/heading[@level='1']" mode="bookmark" />
      </fo:bookmark-tree>
      -->
      
      <!-- compute labels in headers/footers -->
      <xsl:variable name="label-mapping">
        <mapping xmlns="">
          <xsl:for-each select="$configs">
            <!-- now compute  all unique labels used in headers/footers -->
            <xsl:variable name="all-labels">
              <xsl:value-of select="string-join($foconfigs//foconfig[@config = current()]//header//label/@name, ',')" />
              <xsl:text>,</xsl:text>
              <xsl:value-of select="string-join($foconfigs//foconfig[@config = current()]//footer//label/@name, ',')" />
              <xsl:text>,</xsl:text>
              <xsl:value-of select="string-join($foconfigs//foconfig[@config = current()]//right//label/@name, ',')" />
              <xsl:text>,</xsl:text>
              <xsl:value-of select="string-join($foconfigs//foconfig[@config = current()]//left//label/@name, ',')" />
            </xsl:variable>
            <config name="{.}">
              <xsl:for-each select="distinct-values(tokenize($all-labels, ',')[. != ''])">
                <label name="{.}" />
              </xsl:for-each>
            </config>
          </xsl:for-each>
        </mapping>
      </xsl:variable>
      <!--
        now compute unique elements that will trigger a new flow
        a new flow is defined by
         - a new root[@type] that defines a margin zone
         - a new blockxref[@type='embed'][@documenttype] that defines a margin zone (no more)
         - a new label in a root that defines a margin zone with such a label
       -->
      <xsl:variable name="fragment-ids">
        <xsl:variable name="fragments" select="document//section//*[psf:is-fragment(.)][*]" />
        <!-- load all fragments -->
        <xsl:variable name="all-fragment-ids">
          <ids>
            <!-- go through each element and compare its config with the previous one -->
            <xsl:for-each select="$fragments">
              <!-- check for new config -->
              <xsl:variable name="previous"               select="(preceding::*[psf:is-fragment(.)][*])[last()] | (ancestor::*[psf:is-fragment(.)][*])[last()]" />
              <xsl:variable name="previous-margin-config" select="psf:config-with-region($previous)" />
              <xsl:variable name="this-margin-config"     select="psf:config-with-region(.)" />
              <xsl:choose>
                <!-- if new config that defines new margin zone, then restart flow -->
                <xsl:when test="empty($previous) or string($previous-margin-config) != string($this-margin-config)">
                  <id config="{$this-margin-config}"><xsl:value-of select="@id" /></id>
                </xsl:when>
                <xsl:when test="$label-mapping//config/label"> <!-- speed up -->
                  <xsl:variable name="this-elem"   select="." />
                  <xsl:variable name="this-config" select="psf:load-config(.)" />
                  <!-- if label values used for this config -->
                  <xsl:if test="$label-mapping//config[@name = $this-config]/label">
                    <xsl:for-each select=".//inline[@label]">
                      <!-- if new label value used -->
                      <xsl:if test="$label-mapping//config[@name = $this-config]/label[@name = current()/@label]">
                        <!-- if new label, restart at the parent root or blockxref -->
                        <id><xsl:value-of select="$this-elem/@id" /></id>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:if>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </ids>
        </xsl:variable>
        <!-- ok filter duplicates -->
        <ids>
          <xsl:for-each select="distinct-values($all-fragment-ids//id)">
            <id config="{$all-fragment-ids//id[. = current()][1]/@config}"><xsl:value-of select="." /></id>
          </xsl:for-each>
        </ids>
      </xsl:variable>

      <!-- ok now loop through all fragment children (and toc if first one) -->
      <xsl:for-each select="document/section//*[psf:is-fragment(.)][string(@id) != ''][index-of($fragment-ids//id, @id) != -1] |
                            document/toc[empty(preceding::*[psf:is-fragment(.)])]">
        <xsl:variable name="this-config" select="psf:config-with-region(.)" />
        <xsl:variable name="this-elem"   select="." />
        <xsl:variable name="is-first"    select="empty(preceding::*[psf:is-fragment(.)])" />
        <!-- compute all unique labels used in headers/footers -->
        <!-- and their label values -->
        <xsl:variable name="label-map"><labels>
          <xsl:for-each select="$label-mapping//config[@name = $this-config]/label/@name">
            <label name="{.}">
              <xsl:choose>
                <xsl:when test="$this-elem//inline[@label = current()]">
                  <xsl:value-of select="($this-elem//inline[@label = current()])[1]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="(($this-elem/preceding::*[psf:is-fragment(.)][.//inline[@label = current()]])[last()]//inline[@label= current()])[1]"/>
                </xsl:otherwise>
              </xsl:choose>
          </label></xsl:for-each>
        </labels></xsl:variable>
        <!-- ok create page sequence -->
        <fo:page-sequence master-reference="{$this-config}-go{if (position() = 1) then '-first' else ''}">
          <!-- the first page if there is any -->
          <xsl:if test="$is-first">
            <xsl:variable name="config" select="$foconfigs//foconfig[@config = $this-config]" />
            <xsl:if test="$config//header[@first = 'true']">
              <fo:static-content flow-name="{$this-config}-odd-before-first"><xsl:sequence select="psf:header-footer(., 'header', 'first', $label-map)" /></fo:static-content>
            </xsl:if>
            <xsl:if test="$config//footer[@first = 'true']">
              <fo:static-content flow-name="{$this-config}-odd-after-first"><xsl:sequence select="psf:header-footer(., 'footer', 'first', $label-map)" /></fo:static-content>
            </xsl:if>
            <xsl:if test="$config//left[@first = 'true']">
              <fo:static-content flow-name="{$this-config}-odd-left-first"><xsl:sequence select="psf:left-right(., 'left', 'first', $label-map)" /></fo:static-content>
            </xsl:if>
            <xsl:if test="$config//right[@first = 'true']">
              <fo:static-content flow-name="{$this-config}-odd-right-first"><xsl:sequence select="psf:left-right(., 'right', 'first', $label-map)" /></fo:static-content>
            </xsl:if>
          </xsl:if>
          <fo:static-content flow-name="{$this-config}-odd-before"> <xsl:sequence select="psf:header-footer(., 'header', 'odd', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-odd-after">  <xsl:sequence select="psf:header-footer(., 'footer', 'odd', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-odd-left">   <xsl:sequence select="psf:left-right(., 'left', 'odd', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-odd-right">  <xsl:sequence select="psf:left-right(., 'right', 'odd', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-even-before"><xsl:sequence select="psf:header-footer(., 'header', 'even', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-even-after"> <xsl:sequence select="psf:header-footer(., 'footer', 'even', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-even-left">  <xsl:sequence select="psf:left-right(., 'left', 'even', $label-map)" /></fo:static-content>
          <fo:static-content flow-name="{$this-config}-even-right"> <xsl:sequence select="psf:left-right(., 'right', 'even', $label-map)" /></fo:static-content>
          <fo:flow flow-name="xsl-region-body">
            <!-- find next one so we know when to stop -->
            <xsl:variable name="next-stop" select="(following::*[psf:is-fragment(.)][string(@id) != ''][index-of($fragment-ids//id, @id) != -1])[1]/generate-id()" />
            <xsl:variable name="blocks">
              <!-- apply templates to this fragment's children and all the following until we reach then next one (if there's one) -->
              <xsl:apply-templates select="." />
              <!-- find all fragments between this one and the next stop -->
              <xsl:variable name="next" select="(following::*[psf:is-fragment(.)][string(@id) != ''][*] | ../following::toc)[string($next-stop) = '' or following::*[generate-id() = $next-stop]]" />
              <!-- avoid fragments already included in another fragment in the list (transcluded) -->
              <xsl:variable name="next-ids" select="for $i in $next return generate-id($i)" />
              <xsl:apply-templates select="$next[empty(ancestor::*[exists(index-of($next-ids, generate-id()))])]" />
            </xsl:variable>
            <xsl:variable name="props" select="psf:general-style-properties($this-config, 'body', '', '')"/>
            <xsl:for-each-group select="$blocks/fo:block" group-adjacent="if (@span='all') then 3
                                                                 else if (@span='none') then 2
                                                                 else 1">
              <xsl:choose>
                <xsl:when test="current-grouping-key()=3">
                  <fo:block>
                    <xsl:attribute name="span" select="'all'" />
                    <xsl:sequence select="$props[local-name() != 'span']"/>
                    <xsl:sequence select="current-group()" />
                  </fo:block>
                </xsl:when>
                <xsl:when test="current-grouping-key()=2">
                  <fo:block>
                    <xsl:attribute name="span" select="'none'" />
                    <xsl:sequence select="$props[local-name() != 'span']"/>
                    <xsl:sequence select="current-group()" />
                  </fo:block>
                </xsl:when>
                <xsl:otherwise>
                  <fo:block>
                    <xsl:sequence select="$props"/>
                    <xsl:sequence select="current-group()" />
                  </fo:block>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
            <!-- last page ID -->
            <xsl:if test="string($next-stop) = ''"><fo:block id="last-page" /></xsl:if>
          </fo:flow>
        </fo:page-sequence>
      </xsl:for-each>
      
    </fo:root>
  </xsl:template>

  <!-- 
    Function for global PageSeeder header and footer zones.
    
    @param context the current context (used to compute the FOConfig.xml to use)
    @param h-or-f  header or footer
    @param o-or-e  odd or even or first
    @param labels  the labels and their values (to put in the content)
  -->
  <xsl:function name="psf:header-footer">
    <xsl:param name="context" />
    <xsl:param name="h-or-f" />
    <xsl:param name="o-or-e" />
    <xsl:param name="labels" />

    <xsl:variable name="config-with-region" select="psf:config-with-region($context)" />
    <xsl:variable name="margin-zone-first"  select="psf:margin-zone($context, $h-or-f, 'true')" />
    <xsl:variable name="margin-zone"        select="psf:margin-zone($context, $h-or-f, 'false')" />

    <fo:block vertical-align="bottom">
      <xsl:sequence select="psf:general-style-properties($config-with-region, $h-or-f, $o-or-e, '')"/>
      <fo:table table-layout="fixed" border-collapse="collapse" inline-progression-dimension.optimum="100%">
        <fo:table-column>
          <xsl:attribute name="column-width">
            <xsl:variable name="w">
              <xsl:choose>
                <xsl:when test="$o-or-e = 'first'">
                  <xsl:value-of select="$margin-zone-first/left/@width" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="wid" select="$margin-zone[string(@odd-or-even) = '' or @odd-or-even = $o-or-e]/left/@width" />
                  <xsl:if test="$wid"><xsl:value-of select="$wid" /></xsl:if>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="if (string($w) = '') then 'proportional-column-width(1)' else $w" />
          </xsl:attribute>
        </fo:table-column>
        <fo:table-column>
          <xsl:attribute name="column-width">
            <xsl:variable name="w">
              <xsl:choose>
                <xsl:when test="$o-or-e = 'first'">
                  <xsl:value-of select="$margin-zone-first/center/@width" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="wid" select="$margin-zone[string(@odd-or-even) = '' or @odd-or-even = $o-or-e]/center/@width" />
                  <xsl:if test="$wid"><xsl:value-of select="$wid" /></xsl:if>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="if (string($w) = '') then 'proportional-column-width(1)' else $w" />
          </xsl:attribute>
        </fo:table-column>
        <fo:table-column>
          <xsl:attribute name="column-width">
            <xsl:variable name="w">
              <xsl:choose>
                <xsl:when test="$o-or-e = 'first'">
                  <xsl:value-of select="$margin-zone-first/right/@width" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="wid" select="$margin-zone[string(@odd-or-even) = '' or @odd-or-even = $o-or-e]/right/@width" />
                  <xsl:if test="$wid"><xsl:value-of select="$wid" /></xsl:if>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="if (string($w) = '') then 'proportional-column-width(1)' else $w" />
          </xsl:attribute>
        </fo:table-column>
        <fo:table-body>
          <fo:table-row>
            <fo:table-cell text-align="left">
              <fo:block>
                <xsl:sequence select="psf:general-style-properties($config-with-region, $h-or-f, $o-or-e, 'left')"/>
                <xsl:sequence select="psf:margin-zone-styling($context, $h-or-f, $o-or-e, 'left', $labels)" />
              </fo:block>
            </fo:table-cell>
            <fo:table-cell text-align="center">
              <fo:block>
                <xsl:sequence select="psf:general-style-properties($config-with-region, $h-or-f, $o-or-e, 'center')"/>
                <xsl:sequence select="psf:margin-zone-styling($context, $h-or-f, $o-or-e, 'center', $labels)" />
              </fo:block>
            </fo:table-cell>
            <fo:table-cell text-align="right">
              <fo:block>
                <xsl:sequence select="psf:general-style-properties($config-with-region, $h-or-f, $o-or-e, 'right')"/>
                <xsl:sequence select="psf:margin-zone-styling($context, $h-or-f, $o-or-e, 'right', $labels)" />
              </fo:block>
            </fo:table-cell>
          </fo:table-row>
        </fo:table-body>
      </fo:table>
    </fo:block>
  </xsl:function>
  
  <!-- 
    Function for global PageSeeder left and right areas.
    
    @param context     the current context (used to compute the FOConfig.xml to use)
    @param type        left or right
    @param odd-or-even odd or even or first
    @param labels      the labels and their values (to put in the content)
  -->
  <xsl:function name="psf:left-right">
    <xsl:param name="context" />
    <xsl:param name="type" />
    <xsl:param name="odd-or-even" />
    <xsl:param name="labels" />
    <xsl:variable name="config" select="psf:load-config($context)" />
    <fo:block>
      <xsl:sequence select="psf:style-properties($context, $type)"/>
        <fo:block-container vertical-align="top">
            <xsl:attribute name="height">
              <xsl:choose>
                <xsl:when test="$odd-or-even = 'first'">
                  <xsl:choose>
                    <xsl:when test="psf:margin-zone($context, $type, 'true')/top/@height">
                      <xsl:value-of select="psf:margin-zone($context, $type, 'true')/top/@height" />
                    </xsl:when>
                    <xsl:otherwise>auto</xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/top/@height">
                  <xsl:value-of select="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/top/@height" />
                </xsl:when>
                <xsl:otherwise>auto</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <fo:block>
             <xsl:sequence select="psf:style-properties($context, concat($type, '-top'))"/>
             <xsl:sequence select="psf:margin-zone-styling($context, $type, $odd-or-even, 'top', $labels)" />
           </fo:block>
          </fo:block-container>
          <fo:block-container vertical-align="middle">
            <xsl:attribute name="height">
              <xsl:choose>
                <xsl:when test="$odd-or-even = 'first'">
                  <xsl:choose>
                    <xsl:when test="psf:margin-zone($context, $type, 'true')/middle/@height">
                      <xsl:value-of select="psf:margin-zone($context, $type, 'true')/middle/@height" />
                    </xsl:when>
                    <xsl:otherwise>auto</xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/middle/@height">
                  <xsl:value-of select="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/middle/@height" />
                </xsl:when>
                <xsl:otherwise>auto</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <fo:block>
              <xsl:sequence select="psf:style-properties($context, concat($type, '-middle'))"/>
              <xsl:sequence select="psf:margin-zone-styling($context, $type, $odd-or-even, 'middle', $labels)" />
            </fo:block>
          </fo:block-container>
          <fo:block-container vertical-align="bottom">
            <xsl:attribute name="height">
              <xsl:choose>
                <xsl:when test="$odd-or-even = 'first'">
                  <xsl:choose>
                    <xsl:when test="psf:margin-zone($context, $type, 'true')/bottom/@height">
                      <xsl:value-of select="psf:margin-zone($context, $type, 'true')/bottom/@height" />
                    </xsl:when>
                    <xsl:otherwise>auto</xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                  <xsl:when test="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/bottom/@height">
                    <xsl:value-of select="psf:margin-zone($context, $type, 'false')[string(@odd-or-even) = '' or @odd-or-even = $odd-or-even]/bottom/@height" />
                </xsl:when>
                <xsl:otherwise>auto</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
              <fo:block>
                <xsl:sequence select="psf:style-properties($context, concat($type, '-bottom'))"/>
                <xsl:sequence select="psf:margin-zone-styling($context, $type, $odd-or-even, 'bottom', $labels)" />
              </fo:block>
          </fo:block-container>
    </fo:block>
  </xsl:function>
  
</xsl:stylesheet>
