import java.util.zip.*;
import java.io.*;
import java.util.concurrent.*;
import java.io.IOException;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;

class Streams {
	BufferedInputStream inStream = new BufferedInputStream(System.in);
	BufferedOutputStream outStream = new BufferedOutputStream(System.out);
	
	//public Streams();

	public BufferedInputStream getInStream() {
		return inStream;
	}
	public BufferedOutputStream getOutStream() {
		return outStream;
	}
}


class dataBlockCompressor implements Runnable {
	public final static int BLOCK_SIZE = 131072; //128 KiB
	public final static int DICT_SIZE = 32768; //32 KiB

	private int dataSize;
	private byte[] dataBuf;
	private boolean lastBlock;
	private int blockNum;
	private byte[] compBlockBuf;
	private int deflatedBytes;
	private byte[] dictBuf;


	//Constructor for the compressed blocks
	public dataBlockCompressor(int dataBlockNum, byte[] inputData, boolean isLastBlock, byte[] dictBlock, int bytesRead) {
		lastBlock = isLastBlock;
		dataBuf = inputData;
		dataSize = bytesRead;
		System.arraycopy(inputData, 0, dataBuf, 0, BLOCK_SIZE);
		blockNum = dataBlockNum;
		compBlockBuf = new byte[BLOCK_SIZE * 2];
		deflatedBytes = 0;
		dictBuf = dictBlock;
	}

	public int getDeflatedBytes() {
		return deflatedBytes;
	}
	public byte[] getCompBlock() {
		return compBlockBuf;
	}

	public int getDataBlockNum() {
		return blockNum;
	}

	public void run() {
		Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
		compressor.setInput(dataBuf);
		//compressor.reset();

		if(lastBlock) {
			//System.err.println("Called compressor finish");
			compressor.finish();
		}

		if(dictBuf != null) {
			compressor.setDictionary(dictBuf);
		}

		if(lastBlock) {
			deflatedBytes = compressor.deflate(compBlockBuf, 0, compBlockBuf.length, Deflater.SYNC_FLUSH);
		} else {
			deflatedBytes = compressor.deflate(compBlockBuf, 0, compBlockBuf.length,Deflater.SYNC_FLUSH);
		}
	}
}

public class Pigzj {
	private int numOfProcesses;
	private static CRC32 crc = new CRC32();
	private static ExecutorService threadPool;
	private static LinkedBlockingQueue<dataBlockCompressor> blockQueue = new LinkedBlockingQueue<dataBlockCompressor>();
	private static Streams streams;
	private static int totalBytesRead = 0;

	public final static int GZIP_MAGIC = 0x8b1f;
	public final static int BLOCK_SIZE = 131072; //128 KiB
	public final static int DICT_SIZE = 32768; //32 KiB
	private final static int TRAILER_SIZE = 8;

	public static void dataBlockReader() {
		try{
			crc.reset();

			boolean hasDict = false;
			byte[] dictBuf = null;
			boolean isLast = false;
			int dataBlockNum = 0;
			/*Buffers for input blocks, compressed blocks, and dictionaries */

			do {
				byte[] blockBuf = new byte[BLOCK_SIZE];
				int nBytes = streams.getInStream().read(blockBuf, 0, BLOCK_SIZE);
				
				if (nBytes == 0) {
					totalBytesRead -= 1;
					break;
				}

				isLast = (System.in.available() == 0); //if no data to read, this is the last block
				dataBlockCompressor compressedBlock = new dataBlockCompressor(dataBlockNum, blockBuf, isLast, dictBuf, nBytes);
				threadPool.submit(compressedBlock);

				crc.update(blockBuf, 0, nBytes);
				//System.err.println((int)crc.getValue());
				totalBytesRead += nBytes;
				dataBlockNum++;

				if(!blockQueue.offer(compressedBlock)) {
					System.err.println("Memory in queue full.");
					System.exit(1);
				}

				if(!isLast) {
					dictBuf = new byte[DICT_SIZE];
					System.arraycopy(blockBuf, (BLOCK_SIZE-DICT_SIZE), dictBuf, 0, DICT_SIZE);
				}

			} while(!isLast);
		} catch (IOException eofe) {
			System.err.println("Error reading stream");
		}
	}

	//ints must be converted to a byte array
	private static byte[] intToByteArray(int value) {
		byte[] byteArr = new byte[] {
			(byte)(value & 0xff),
			(byte)(value >> 8 & 0xff),
			(byte)(value >> 16 & 0xff),
			(byte)(value >> 24 & 0xff)
		};
		return byteArr;
	}


	public static void main(String[] args) {
		int numOfProcesses = Runtime.getRuntime().availableProcessors();
		int arg_len = args.length;
		int inputProcesses = 0;
		
		if (arg_len == 2) {
			if (!args[0].equals("-p")) {
				System.err.println("Incorrect input arguments. Exiting.");
				System.exit(1);
			}
			try {
				inputProcesses = Integer.parseInt(args[1]);
				if (inputProcesses > numOfProcesses) {
					System.err.println("Number of threads out of range. Exiting.");
					System.exit(1);
				} else {
					numOfProcesses = inputProcesses;
				}
			} catch (NumberFormatException a) {
				;
			}
		}
		//account for wrong number of inputs

		streams = new Streams();

		//Write header first
		try {
			streams.getOutStream().write(new byte[] {(byte)0x1f, (byte)0x8b, (byte)0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00});
			streams.getOutStream().flush();
		} catch (IOException err) {
			System.err.println("Could not access output stream. Exiting.");
			System.exit(1);
		}

		//initialize the thread pool object with number of threads from input argument
		threadPool = Executors.newFixedThreadPool(numOfProcesses);

		//read input data and set up Executor queue
		dataBlockReader();

		//Wait for all threads to terminate
		try{
			threadPool.shutdown();
			threadPool.awaitTermination(10, TimeUnit.MINUTES);
		} catch (Exception interrupted) {
			System.err.println("Thread execution timed out, past 10 minutes to compress block. Exiting");
			System.exit(1);
		}
		
		//Write compressed data
		try {
			while(blockQueue.size() > 0) {
				dataBlockCompressor blockToCompress = blockQueue.poll();
				streams.getOutStream().write(blockToCompress.getCompBlock(), 0, blockToCompress.getDeflatedBytes());
			}
		} catch (IOException err) {
			System.err.println("Could not access output stream. Exiting");
			System.exit(1);
		}
		//System.err.println("Total bytes read: " + totalBytesRead);

		//Write trailer
		try {
			
			streams.getOutStream().write(intToByteArray((int)crc.getValue()));
			//System.err.println(intToByteArray((int)crc.getValue()));
			streams.getOutStream().write(intToByteArray((int)(totalBytesRead-1)));
			streams.getOutStream().flush();
			
		} catch (IOException err) {
			System.err.println("Could not access output stream. Exiting.");
			System.exit(1);
		}
		return;
	}
}
