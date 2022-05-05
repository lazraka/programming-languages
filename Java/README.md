# Multithreaded gzip compression filter

 generate some fairly large data streams and compress them using gzip
 reprogram your servers to do the compression in parallel, taking advantage of the fact that your servers are multiprocessor
 data are generated dynamically in in the form of a stream, and you want the data to be compressed and delivered to its destination on the fly
 divide the input into fixed-size blocks (with block size equal to 128 KiB), and have P threads that are each busily compressing a block. 
 That is, pigz starts by reading P blocks and starting a compression thread on each block. It then waits for the first thread to finish, outputs its result, and then can reuse that thread to compress the (P+1)st block.
