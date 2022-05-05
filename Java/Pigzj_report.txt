Summary
At this company, we regularly need work to with large data streams that must be compressed. Yet when dealing with such large datasets, it is crucial the compression be performed efficiently and reliably. So far, the compression has been a CPU bottleneck and one solution has been to updgrade the company's hardware and use parallel compression. Programs performing parallel compression have been written in C but do not yet exist in Java, which is the main programming language used at this company. Java is a programming well equipped to handle large amounts of data through the use of multi-threading. This feature provides efficiency by accelerating a program’s runtime, yet it must be employed carefully as it can come at the expense of reliability. A data race can occur if only efficiency is taken into account, markedly reducing the accuracy of the program. To avoid data races, multiple techniques can be utilized to reinstate reliability including fixed thread pools to manage multiple threads running simultaneously and concurrent blocking queues to keep track of threads starting and ending. For the simulation of Pigzj, we tested the compression on several data files of multiple sizes with the aim of finding a balance between speed and compression performance. We report on its performance showing it consistently provides more efficiency with similar performance similar to the C implementation, pigz.c.

Background
Concurrency in Java is an important and powerful feature of the language but it must be handled cautiously. Concurrency occurs through the use of multithreading, where multiple thread objects can divide up a certain task in order to make a program run faster, comparable to parallel computing. One danger of concurrency is the possibility of creating a data race which occurs when multiple threads are accessing an instance of a class at the same time and are performing changes to that object. One way to mitigate this possible issue is through the use of the ExecutorService interface provided by java. Through this interface, it is possible to create a fixed integer Thread pool that adds threads to a pool of threads and through its method submit, the threads can accept Runnable objects that can perform the same task simultaneously. In addition, the shutdown of multiple threads can be difficult, especially threads are performing IO and ending at different times, but ExecutorService provides an efficient method to manage the shutdown of the executor. For certain tasks such as outputting data dynamically, it is also essential that the order of the data sent to output be preserved. To maximize efficiency, an operating system does not necessarily perform tasks on input data in order when the task is performed by multiple threads, therefore it is necessary to use a data structure that can accomodate this constraint. One such data structure is a Linked Blocking queue that orders elements via the FIFO (first-in-first-out) algorithm, ensuring that the order between blocks added to the queue is preserved. IO is essential in compressing data as it is taken in by the program, compressed, and then returned by the program and for this task, the poll() method of Queue Interface is helpful in returning and removing the elements at the head of queue that must be released as output.

Experimental Setup
For reproducibility purposes, we report the use of Java version 16.0 and the specification of the server on which we performed testing, courtesy of the University of California Los Angeles (UCLA). The server, named Lnxsrv11, is from GenuineIntel with model name Intel(R) Xeon(R) Silver 4116 CPU @ 2.10GHz. This server holds 4 processors and 4 cpu cores. It contains a total memory of ~6.564 x 10^7 kB with ~5.967 x 10^7 of those as available memory, allowing for the testing of large files without the risk of memory running out. Tests were performed by passing bytes to the program through standard input and multiple sizes of the input stream were examined: 11 bytes, ~300 KB, ~126 MB. To determine the efficiency of the program, time values were printed including the real time, user CPU time and system CPU time consumed for the entire program to run (in seconds). To measure the performance of the compression, the sizes of the compressed files were compared between compression done by Java Pigzj, and the C implementations of pigz and gzip. When running the multithreaded programs Pigzj and pigz, 3 trials were performed for each test to obtain an average performance since time can vary slightly per run.
The Pigzj Java program consisted of 3 different classes: Pigzj, dataBlockCompressor, and Streams. The Streams class is set up to initialize the buffered input and output stream in order to accept input from standard input and print the compressed blocks to standard output. The dataBlockCompressor class is a class that creates Runnable objects that are passed to the different threads that are spawned by the main class Pigzj. This class that implements the Runnable interface contains a constructor that takes in multiple arguments including the number of the data block being compressed, the input data to compress, a boolean value describing if this block is the last block, a buffer containing the dictionary to improve the compression of this block, and the number of bytes contained in the data block to compress. This class also contains the run method found in Runnable objects that performs the actual data compression. The main public class Pigzj was divided into 3 parts, writing the header bytes needed for a compressed file, creating threads based on the number of processors either available or specified through input arguments and having them perform compressions simultaneously by calling the dataBlockCompressor, and finally writing the trailer bytes necessary for the compressed file as well.


Results and Discussion
Compression efficiency and performance were tested on 3 different input sizes, 11 bytes, ~300 KB and ~126 MB to determine the value of programming parallel compression in Java compared to C. When compression is done on a small input stream of only 11 bytes for example, the overhead produced by a program that will spawn multiple threads hinders the performance, both in terms of efficiency as well as compression size. The results of the testing are as follows on this input stream:

11 bytes
$ time gzip <small_test.txt >gzip.gz
real	0m0.009s, user	0m0.000s, sys	0m0.005s

$ time pigz <small_test.txt >pgiz.gz
real	0m0.015s, user	0m0.000s, sys	0m0.002s
real	0m0.008s, user	0m0.000s, sys	0m0.003s
real	0m0.004s, user	0m0.001s, sys	0m0.002s

$ time java Pigzj <small_test.txt >Pigzj.gz
real	0m0.069s, user	0m0.035s, sys	0m0.027s
real	0m0.063s, user	0m0.034s, sys	0m0.024s
real	0m0.063s, user	0m0.037s, sys	0m0.021s

-rw-r--r-- 1 amina csgrad  31 May 11 15:29 gzip.gz
-rw-r--r-- 1 amina csgrad  31 May 11 15:35 pigz.gz
-rw-r--r-- 1 amina csgrad 176 May 11 15:35 Pigzj.gz

On this small input stream, it took gzip, a single threaded program as well as pigz, the C implementation of multithreaded compression, only 9 milliseconds on average to compress the file whereas Pigzj completed in ~67 milliseconds, almost a 7X increase. In addition, the size of the compressed file was larger for Pigzj than for either of the other 2 programs where the compression ratio of compressed bytes to uncompressed bytes was ~2.81 for both pigz and gzip and 16 for Pigz, making the Java implementation of multithreaded compression considerably weaker and inadequate for compression of small files.

When testing on a medium input stream, such as 300 kB, the results differ. The following presents the time testing and compression sizes of the resulting data files:

~300 kB
$ time gzip <great_gatsby.txt >gzip.gz
real	0m0.042s, user	0m0.028s, sys	0m0.005s

$ time pigz <great_gatsby.txt >pigz.gz
real	0m0.025s, user	0m0.029s, sys	0m0.006s
real	0m0.020s, user	0m0.032s, sys	0m0.000s
real	0m0.020s, user	0m0.029s, sys	0m0.003s

$ time java Pigzj <great_gatsby.txt >Pigzj.gz
real	0m0.077s, user	0m0.062s, sys	0m0.028s
real	0m0.076s, user	0m0.059s, sys	0m0.032s
real	0m0.077s, user	0m0.066s, sys	0m0.025s

[amina@lnxsrv11 ~/Desktop]$ ls -l gzip.gz pigz.gz Pigzj.gz
-rw-r--r-- 1 amina csgrad 115429 May 11 14:35 gzip.gz
-rw-r--r-- 1 amina csgrad 115465 May 11 14:35 pigz.gz
-rw-r--r-- 1 amina csgrad 115983 May 11 14:45 Pigzj.gz

On a medium stream input, the benefits of Pigzj start to become apparent. Even though Pigzj running with 4 threads is still not running faster than gzip which is single threaded, it is only 1.8X slower than gzip instead of 7X slower in the previous test with a small input stream. In addition, the compression ratio is much better when the input stream is around 300 KB, where the Pigzj.gz file is only 38% of the original file size vs 1600% as observed in the previous test.

Testing on a large input stream such as the OpenJDK library modules that comprise almost 126 MB, the full value of Pigzj is displayed. The data of the tests for 1-4 threads running on this large input stream are the following: 

~126 MB
$ time gzip <$input >gzip.gz
real	0m7.671s, user	0m7.315s, sys	0m0.074s

$ time pigz <$input >pigz.gz
real	0m2.218s ,user	0m7.077s, sys	0m0.039s
real	0m2.226s, user	0m7.063s, sys	0m0.055s
real	0m2.246s, user	0m7.089s, sys	0m0.050s

$ time java Pigzj <$input >Pigzj.gz
real	0m2.480s, user	0m7.256s, sys	0m0.445s
real	0m2.492s, user	0m7.235s, sys	0m0.465s
real	0m2.460s, user	0m7.228s, sys	0m0.471s

-rw-r--r-- 1 amina csgrad 43261332 May 11 14:49 gzip.gz
-rw-r--r-- 1 amina csgrad 43134815 May 11 14:51 pigz.gz
-rw-r--r-- 1 amina csgrad 43136403 May 11 14:52 Pigzj.gz

$ time pigz -p 3 <$input >pigz.gz
real	0m2.830s, user	0m7.064s, sys	0m0.141s
real	0m2.765s, user	0m7.042s, sys	0m0.105s
real	0m2.792s, user	0m7.081s, sys	0m0.109s

$ time java Pigzj -p 3 <$input >Pigzj.gz
real	0m3.013s, user	0m7.252s, sys	0m0.482s
real	0m3.007s, user	0m7.259s, sys	0m0.499s
real	0m2.962s, user	0m7.236s, sys	0m0.473s

$ time pigz -p 2 <$input >pigz.gz
real	0m3.955s, user	0m7.049s, sys	0m0.095s
real	0m3.943s, user	0m7.053s, sys	0m0.101s
real	0m3.977s, user	0m7.037s, sys	0m0.090s

$ time java Pigzj -p 2 <$input >Pigzj.gz
real	0m4.159s, user	0m7.259s, sys	0m0.411s
real	0m4.223s, user	0m7.236s, sys	0m0.431s
real	0m4.195s, user	0m7.259s, sys	0m0.456s

$ time pigz -p 1 <$input >pigz.gz
real	0m7.487s, user	0m6.993s, sys	0m0.068s

$ time java Pigzj -p 1 <$input >Pigzj.gz
real	0m7.738s, user	0m7.240s, sys	0m0.430s

First examining the context of running 4 threads simultaneously for both pigz and Pigzj (default number of available processors), the average time for Pigzj to complete, ~2.477s, is only 87 milliseconds longer than the average time for the pigz program to compress the same input stream, ~2.39s. This displays efficiency comparable to the C implementation yet pigz still runs slightly faster as C is a lower level language that usually runs faster than Java. In addition, the time spent performing system calls for the Java implementation of multithreaded compression much larger than for the C implementation, providing a possible explanation for the lag seen in Pigzj. The compression ratio, approximately 0.3424 (compressed to uncompressed bytes), for this test displays a similar compression performance for Pigzj compared to pigz and slightly better than gzip which reported a higher number of compressed bytes.
Next, analyzing the performance Pigzj compared to pigz when reducing the number of threads from 4 to 3 to 2, there is positive trend in terms of the increase in time it takes for Pigzj to complete. When running 3 threads, Pigzj (2.94s on average) lags behind pigz (2.80s on average) by 194 milliseconds compared to only 87 milliseconds when running 4 threads, and when running 2 threads simultaneously, this gap increases to 234 millseconds. This suggests that using Java for multithreaded compression provides the most benefits when the hardware is powerful enough to support many threads, and potentially using more than 4 threads could result in Pigzj running faster than pigz.
In addition, when running Pigzj with only 1 thread, due to the extensive overhead in setting up this single thread using the data structures such as a Thread pool and Concurrent queue, the added safety features of such a queue and the calls made through the threadpool even though it is only managing one thread cause the Pigzj program to run slighly more slowly than the single threaded gzip.

Discussion and Limitations
The results presented in this report show 2 major trends. The first trend occurs when the size of the input stream increases where as this variable grows, the compression ratio decreases and the time required for the Java multithreaded program Pigzj to complete compared to gzip significantly decreases. Therefore, as the input size increases, the value of Pigzj increases. The second trend shows that as the number of threads used in the multithreaded programs pigz Pigzj increases, the time lag between the two decreases, where Pigzj completes only a few milliseconds after pigz when using 4 threads. These results could be explained by the data found in the appendix, that shows the results of running strace on all three programs. When running Pigzj on 4 threads, a large number of processes are launched as calls to futex are being made, explaining the large overhead acquired. In addition, there are over 4000 mprotect system calls made when running Pigzj whereas pigz only makes 32 of those calls. mprotect is called to set protection on a region of memory, a result of a design choice a concurrent linked blocking queue is used to ensure no data races are encountered. In attempting to ensure reliability, the efficiency of the Pigzj program suffered. On the other hand, read and write system calls are also very expensive and Pigzj as well as pigz heavily reduce the amount of those calls made compared to gzip, accounting for their greater speed. 

This implemenation of Pigzj is able to perform compression correctly and output the compressed stream in the same order in which the input stream is fed in, yet when attempting to decompress the resulting compressed stream, an error occurs due to a CRC mismatch. This is most likely occuring due to the mishandling of the EOF byte in the last block that is causing a small mismatch between the original input stream and the decompressed input stream. This presents a serious limitation in the program as the input stream cannot be recovered but it is still fulfills its job of correctly decompressing this stream. The CRC variable is one example of the difficulty of implementing multithreading when compressing a set of input data as it is divided between multiple threads and compressed in pieces but the CRC value is shared between all the threads and must be updated every time a thread completes compression on a portion of the input data. As a result, many manual checks such as conditional if loops and printing to standard error to trace the value of the CRC are implemented, which could also potentially affect the efficiency of the program. Yet even with the safety constraints required by the Java multithreaded implementation of compression, the efficiency gained when compressing large datasets, as is done in this company, makes this program valuable and recommended for use.

Appendix
strace call for Pigzj
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 97.48    5.890732        2903      2029       341 futex
  0.86    0.052063          12      4197           mprotect
  0.46    0.027772          23      1170           read
  0.43    0.025797          26       973           write
  0.22    0.013483          11      1136           fstat
  0.22    0.013420          13      1011           lseek
  0.10    0.006327         263        24           prctl
  0.10    0.005756           7       810           gettid
  0.03    0.002003           8       229        55 openat
  0.02    0.001158           4       238           mmap
  0.02    0.001139           9       115           sysinfo
  0.02    0.001029           5       182           close
  0.01    0.000466           3       143           rt_sigprocmask
  0.00    0.000259           4        53        33 stat
  0.00    0.000242           8        30           munmap
  0.00    0.000187           2        63           sched_getaffinity
  0.00    0.000151           8        18           madvise
  0.00    0.000146           3        38           lstat
  0.00    0.000146           8        17           sched_yield
  0.00    0.000144           5        25           clone
  0.00    0.000105           2        36           getpid
  0.00    0.000104           4        26           set_robust_list
  0.00    0.000062           2        25           rt_sigaction
  0.00    0.000062          15         4           sendto
  0.00    0.000051           6         8           socket
  0.00    0.000049          12         4           getdents64
  0.00    0.000044           1        34           pread64
  0.00    0.000039           3        12           getsockname
  0.00    0.000035           8         4         4 connect
  0.00    0.000024           3         8           getsockopt
  0.00    0.000023          11         2           ftruncate
  0.00    0.000023          11         2         2 statfs
  0.00    0.000023           3         7           prlimit64
  0.00    0.000019           4         4           poll
  0.00    0.000018           2         7           nanosleep
  0.00    0.000018           4         4           recvfrom
  0.00    0.000016           4         4           fchdir
  0.00    0.000015           3         4         4 bind
  0.00    0.000014           3         4           setsockopt
  0.00    0.000012           3         4         2 access
  0.00    0.000012           3         4           geteuid
  0.00    0.000011           2         4           ioctl
  0.00    0.000009           0        44           getrusage
  0.00    0.000008           4         2           clock_getres
  0.00    0.000005           2         2           uname
  0.00    0.000005           5         1           getcwd
  0.00    0.000005           2         2         1 arch_prctl
  0.00    0.000004           1         4           fcntl
  0.00    0.000004           4         1         1 mkdir
  0.00    0.000004           4         1           set_tid_address
  0.00    0.000003           3         1           getuid
  0.00    0.000002           2         1           unlink
  0.00    0.000000           0         4           brk
  0.00    0.000000           0         1           rt_sigreturn
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2           readlink
------ ----------- ----------- --------- --------- ----------------
100.00    6.043248                 12779       443 total

strace call for pigz
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 69.60    0.173191          44      3928       350 futex
 15.61    0.038858          40       963           write
 14.12    0.035145          36       971           read
  0.35    0.000881          27        32           mprotect
  0.14    0.000346           7        44           mmap
  0.07    0.000164           5        28           munmap
  0.06    0.000152          30         5           madvise
  0.03    0.000084          14         6           set_robust_list
  0.01    0.000024           4         5           clone
  0.00    0.000006           0         8           brk
  0.00    0.000000           0         6           close
  0.00    0.000000           0         6           fstat
  0.00    0.000000           0         3           lseek
  0.00    0.000000           0         3           rt_sigaction
  0.00    0.000000           0         1           rt_sigprocmask
  0.00    0.000000           0         2         2 ioctl
  0.00    0.000000           0         1         1 access
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2         1 arch_prctl
  0.00    0.000000           0         1           set_tid_address
  0.00    0.000000           0         6           openat
  0.00    0.000000           0         1           prlimit64
------ ----------- ----------- --------- --------- ----------------
100.00    0.248851                  6023       354 total

strace call for gzip
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 84.79    0.011457        2864         4           close
  7.19    0.000971           0      2641           write
  6.50    0.000878           0      3846           read
  0.38    0.000051           4        12           rt_sigaction
  0.26    0.000035           8         4           mprotect
  0.24    0.000032           6         5           mmap
  0.16    0.000021           7         3           fstat
  0.14    0.000019          19         1           munmap
  0.10    0.000014           7         2           openat
  0.06    0.000008           8         1         1 access
  0.06    0.000008           4         2         1 arch_prctl
  0.04    0.000005           5         1           brk
  0.04    0.000005           5         1         1 ioctl
  0.04    0.000005           5         1           execve
  0.03    0.000004           4         1           lseek
------ ----------- ----------- --------- --------- ----------------
100.00    0.013513                  6525         3 total