/*
 * ServiceDirectory.h
 *
 *  Created on: Jun 28, 2012
 *      Author: Mark Barger
 */

#ifndef SERVICEDIRECTORY_H_
#define SERVICEDIRECTORY_H_

#include <string>
#include <list>
#include <map>
#include "GravityDataProduct.h"

using namespace std;

namespace gravity
{

class ServiceDirectory
{
private:
    map<string, list<string> > dataProductMap;
    map<string, string> serviceMap;
public:
    ServiceDirectory();
    virtual ~ServiceDirectory();
    void start();

private:
    void handleLookup(const GravityDataProduct& request, GravityDataProduct& response);
    void handleRegister(const GravityDataProduct& request, GravityDataProduct& response);
    void handleUnregister(const GravityDataProduct& request, GravityDataProduct& response);
};

} /* namespace gravity */
#endif /* SERVICEDIRECTORY_H_ */
