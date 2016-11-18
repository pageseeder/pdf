/*
 * Copyright (c) 1999-2012 weborganic systems pty. ltd.
 */
package org.pageseeder.pdf.ant;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;

import javax.imageio.ImageIO;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.util.PDFImageWriter;
import org.apache.pdfbox.util.PDFTextStripper;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.pageseeder.pdf.util.ImageScaler;


/**
 * An ANT task to import a Excel Spreadsheet as a single or multiple PageSeeder documents.
 *
 * @author Christophe Lauret
 * @version 19 April 2012
 */
public final class ProcessTask extends Task {

  /**
   * The PowerPoint Presentation to import.
   */
  private File _source;

  /**
   * Where to create the PageSeeder documents (a directory).
   */
  private File _destination;

  // Set properties
  // ----------------------------------------------------------------------------------------------

  /**
   * Set the source PDF file to process.
   *
   * @param pdf The PDF file to process
   */
  public void setSrc(File pdf) {
    if (!(pdf.exists())) {
      throw new BuildException("the PDF " + pdf.getName()+ " doesn't exist");
    }
    if (pdf.isDirectory()) {
      throw new BuildException("the PDF " + pdf.getName() + " can't be a directory");
    }
    String name = pdf.getName();
    if (!name.endsWith(".pdf") && !name.endsWith(".pdf")) {
      log("presentation file should generally end with .pptx or .zip - but was "+name);
    }
    this._source = pdf;
  }

  /**
   * Set the destination folder where the PageSeeder document should be created.
   *
   * @param destination The destination folder.
   */
  public void setDest(File destination) {
    this._destination = destination;
    if (destination.exists() && !destination.isDirectory()) {
      throw new BuildException("the destination " + destination.getName() + " must be a directory");
    }
  }

  // Execute
  // ----------------------------------------------------------------------------------------------

  @Override
  public void execute() throws BuildException {
    if (this._source == null)
      throw new BuildException("Source presentation must be specified using 'src' attribute");

    // Defaulting destination directory
    if (this._destination == null) {
      this._destination = this._source.getParentFile();
      log("Destination set to source directory "+this._destination.getAbsolutePath()+"");
    }

    // 4. Convert rows to PSXML
    log("Processing file");
    PDDocument document = null;
    try {
      document = PDDocument.loadNonSeq(this._source, null, null);
      PDFImageWriter writer = new PDFImageWriter();

      // Grab the name
      String name = this._source.getName();
      if (name.endsWith(".pdf")) name = name.substring(0, name.length() - 4);

      // Compute the destination
      this._destination.mkdirs();
      String prefix = new File(this._destination, name +"-p").getAbsolutePath();

      boolean success = writer.writeImage(document, "png", null, 1, Integer.MAX_VALUE, prefix, 1, 300);

      // Generate all the sizes
      File[] files = this._destination.listFiles();
      for (File f : files) {
        BufferedImage image = ImageIO.read(f);
        String iname = f.getName().substring(0, f.getName().length() - 4);
        log("Downscaling "+f.getName());

        // Large
        scale(image, iname, 1000, "large");
        scale(image, iname, 700, "normal");
        scale(image, iname, 180, "small");

        f.delete();
      }

      // Extract the text from each page
      PDFTextStripper stripper = new PDFTextStripper("utf-8");
      int pages = document.getNumberOfPages();
      for (int page = 1; page <= pages; page++) {
        log("Extracting text from page "+page);
        stripper.setStartPage(page);
        stripper.setEndPage(page);
        File file = new File(this._destination, name+"-p"+page+".txt");
        OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(file), "utf-8");
        stripper.writeText(document, output);
        output.close();
      }

      // Generate the JSON
      log("Generating the JSON file");
      File json = new File(this._destination, name+".json");
      OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(json), "utf-8");
      generateJSON(document, output, name, "http://docviewer.local:8099/data/");
      output.close();

    } catch (Exception ex) {
      ex.printStackTrace();
    }

  }

  private boolean scale(BufferedImage image, String name, int width, String size) throws IOException {
    BufferedImage large = ImageScaler.scale(image, width);
    File file = new File(this._destination, name+"-"+size+".png");
    return ImageIO.write(large, "png", file);
  }

  private static void generateJSON(PDDocument document, Writer writer, String id, String webpath) throws IOException  {
    writer.append('{');
    PDDocumentInformation info = document.getDocumentInformation();
    writeJSON("id", id, writer).append(',');
    String title = info.getTitle();
    writeJSON("title", title != null? title : id, writer).append(',');
    String description = info.getSubject();
    if (description != null)
      writeJSON("description", info.getSubject(), writer).append(',');
    writeJSON("pages", Integer.toString(document.getNumberOfPages()), writer).append(',');
    String contributor = info.getAuthor();
    if (contributor != null)
      writeJSON("contributor", contributor, writer).append(',');
    writeJSON("created_at", "Sat, 24 Apr 2010 05:09:21 +0000", writer).append(','); // info.getCreationDate()
    writeJSON("updated_at", "Thu, 25 Oct 2012 18:28:03 +0000", writer).append(','); // info.getModificationDate()
    writer.append("\"resources\": {");
    writer.append("\"page\": {");
    writeJSON("text",  webpath+id+'/'+id+"-p{page}.txt" , writer).append(',');
    writeJSON("image", webpath+id+'/'+id+"-p{page}-{size}.png", writer);
    writer.append("},");
    writeJSON("pdf",  webpath+id+'/'+id+".pdf" , writer);
    writer.append("}");

    // The End
    writer.append('}');
  }


  private static Writer writeJSON(String name, String value, Writer writer) throws IOException {
    // TODO encoding...
    writer.append('"').append(name).append('"').append(':');
    writer.append('"').append(value).append('"');
    return writer;
  }

}



