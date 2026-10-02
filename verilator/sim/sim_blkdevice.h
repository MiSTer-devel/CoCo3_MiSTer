#pragma once
#include <iostream>
#include <fstream>
#include "verilated.h"
#include "sim_console.h"

// Off by default: a sweep must never modify the user's disk images.
extern bool disk_persist_writes;


#ifndef _MSC_VER
#else
#define WIN32
#endif

#define kVDNUM 10
#define kBLKSZ 512

struct SimBlockDevice {
public:

	IData* sd_lba[kVDNUM];
	SData* sd_rd;
	SData* sd_wr;
	SData* sd_ack;
	SData* sd_buff_addr;
	CData* sd_buff_dout;
	CData* sd_buff_din[kVDNUM];
	CData* sd_buff_wr;
	SData* img_mounted;
	CData* img_readonly;
	QData* img_size;

	int bytecnt;
        long int disk_size[kVDNUM];
	long int header_size[kVDNUM];
	bool reading;
	bool writing;
	int ack_delay;
	int current_disk;
	bool mountQueue[kVDNUM];
	std::fstream disk[kVDNUM];

	// 64-bit, not int. main_time passes INT_MAX around frame 2666 at 48 MHz /
	// 60 Hz (~800k cycles a frame); truncating it made `cycles` go negative, the
	// `cycles < 2000` guard below became permanently true, and the block device
	// silently stopped servicing every request from then on. See TODO.md P4-5.
	void BeforeEval(uint64_t cycles);
	void AfterEval(void);
	//void QueueDownload(std::string file, int index);
	//void QueueDownload(std::string file, int index, bool restart);
	//bool HasQueue();
	void MountDisk( std::string file, int index);

	SimBlockDevice(DebugConsole c);
	~SimBlockDevice();


private:
	//std::queue<SimBus_DownloadChunk> downloadQueue;
	//SimBus_DownloadChunk currentDownload;
	//void SetDownload(std::string file, int index);
};
