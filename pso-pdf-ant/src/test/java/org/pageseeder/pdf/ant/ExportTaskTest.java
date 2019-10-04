package org.pageseeder.pdf.ant;

import org.junit.Assert;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.File;
import java.io.InputStream;

public class ExportTaskTest {

  private static File WORKING     = new File("test/working/export");
  private static File SOURCE      = new File("test/input/export");
  private static File DESTINATION = new File("test/output/export");
  private static File CONFIG      = new File("test/pdf-export-config.xml");

  @BeforeClass
  public static void init() {
    if (!WORKING.exists()) WORKING.mkdir();
    if (!DESTINATION.exists()) DESTINATION.mkdir();
    File[] toClean = DESTINATION.listFiles();
    if (toClean != null) for (File f : toClean) f.delete();
  }

  @Test
  public void testLoremIpsum() {

    File lorem = new File(SOURCE, "lorem_ipsum.psml");
    File fo = new File(WORKING, "fo.xml");
    File output = new File(DESTINATION, "lorem_ipsum.pdf");

    ExportTask task = new ExportTask();
    task.setDebug(true);
    task.setWorking(WORKING);
    task.setSrc(lorem);
    task.setDest(output);
    ExportTask.FOConfig cfg = task.createConfig();
    cfg.setFile(CONFIG);
    cfg.setPriority(1);
    task.execute();

    Assert.assertTrue(output.exists());
    Assert.assertTrue(fo.exists());

  }

}
