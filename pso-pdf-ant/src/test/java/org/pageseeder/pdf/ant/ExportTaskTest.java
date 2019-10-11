package org.pageseeder.pdf.ant;

import org.hamcrest.MatcherAssert;
import org.junit.Assert;
import org.junit.BeforeClass;
import org.junit.Test;
import org.pageseeder.pdf.utils.XML;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Collections;
import java.util.Map;

import static org.hamcrest.CoreMatchers.equalTo;

public class ExportTaskTest {

  private static File WORKING     = new File("test/export/working");
  private static File SOURCE      = new File("test/export/input");
  private static File DESTINATION = new File("test/export/output");
  private static File EXPECTED    = new File("test/export/expected");
  private static File CONFIGS     = new File("test/export/config");

  @BeforeClass
  public static void init() {
    if (!WORKING.exists()) WORKING.mkdir();
    if (!DESTINATION.exists()) DESTINATION.mkdir();
    File[] toClean = DESTINATION.listFiles();
    if (toClean != null) for (File f : toClean) f.delete();
  }

  @Test
  public void testLoremIpsum() throws IOException {

    File lorem = new File(SOURCE, "lorem_ipsum.psml");
    File fo = new File(WORKING, "fo.xml");
    File expectedFo = new File(EXPECTED, "fo.xml");
    File output = new File(DESTINATION, "lorem_ipsum.pdf");
    File config = loadConfig("pdf-export-config-lorem-ipsum.xml");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    ExportTask.FOConfig cfg = task.createConfig();
    cfg.setFile(config);
    cfg.setPriority(1);
    task.execute();

    Assert.assertTrue(output.exists());
    Assert.assertTrue(fo.exists());

    // compare FO
    Assert.assertEquals(new String(Files.readAllBytes(expectedFo.toPath()), StandardCharsets.UTF_8),
                        new String(Files.readAllBytes(fo.toPath()),         StandardCharsets.UTF_8));
  }

  @Test
  public void testPrefixes() throws IOException {

    File lorem = new File(SOURCE, "lorem_ipsum.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "lorem_ipsum.pdf");
    File config = loadConfig("pdf-export-config-prefixes.xml");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    ExportTask.FOConfig cfg = task.createConfig();
    cfg.setFile(config);
    cfg.setPriority(1);
    task.execute();

    Assert.assertTrue(output.exists());
    Assert.assertTrue(fo.exists());

    Map<String, String> ns = Collections.singletonMap("fo", "http://www.w3.org/1999/XSL/Format");
    String xml = new String(Files.readAllBytes(fo.toPath()), StandardCharsets.UTF_8);
    String frag = "//fo:block[@id='psf-2.1251']";
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[1]/@start-indent", equalTo("-1cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[2]/@start-indent", equalTo("-2cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[3]/@start-indent", equalTo("-3cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[4]/@start-indent", equalTo("-4cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[5]/@start-indent", equalTo("-5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[6]/@start-indent", equalTo("-6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[7]/@start-indent", equalTo("-1.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[8]/@start-indent", equalTo("-2.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[1]/fo:table-column[1]/@column-width", equalTo("1cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[2]/fo:table-column[1]/@column-width", equalTo("2cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[3]/fo:table-column[1]/@column-width", equalTo("3cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[4]/fo:table-column[1]/@column-width", equalTo("4cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[5]/fo:table-column[1]/@column-width", equalTo("5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[6]/fo:table-column[1]/@column-width", equalTo("6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[7]/fo:table-column[1]/@column-width", equalTo("1.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[8]/fo:table-column[1]/@column-width", equalTo("2.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[1]//fo:table-cell[1]/fo:block/@color", equalTo("green")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[2]//fo:table-cell[1]/fo:block/@color", equalTo("blue")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[3]//fo:table-cell[1]/fo:block/@color", equalTo("yellow")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[4]//fo:table-cell[1]/fo:block/@color", equalTo("red")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[5]//fo:table-cell[1]/fo:block/@color", equalTo("purple")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[6]//fo:table-cell[1]/fo:block/@color", equalTo("orange")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[7]//fo:table-cell[1]/fo:block/@font-size", equalTo("10pt")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(frag+"/fo:table[8]//fo:table-cell[1]/fo:block/@font-size", equalTo("15pt")).withNamespaceContext(ns));
  }

  @Test
  public void testLabelledDocument() throws IOException {

    File lorem = new File(SOURCE, "labelled-document.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "labelled-document.pdf");
    File config = loadConfig("pdf-export-config-labelled-document.xml");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    ExportTask.FOConfig cfg = task.createConfig();
    cfg.setFile(config);
    cfg.setPriority(1);
    task.execute();

    Assert.assertTrue(output.exists());
    Assert.assertTrue(fo.exists());

    Map<String, String> ns = Collections.singletonMap("fo", "http://www.w3.org/1999/XSL/Format");
    String xml = new String(Files.readAllBytes(fo.toPath()), StandardCharsets.UTF_8);
    MatcherAssert.assertThat(xml, XML.hasXPath("count(//fo:simple-page-master[@master-name = 'label-pdf1-first'])", equalTo("1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:simple-page-master[@master-name = 'label-pdf1-first']/fo:region-before/@extent", equalTo("1.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("count(//fo:page-sequence/fo:static-content[@flow-name = 'label-pdf1-odd-before-first'])", equalTo("1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("count(//fo:page-sequence/fo:static-content[@flow-name = 'label-pdf1-odd-after-first'])",  equalTo("1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence/fo:static-content[@flow-name = 'label-pdf1-odd-before-first']//fo:table-cell[3]/fo:block", equalTo("first labelled styles pdf1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence/fo:static-content[@flow-name = 'label-pdf1-odd-before']//fo:table-cell[3]/fo:block", equalTo("labelled styles pdf1")).withNamespaceContext(ns));

  }

  private File loadConfig(String path) {
    File config = new File(CONFIGS, path);
    Assert.assertTrue(config.exists());
    // validate using schema
    MatcherAssert.assertThat(config, XML.validates("pdf-export-config.xsd"));
    return config;
  }
}
