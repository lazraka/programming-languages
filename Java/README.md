# Multithreaded gzip compression filter

The goal of the project is to compress fairly large datasets using a similar implementation to the C pigz library in Java.
The compression is performed in parallel, taking advantage of the fact that given servers are multiprocessor and data are generated dynamically in the form of a stream and must be compressed and delivered to its destination on the fly.

###### Project Specifications 
- Write a Java program called Pigzj that behaves like the C pigz implementation operating with multiple compression threads to improve wall-clock performance. 
- Each compression thread acts on an input data block of size 128 KiB. 
- Each thread uses as its dictionary the last 32 KiB of the previous input data block. 
- Compressed output blocks are generated in the same order that their uncompressed blocks were input. 
- The number of compression threads defaults to the number of available processors, but this can be overridden. 
- Program may also use a small, fixed number of threads to control the compression threads or to do input/output.

