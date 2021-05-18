[![Maven Central](https://img.shields.io/maven-central/v/org.pageseeder.pdf/pso-pdf-core.svg?label=Maven%20Central)](https://search.maven.org/search?q=g:%22org.pageseeder.pdf%22%20AND%20a:%22pso-pdf-core%22)

# Pageseeder PDF Export import API

About this library
------------------

This library provides Apache ANT tasks to process a PDF to view using the DocumentCloud viewer.

Dependencies
------------

This library should depends on ANT 1.7 and PDFBox and its dependencies.


Testing
-------

If you want to test the code, ensure that you add all the required libraries to the ANT classpath.
The build will prompt for a PDF file that should be in the /test/pdf folder.

If ANT hangs, it may be necessary to add the following to the command-line -Djava.awt.headless=true

Copyright (c) 1999-2012 Weborganic Pty Ltd - All Rights Reserved.
