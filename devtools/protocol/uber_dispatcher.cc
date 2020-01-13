//
// Created by rowandjj on 2019/4/2.
//

#include "devtools/protocol/uber_dispatcher.h"

namespace kraken{
    namespace Debugger {
        UberDispatcher::UberDispatcher(Debugger::FrontendChannel *frontendChannel)
                :m_frontendChannel(frontendChannel) {
        }

        UberDispatcher::~UberDispatcher() = default;

        void UberDispatcher::registerBackend(const std::string &name,
                                             std::unique_ptr<Debugger::DispatcherBase> dispatcher) {

            m_dispatchers[name] = std::move(dispatcher);
        }

        void UberDispatcher::setupRedirects(
                const std::unordered_map<std::string, std::string> &redirects) {
            for(const auto& pair : redirects) {
                m_redirects[pair.first] = pair.second;
            }
        }

        bool UberDispatcher::canDispatch(const std::string &in_method) {
            std::string method = in_method;
            auto redirectIt = m_redirects.find(method);
            if(redirectIt != m_redirects.end()) {
                method = redirectIt->second;
            }
            return findDispatcher(method) != nullptr;

        }

        void UberDispatcher::dispatch(uint64_t callId, const std::string &in_method,
                                      Debugger::jsonRpc::JSONObject message) {
            std::string method = in_method;
            auto redirectIt = m_redirects.find(method);
            if (redirectIt != m_redirects.end()) {
                method = redirectIt->second;
            }
            auto dispatcher = findDispatcher(method);
            if(!dispatcher) {
                Internal::reportProtocolErrorTo(m_frontendChannel,
                                                callId,
                                                jsonRpc::kMethodNotFound,
                                                "'" + method + "' wasn't found",
                                                nullptr);
                return;
            }
            dispatcher->dispatch(callId, method, std::move(message));
        }

        /**
         * method格式: domain.command。
         * 如 Debugger.setPauseOnExceptions
         *
         * */
        //private
        Debugger::DispatcherBase* UberDispatcher::findDispatcher(const std::string &method) {
            auto dotIndex = method.find('.');
            if(dotIndex == std::string::npos) {
                return nullptr;
            }
            std::string domain = method.substr(0,dotIndex);
            auto it = m_dispatchers.find(domain);
            if(it == m_dispatchers.end()) {
                return nullptr;
            }
            if(!it->second->canDispatch(method)) {
                KRAKEN_LOG(ERROR) << "can not dispatch method: " << method;
                return nullptr;
            }
            return it->second.get();
        }

    }
}



