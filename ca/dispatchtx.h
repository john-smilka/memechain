#ifndef DISPATCHER_HEADER_PROTECTION
#define DISPATCHER_HEADER_PROTECTION
#include <mutex>
#include <thread>
#include <vector>
#include <functional>
#include <unordered_map>

#include "ca/global.h"
#include "ca/interface.h"
#include "ca/transaction.h"
#include "ca/transaction_cache.h"

class ContractDispatcher{

    public:
        ContractDispatcher() = default;
        ~ContractDispatcher() = default;
        /**
        * @brief       
        * 
        * @param       contractHash: 
        * @param       dependentContracts: 
        */
        void AddContractInfo(const std::string& contractHash, const std::vector<std::string>& dependentContracts);
        /**
        * @brief       
        * 
        * @param       contractHash: 
        * @param       msg: 
        */
        void addContractMessageRequest(const std::string& contractHash, const contractTransactionMessageRequest &msg);
        /**
        * @brief       
        */
        void Process();

        /**
        * @brief       
        * 
        * @param       v1: 
        * @param       v2: 
        * @return      true
        * @return      false  
        */
        bool HasDuplicate(const std::vector<std::string>& v1, const std::vector<std::string>& v2);
        void setValue(const uint64_t& newValue);
        
    private:
        constexpr static int contractWaitingTime = 3 * 1000000;

        struct msgInfo
        {
            std::vector<TxMsgReq> txMsgReq;//Transaction information protocol
        };
        /**
        * @brief       
        */
        void dispatcherProcessingFunc();

        /**
        * @brief       
        * 
        * @return      std::vector<std::vector<TxMsgReq>> 
        */
        std::vector<std::vector<TxMsgReq>> GetDependentData();
        /**
        * @brief       
        * 
        * @param       txMessageVector:
        * @return      std::vector<std::vector<TxMsgReq>>  
        */
        std::vector<std::vector<TxMsgReq>> groupData(const std::vector<std::vector<TxMsgReq>> & txMessageVector);
        /**
        * @brief       
        * 
        * @param       distribution:
        * @return      int 
        */
        int distributionContractTransactionRequest(std::multimap<std::string, msgInfo>& distribution);
        /**
        * @brief       Message the transaction information to the packer
        * 
        * @param       packager:
        * @param       info:
        * @param       txsMsg:
        * @param       nodeList:
        * @return      int 
        */
        int sendTransactionInfoRequest(const std::string &packager, std::vector<TxMsgReq> &txsMsg);

    private:
        std::thread _dispatcherThread;
        std::mutex contractInfoCacheMutex;
        std::mutex contractMessageMutex;
        std::mutex contractHandleMutex;
        std::mutex _mtx;

        bool isFirst = false;
        uint64_t timeValue;

        std::unordered_map<std::string/*txHash*/, std::vector<std::string>/*Contract dependency address*/> contractDependentCache; //The data received from the initiator is stored
        std::unordered_map<std::string, TxMsgReq> contractMessageRequestCache; //hash TxMsgReq

 

};

#endif