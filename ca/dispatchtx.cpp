#include "ca/dispatchtx.h"
#include "include/logging.h"

void ContractDispatcher::Process()
{
    _dispatcherThread = std::thread(std::bind(&ContractDispatcher::dispatcherProcessingFunc, this));
    _dispatcherThread.detach();
}
void ContractDispatcher::dispatcherProcessingFunc()
{
    uint64_t timeBaseline = 0;
    while (true)
    {
        usleep(1000000);
        {
            std::unique_lock<std::mutex> locker(contractInfoCacheMutex);
            if (contractDependentCache.empty())
            {
                continue;
            }
        }

        if(timeBaseline == 0)
        {
            timeBaseline = MagicSingleton<TimeUtil>::GetInstance()->getTimestampPerUnit(timeValue);
            auto s1 = MagicSingleton<TimeUtil>::GetInstance()->FormatUTCTimestamp(timeValue);
            auto s2 = MagicSingleton<TimeUtil>::GetInstance()->FormatUTCTimestamp(timeBaseline);
            DEBUGLOG("FFF OOOOOOOO, currentTime:{}, timeBaseline:{}", s1, s2);
        }
        /*
            A = Transaction reception time in 10 seconds (time interval between two dispatchers' packaging) = Switching dispatcher time (10 seconds)
            B = Delay in distribution and packaging after receiving the transaction by the dispatcher in 5 seconds
            C = B (Fastest transaction confirmation time)
            D = A + B (Slowest transaction confirmation time)
        */
        if (timeValue >= timeBaseline + contractWaitingTime)
        {
            std::unique_lock<std::mutex> lock(contractHandleMutex);
            DEBUGLOG("************** time out 10s");
   
            std::multimap<std::string, msgInfo> distribution;
            auto ret = distributionContractTransactionRequest(distribution);
            if(ret != 0)
            {
                ERRORLOG("++++++++++++++++ distributionContractTransactionRequest error ret :{} ++++++++++++++++++", ret);
                continue;;
            }

            if(distribution.empty())
            {
                ERRORLOG("++++++++++++++++ distribution empty ++++++++++++++++++");
            }

            for(auto & item : distribution)
            {
                DEBUGLOG("-0-0-0-0-0-0-0-0- send packager : {}, Number of transactions: {} ", item.first, item.second.txMsgReq.size());
                for(auto & txmsg : item.second.txMsgReq)
                {
                CTransaction contractTx;
                if (!contractTx.ParseFromString(txmsg.txmsginfo().tx()))
                {
                    ERRORLOG("Failed to deserialize transaction body!");
                    continue;
                }
                DEBUGLOG("send packager : {} , tx hash : {}", item.first, contractTx.hash());
                }
                sendTransactionInfoRequest(item.first, item.second.txMsgReq);
            }

            

            std::scoped_lock locker(contractInfoCacheMutex,contractMessageMutex,_mtx);
            contractMessageRequestCache.clear();
            contractDependentCache.clear();
            timeBaseline = 0;
            timeValue = 0;
            isFirst = false;
        }else
        {
            timeValue+= 1000000;
            DEBUGLOG("timeValue+= 500000");
        }

    }
}


void ContractDispatcher::AddContractInfo(const std::string& contractHash, const std::vector<std::string>& dependentContracts)
{
    std::unique_lock<std::mutex> locker(contractInfoCacheMutex);
    contractDependentCache.insert(std::make_pair(contractHash, dependentContracts));
}


void ContractDispatcher::addContractMessageRequest(const std::string& contractHash, const contractTransactionMessageRequest &msg)
{
    std::unique_lock<std::mutex> locker(contractMessageMutex);
    TxMsgReq  txmsg = msg.txmsgreq();

    contractMessageRequestCache.insert(std::make_pair(contractHash, txmsg));
}

bool ContractDispatcher::HasDuplicate(const std::vector<std::string>& v1, const std::vector<std::string>& v2)
{
	std::unordered_set<std::string> set;

	for (const std::string& s : v1) {
		set.insert(s);
	}

	for (const std::string& s : v2) {
		if (set.count(s) > 0) {
			return true;
		}
	}

	return false;
}

int ContractDispatcher::sendTransactionInfoRequest(const std::string &packager, std::vector<TxMsgReq> &txsMsg)
{
    DEBUGLOG("***** sendTransactionInfoRequest *****");
    contractPackagerMessage msg;
    msg.set_version(global::kVersion);

    for(auto & msgReq : txsMsg)
    {
        TxMsgReq * _Msg = msg.addTxMessageRequest();
        _Msg -> CopyFrom(msgReq);
    }

    
    std::string owner = MagicSingleton<AccountManager>::GetInstance()->GetDefaultAddr();
    std::string vinHashSerialized = Getsha256hash(msg.SerializeAsString());
    std::string signature;
    std::string pub;
    if (TxHelper::Sign(owner, vinHashSerialized, signature, pub) != 0)
    {
        ERRORLOG("sign fail");
        return -1;
    }
    
    CSign * Sign = msg.mutable_sign();
    Sign->set_sign(signature);
    Sign->set_pub(pub);

    if(owner == packager)
    {
        DEBUGLOG("sendTransactionInfoRequest onwer : {} , packager : {}", owner, packager);
        auto sendTxmsg = std::make_shared<contractPackagerMessage>(msg);
        MsgData msgdata;
        handleContractPackagerMessage(sendTxmsg,msgdata);
        return 0;
    }
	NetSendMessage<contractPackagerMessage>(packager, msg, net_com::Compress::COMPRESS_TRUE, net_com::Encrypt::ENCRYPT_FALSE, net_com::Priority::PRIORITY_HIGH_LEVEL_1);
    return 0;
}

std::vector<std::vector<TxMsgReq>> ContractDispatcher::GetDependentData()
{
    DEBUGLOG("DependencyGrouping");
    std::vector<std::set<std::string>> groupedDependencies;
	for (const auto& [key, values] : contractDependentCache) {
		std::set<std::string> commonKeys;
		commonKeys.insert(key);
        //Check for duplicate dependencies
		for (const auto& [otherKey, otherValues] : contractDependentCache) {
			if (key == otherKey)  continue;

			if (HasDuplicate(values, otherValues) == true)
			{
				commonKeys.insert(otherKey);
			}
		}
        //If there are common dependencies, deal with them
		if (!commonKeys.empty()) {
			bool foundDuplicate = false;
			// Check for duplicates with previous data
			for (auto& itemSet : groupedDependencies) {
                
				std::set<std::string> intersection;
				std::set_intersection(
					itemSet.begin(), itemSet.end(),
					commonKeys.begin(), commonKeys.end(),
					std::inserter(intersection, intersection.begin())
				);

				if (!intersection.empty()) {
                //There are duplicates with the previous data, inserted into the original array
					foundDuplicate = true;
					itemSet.insert(commonKeys.begin(), commonKeys.end());
					break;
				}
			}
			//There is no duplication with the previous data, create a new array to insert
			if (!foundDuplicate) {
				groupedDependencies.push_back(commonKeys);
			}
		}
	}
    // Transform dependency data into message data
    std::vector<std::vector<TxMsgReq>> groupedTransmissionMessage;
    for(const auto & hashContainer : groupedDependencies)
    {
        std::vector<TxMsgReq> messageVec;
        for(const auto & hash : hashContainer)
        {
            if(contractMessageRequestCache.count(hash) == 0) {
                continue;
            }
            messageVec.emplace_back(contractMessageRequestCache.at(hash));
        }
        if(messageVec.size() != 0)
        {
            groupedTransmissionMessage.push_back(messageVec);
        }
    }
    return groupedTransmissionMessage;
}

std::vector<std::vector<TxMsgReq>> ContractDispatcher::groupData(const std::vector<std::vector<TxMsgReq>> & txMessageVector)
{
    //Protocol to group
    int size = txMessageVector.size();
    int parts = 8;

    std::vector<std::vector<TxMsgReq>> sendGroupMessage;
    if(size <= parts)
    {
        //No segmentation is needed when the threshold is insufficient
        for(const auto & hashContainer : txMessageVector)
        {
            sendGroupMessage.emplace_back(hashContainer);
        }
    }
    else
    {
        int perPart = size / parts;
        int remain = size % parts;

        int index = 0;

        for(int i = 0; i < parts; i++) {
            std::vector<TxMsgReq> part;
            for(int j = index; j < index + perPart; j++) 
            {
                for(auto& txMsg : txMessageVector[j])
                {
                    part.push_back(txMsg);
                }
            }

            index += perPart;
            //If you have any left over you add the rest of this section to the first section
            if(remain > 0) 
            {
                for(int j = index; j < index + remain; j++)
                {
                    for(auto& txMsg : txMessageVector[j])
                    {
                        part.push_back(txMsg);
                    }
                }
                index += remain;
                remain = 0;
            }
            sendGroupMessage.push_back(part);
        }
    }
    return sendGroupMessage;
}

int ContractDispatcher::distributionContractTransactionRequest(std::multimap<std::string, msgInfo>& distribution)
{
    //1.Fetching dependent data
    std::vector<std::vector<TxMsgReq>> dependentData = GetDependentData();
    if(dependentData.empty())
    {
        ERRORLOG("DependencyGrouping dependentData  is empty");
        return -1;
    }
    //2.Group dependent data
    std::vector<std::vector<TxMsgReq>> groupedData = groupData(dependentData);
    if(groupedData.empty())
    {
        ERRORLOG("groupData groupedData is empty");
        return -2;
    }
    //3.Iterate over the grouped data to find the packager
    for(const auto & sendMessageContainer : groupedData)
    { 
        std::string contractHash;
        std::vector<TxMsgReq> txMsgData;
        std::vector<uint64_t> txTimestamps;
        for(const auto & txMsg : sendMessageContainer)
        {
            CTransaction ContractTx;
            if (!ContractTx.ParseFromString(txMsg.txmsginfo().tx()))
            {
                ERRORLOG("Failed to deserialize transaction body!");
                return -3;
            }
            contractHash += ContractTx.hash();
            txMsgData.push_back(txMsg);
            txTimestamps.push_back(ContractTx.time());
        }
        
        auto maxIterator = std::max_element(txTimestamps.begin(), txTimestamps.end());
        uint64_t maxTxTime = 0;
        if (maxIterator != txTimestamps.end()) {
            maxTxTime = *maxIterator;
        }
    
        std::string input = Getsha256hash(contractHash);
        
        std::string packAddr;
        auto ret = FindContractPackNode(input, maxTxTime, packAddr);
        if(ret != 0)
        {
            ERRORLOG("distributionContractTransactionRequest ret :{}", ret);
            continue;
        }

        msgInfo msg;
        msg.txMsgReq = txMsgData;
        distribution.insert(std::make_pair(packAddr, msg));
    }
    
    if(distribution.empty())
    {
        ERRORLOG("distributionContractTransactionRequest error , distribution is empty");
        return -4;
    }

    return 0;
}

void ContractDispatcher::setValue(const uint64_t& newValue) {
    std::unique_lock<std::mutex> lock(_mtx);
    if (!isFirst) {
        timeValue = newValue;
        isFirst = true;
    }
}
