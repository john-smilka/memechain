/**
 * *****************************************************************************
 * @file        check_blocks.h
 * @brief       Verify the sum hash per 1000 heights
 * @date        2023-09-26
 * @copyright   mmc
 * *****************************************************************************
 */
#ifndef CA_CHECK_BLOCKS_HEADER
#define CA_CHECK_BLOCKS_HEADER

#include <cstdint>
#include <mutex>
#include <string>
#include <utility>

#include "db/db_api.h"
#include "utils/timer.hpp"
#include "proto/sync_block.pb.h"
#include "net/msg_queue.h"

/**
 * @brief       Verify the sum hash per 1000 heights
 */
class CheckBlocks
{
public:

	/**
	 * @brief       Gets the highest height hash value in the current database
	 * 
	 */
    CheckBlocks();  

	/**
	 * @brief       The timer executes the _ToCheck function at regular intervals
	 */
    void StartTimer();

	/**
	 * @brief       Stop the timer
	 */
	void StopTimer() { _timer.Cancel(); }

	/**
	 * @brief       get stake and delegatinged addr
	 * 
	 * @param       dbReader:   db object
	 * @param       pledgeAddr: stake and delegatinged addr
	 * @return      int success return 0
	 */
	int fetchPledgeAddress(DBReadWriter& dbReader, std::vector<std::string>& pledgeAddr);

	/**
	 * @brief       If _ToCheck fails, the range of the wrong blocks is determined by Byzantium
	 * 
	 * @param       node_ids_to_send: Request data from these nodes
	 * @param       heightsForSending: The height of the requested data block
	 * @param       needSyncHeights: Determine the height of the error
	 * @return      int success return 0
	 */
	int calculateByzantineSumHash(const std::vector<std::string> &node_ids_to_send, const std::vector<uint64_t>& heightsForSending,std::vector<uint64_t>& needSyncHeights);

	/**
	 * @brief       Get the right data through Byzantium
	 * 
	 * @param       node_ids_to_send: Request data from these nodes
	 * @param       pledgeAddr: stake and delegatinged addr
	 * @param       nodeHeight: self  Height
	 * @return      int  success return 0
	 */
	int performNewSynchronization(std::vector<std::string> node_ids_to_send, std::vector<std::string>& pledgeAddr ,uint64_t nodeHeight);

	/**
	 * @brief       Get the Temp Top Data object
	 * 
	 * @return      std::pair<uint64_t, std::string>  Temp data
	 */
	std::pair<uint64_t, std::string> fetchTemporaryTopData();
private:
	/**
	 * @brief       Gets the highest height hash value in the current database
	 */
	void _Init();

	/**
	 * @brief       Loop to check if there is a problem with its own block of corresponding height
	 * 
	 * @return      int  success return 0
	 */
    int _ToCheck(); 

	/**
	 * @brief       Set the Temp Top Data object
	 * 
	 * @param       height: Gets the currently calculated height
	 * @param       hash: Gets the currently calculated hash
	 */
	void setTemporaryTopData(uint64_t height, std::string hash);

private:
    uint64_t 	topBlockHeight;		//The highest height that currently has a hash value
    std::string topBlockHash;			//The current hash value
    CTimer 		_timer;		        
	std::pair<uint64_t, std::string> tempTopDate; //Current temporary data
	std::mutex topDateMutex;		
	std::atomic<bool> isRunning;
};

/**
 * @brief       to other nodes get corresponds to height sum hash
 * 
 * @param       nodeId: Request data from these nodes
 * @param       msgId:  The identification of the data
 * @param       height: Gets the height of the data
 */
void checksumHashRequest(const std::string &nodeId, const std::string &msgId, uint64_t height);

/**
 * @brief       Send to other nodes sum hash
 * 
 * @param       nodeId: 	Request data node id
 * @param       msgId: 		The identification of the data
 * @param       height: 	send the height of the data	
 */
void sendChecksumHashAcknowledgment(const std::string &nodeId, const std::string &msgId, uint64_t height);

/**
 * @brief       
 * 
 * @param       msg: 
 * @param       msgdata: 
 * @return      int 
 */
int  handleGetCheckSumHashRequest(const std::shared_ptr<getCheckSumHashRequest> &msg, const MsgData &msgdata);

/**
 * @brief       
 * 
 * @param       msg: 
 * @param       msgdata: 
 * @return      int 
 */
int  handleChecksumHashAcknowledge(const std::shared_ptr<checksumHashAcknowledge> &msg, const MsgData &msgdata);

#endif