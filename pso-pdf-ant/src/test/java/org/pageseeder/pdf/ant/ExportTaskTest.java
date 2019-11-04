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
    String expected_cont = new String(Files.readAllBytes(expectedFo.toPath()), StandardCharsets.UTF_8);
    String actual_cont = new String(Files.readAllBytes(fo.toPath()),         StandardCharsets.UTF_8);
    // normalize EOL chars
    expected_cont = expected_cont.replaceAll("\\r\\n", "\n");
    actual_cont = actual_cont.replaceAll("\\r\\n", "\n");
    // normalize file locations
    expected_cont = expected_cont.replaceAll("file:/.*/pso-pdf-ant/", "");
    actual_cont = actual_cont.replaceAll("file:/.*/pso-pdf-ant/", "");
    Assert.assertEquals(expected_cont, actual_cont);
  }

  @Test
  public void testPrefixes() throws IOException {

    File lorem = new File(SOURCE, "prefixes.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "prefixes.pdf");
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

    String headingsFrag = "//fo:block[@id='psf-headings']";
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[1]/@start-indent", equalTo("-1cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]/@start-indent", equalTo("-2cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[3]/@start-indent", equalTo("-3cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[4]/@start-indent", equalTo("-4cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[5]/@start-indent", equalTo("-5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[6]/@start-indent", equalTo("-6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[1]/fo:table-column[1]/@column-width", equalTo("1cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]/fo:table-column[1]/@column-width", equalTo("2cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[3]/fo:table-column[1]/@column-width", equalTo("3cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[4]/fo:table-column[1]/@column-width", equalTo("4cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[5]/fo:table-column[1]/@column-width", equalTo("5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[6]/fo:table-column[1]/@column-width", equalTo("6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[1]//fo:table-cell[1]/fo:block/@color", equalTo("yellow")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]//fo:table-cell[1]/fo:block/@color", equalTo("orange")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[3]//fo:table-cell[1]/fo:block/@color", equalTo("green")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[4]//fo:table-cell[1]/fo:block/@color", equalTo("red")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[5]//fo:table-cell[1]/fo:block/@color", equalTo("purple")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[6]//fo:table-cell[1]/fo:block/@color", equalTo("blue")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[1]/@background-color", equalTo("black")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[1]/@width", equalTo("18cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]/@background-color", equalTo("black")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]/@width", equalTo("19cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[2]//fo:table-cell[1]/@background-color", equalTo("white")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(headingsFrag+"/fo:table[3]/@width", equalTo("100%")).withNamespaceContext(ns));

    String parasFrag = "//fo:block[@id='psf-paras']";
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[1]//fo:table-cell[1]/fo:block/@font-size", equalTo("10pt")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[2]//fo:table-cell[1]/fo:block/@font-size", equalTo("15pt")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[1]/fo:table-column[1]/@column-width", equalTo("1.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[2]/fo:table-column[1]/@column-width", equalTo("2.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[1]/@start-indent", equalTo("-1.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[2]/@start-indent", equalTo("-2.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:block[1]/@start-indent", equalTo("5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:block[2]/@start-indent", equalTo("6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:block[1]/@text-indent", equalTo("-5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:block[2]/@text-indent", equalTo("-6cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[3]/@background-color", equalTo("black")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[3]/@width", equalTo("100%")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[4]/@background-color", equalTo("black")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[4]/@width", equalTo("14.5cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath(parasFrag+"/fo:table[4]//fo:table-cell[1]/@background-color", equalTo("white")).withNamespaceContext(ns));
  }

  @Test
  public void testRoles() throws IOException {

    File lorem = new File(SOURCE, "roles.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "roles.pdf");
    File config = loadConfig("pdf-export-config-roles.xml");

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
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:inline)[1]/fo:basic-link/@color", equalTo("#1f4f76")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:inline)[2]/fo:basic-link/@color", equalTo("#777700")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:inline)[3]/@color", equalTo("#1f4f76")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:inline)[4]/@color", equalTo("#aaaa00")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:block)[7]/@color", equalTo("#1f4f76")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:block)[8]/@color", equalTo("#dddd00")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:list-block)[1]/@color", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:list-block)[2]/@color", equalTo("#007777")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:list-block)[3]/@color", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:list-block)[4]/@color", equalTo("#00ffff")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table)[1]/parent::fo:block/@background-color", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table)[2]/parent::fo:block/@background-color", equalTo("#770077")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-column)[1]/@background-color", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-column)[3]/@background-color", equalTo("#990099")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-row)[3]/@background-color", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-row)[6]/@background-color", equalTo("#bb00bb")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[1]/@height", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[3]/@height", equalTo("")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[7]/@height", equalTo("1cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[9]/@height", equalTo("2cm")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[1]/fo:block/@color", equalTo("white")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[3]/fo:block/@color", equalTo("#1f4f76")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[7]/fo:block/@color", equalTo("#dd00dd")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:flow//fo:table-cell)[9]/fo:block/@color", equalTo("#ff00ff")).withNamespaceContext(ns));
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

  @Test
  public void testTranscludedDocument() throws IOException {

    File lorem = new File(SOURCE, "transcluded-document.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "transcluded-document.pdf");
    File config = loadConfig("pdf-export-config-transcluded-document.xml");

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
    MatcherAssert.assertThat(xml, XML.hasXPath("count(//fo:simple-page-master[@master-name = 'custom-first'])", equalTo("1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("count(//fo:page-sequence)",                                     equalTo("5")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence[1]/@master-reference",                       equalTo("custom-go-first")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[1]/fo:flow//fo:block)[3]/@id",              equalTo("psf-100")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence[2]/@master-reference",                       equalTo("label-pdf2-go")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[2]/fo:flow//fo:block)[3]/@id",              equalTo("psf-200")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence[3]/@master-reference",                       equalTo("custom-go")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[3]/fo:flow//fo:block)[3]/@id",              equalTo("psf-400")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence[4]/@master-reference",                       equalTo("label-pdf2-go")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[4]/fo:flow//fo:block)[2]/@id",              equalTo("psf-200-4")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("//fo:page-sequence[5]/@master-reference",                       equalTo("custom-go")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[5]/fo:flow//fo:block)[2]/@id",              equalTo("psf-100-4")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("(//fo:page-sequence[5]/fo:flow//fo:block)[last()]/@id",                   equalTo("last-page")).withNamespaceContext(ns));

  }

  @Test
  public void testTOC() throws IOException {

    File lorem = new File(SOURCE, "toc.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "toc.pdf");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    task.execute();

    Assert.assertTrue(output.exists());
    Assert.assertTrue(fo.exists());

    Map<String, String> ns = Collections.singletonMap("fo", "http://www.w3.org/1999/XSL/Format");
    String xml = new String(Files.readAllBytes(fo.toPath()), StandardCharsets.UTF_8);
    String tocBlock = "//fo:flow//fo:block[@id='toc-123456']";
    MatcherAssert.assertThat(xml, XML.hasXPath("count("+tocBlock+")",                equalTo("1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("count("+tocBlock+"//fo:basic-link)", equalTo("11")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[1]",   equalTo("1. heading 1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[2]",   equalTo("1.1. heading 2")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[3]",   equalTo("1.1.1. heading 3")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[4]",   equalTo("1.1.1.1. heading 4")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[5]",   equalTo("1.1.1.1.1. heading 5")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[6]",   equalTo("1.1.1.1.1.1. heading 6")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[7]",   equalTo("2. heading 1")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[8]",   equalTo("2.1. heading 2")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[9]",   equalTo("2.2. heading 2")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[10]",  equalTo("2.3.1. heading 3")).withNamespaceContext(ns));
    MatcherAssert.assertThat(xml, XML.hasXPath("("+tocBlock+"//fo:basic-link)[11]",  equalTo("2.3. heading 2")).withNamespaceContext(ns));

  }

  @Test
  public void testMathML() throws IOException {

    File lorem = new File(SOURCE, "mathml.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "mathml.pdf");
    File config = loadConfig("pdf-export-config-mathml.xml");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    ExportTask.FOConfig cfg = task.createConfig();
    cfg.setFile(config);
    cfg.setPriority(1);
    task.execute();
  }

  private File loadConfig(String path) {
    File config = new File(CONFIGS, path);
    Assert.assertTrue(config.exists());
    // validate using schema
    MatcherAssert.assertThat(config, XML.validates("pdf-export-config.xsd"));
    return config;
  }
}
