/** (C) Copyright 2013, Applied Physical Sciences Corp., A General Dynamics Company
 **
 ** Gravity is free software; you can redistribute it and/or modify
 ** it under the terms of the GNU Lesser General Public License as published by
 ** the Free Software Foundation; either version 3 of the License, or
 ** (at your option) any later version.
 **
 ** This program is distributed in the hope that it will be useful,
 ** but WITHOUT ANY WARRANTY; without even the implied warranty of
 ** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ** GNU Lesser General Public License for more details.
 **
 ** You should have received a copy of the GNU Lesser General Public
 ** License along with this program;
 ** If not, see <http://www.gnu.org/licenses/>.
 **
 */

// all imports required in the generated Python SWIG code
%pythonbegin %{
import abc, logging
from GravityDataProduct import GravityDataProduct 
%}

// give this type the highest precedence for comparison purposes
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) const gravity::GravityDataProduct&  {
	PyObject* pyStr = PyObject_CallMethod($input, (char*)"getDataProductID", NULL);
	$1 = pyStr ? 1 : 0;
	Py_XDECREF(pyStr);
}

// This is where the conversion from Python GDP to C++ GDP occurs
%typemap(in) const gravity::GravityDataProduct&  {
	PyObject* pyStr = PyObject_CallMethod($input, (char*)"serializeToString", NULL);
	if (!pyStr) SWIG_fail;
	char* data = PyString_AsString(pyStr);
    int length = (int) PyString_Size(pyStr);
	$1 = new gravity::GravityDataProduct((void *)data, length);
	Py_XDECREF(pyStr);
}

// delete the C++ GDP allocated above 
%typemap(freearg) const gravity::GravityDataProduct&  {
    if ($1 != 0) delete $1;
}

%typemap(out) shared_ptr<gravity::GravityDataProduct> {
    char* buffer = new char[$1->getSize()];
    $1->serializeToArray(buffer);
    $result = PyString_FromStringAndSize(buffer, $1->getSize());
    delete[] buffer;
}

// this turns on director features for GravityHeartbeatListener
%feature("director") gravity::GravityHeartbeatListener;
	

// This is where we actually declare GravityNode and the basic enums that will be made available in Python.  This section must be kept in
// sync with the Gravity API.
namespace gravity {

	namespace GravityReturnCodes {
		enum Codes {
	        SUCCESS = 0,
	        FAILURE = -1,
	        NO_SERVICE_DIRECTORY = -2,
	        REQUEST_TIMEOUT = -3,
	        DUPLICATE = -4,
	        REGISTRATION_CONFLICT = -5,
	        NOT_REGISTERED = -6,
	        NO_SUCH_SERVICE = -7,
	        LINK_ERROR = -8,
	        INTERRUPTED = -9,
	        NO_SERVICE_PROVIDER = -10,
	        NO_PORTS_AVAILABLE = -11,
			INVALID_PARAMETER = -12
	    };
	};
	typedef GravityReturnCodes::Codes GravityReturnCode;
	
	
	namespace GravityTransportTypes
	{
	    enum Types {
	        TCP = 0,
	        INPROC = 1,
	        PGM = 2,
	        EPGM= 3,
	#ifndef WIN32
	        IPC = 4
	#endif
	    };
    };
	typedef GravityTransportTypes::Types GravityTransportType;

    // rename the request methods so that we can wrap the call in %pythoncode (below) 
	%rename(requestBinary) GravityNode::request;
	
	class GravityNode {
	public:
	    GravityNode();
		GravityNode(std::string);
	    ~GravityNode();
		GravityReturnCode init();
	    GravityReturnCode init(std::string);
	    void waitForExit();
		GravityReturnCode registerDataProduct(const std::string& dataProductID, const GravityTransportType& transportType);
	    GravityReturnCode registerDataProduct(const std::string& dataProductID, const GravityTransportType& transportType, bool cacheLastValue);    
		GravityReturnCode unregisterDataProduct(const std::string& dataProductID);
	
		GravityReturnCode subscribe(const std::string& dataProductID, const gravity::GravitySubscriber& subscriber);
		GravityReturnCode subscribe(const std::string& dataProductID, const gravity::GravitySubscriber& subscriber, const std::string& filter);
		GravityReturnCode subscribe(const std::string& dataProductID, const gravity::GravitySubscriber& subscriber, const std::string& filter, const std::string& domain);
		GravityReturnCode subscribe(const std::string& dataProductID, const gravity::GravitySubscriber& subscriber, const std::string& filter, const std::string& domain, bool receiveLastCachedValue);
	    
	    GravityReturnCode unsubscribe(const std::string& dataProductID, const gravity::GravitySubscriber& subscriber, const std::string& filter = "", const std::string& domain = "");
	
	    GravityReturnCode publish(const gravity::GravityDataProduct& dataProduct, const std::string& filter = "", unsigned long timestamp = 0);
	
	    GravityReturnCode request(const std::string& serviceID, const gravity::GravityDataProduct& dataProduct,
		        const gravity::GravityRequestor& requestor, const std::string& requestID = "", int timeout_milliseconds = -1, const std::string& domain = "");

	    shared_ptr<gravity::GravityDataProduct> request(const std::string& serviceID, const gravity::GravityDataProduct& request, int timeout_milliseconds = -1, const std::string& domain = "");
	    %pythoncode %{
            # The above request methods will both be renamed as requestBinary.  This provides a request method in the Python API that wraps the requestBinary
            # call and converts the serialized GDP into a Python GDP in the case of the synchronous request.
            def request(self, *args):
                ret = self.requestBinary(*args)
                
                # We only need to convert the return value in the synchronous case, which means no GravityRequestor arg
                synchronous = True
                for arg in args:
                    if isinstance(arg, GravityRequestor):
                        synchronous = False
                if synchronous:
                    ret = GravityDataProduct(data=ret)
                return ret
        %}
	
	    GravityReturnCode registerService(const std::string& serviceID, const GravityTransportType& transportType,
	    		const gravity::GravityServiceProvider& server);
	    GravityReturnCode unregisterService(const std::string& serviceID);

	    GravityReturnCode startHeartbeat(unsigned long interval_in_microseconds);
	    GravityReturnCode stopHeartbeat();
	    GravityReturnCode registerHeartbeatListener(const std::string& dataProductID, long timebetweenMessages, 
			const gravity::GravityHeartbeatListener& listener, const std::string& domain = "");
		GravityReturnCode unregisterHeartbeatListener(const std::string& dataProductID, const std::string &domain = "");
	
	    std::string getStringParam(std::string key, std::string default_value = "");
	    int getIntParam(std::string key, int default_value = -1);
	    double getFloatParam(std::string key, double default_value = 0.0);
	    bool getBoolParam(std::string key, bool default_value = false);
	    std::string getComponentID();
		std::string getIP();
	    std::string getDomain();

/*	Not yet implemented
	    shared_ptr<gravity::FutureResponse> createFutureResponse();
		GravityReturnCode sendFutureResponse(const gravity::FutureResponse& futureResponse);
		GravityReturnCode setSubscriptionTimeoutMonitor(const std::string& dataProductID, const gravity::GravitySubscriptionMonitor& monitor, 
				int milliSecondTimeout, const std::string& filter="", const std::string& domain="");
		GravityReturnCode clearSubscriptionTimeoutMonitor(const std::string& dataProductID, const gravity::GravitySubscriptionMonitor& monitor, 
				const std::string& filter="", const std::string& domain="");
*/
	};
	
	class GravityHeartbeatListener
	{
	public:
		virtual void MissedHeartbeat(std::string componentID, int64_t microsecond_to_last_heartbeat, int64_t& interval_in_microseconds) = 0;
		virtual void ReceivedHeartbeat(std::string componentID, int64_t& interval_in_microseconds) = 0;
		virtual ~GravityHeartbeatListener();
	};
	
};