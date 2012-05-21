// Copyright 2012 Citrix Systems, Inc. Licensed under the
// Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.  Citrix Systems, Inc.
// reserves all rights not expressly granted by the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 
// Automatically generated by addcopyright.py at 04/03/2012
package com.cloud.network.vpc;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.cloud.exception.ConcurrentOperationException;
import com.cloud.exception.InsufficientCapacityException;
import com.cloud.exception.ResourceUnavailableException;
import com.cloud.network.Network;
import com.cloud.network.Network.Provider;
import com.cloud.network.Network.Service;

/**
 * @author Alena Prokharchyk
 */
public interface VpcService {
    
    public VpcOffering getVpcOffering(long vpcOfferingId);
    
    public VpcOffering createVpcOffering(String name, String displayText, List<String> supportedServices);
    
    public Vpc getVpc(long vpcId);
        
    public List<Network> getVpcNetworks(long vpcId);
    
    Map<Service, Set<Provider>> getVpcOffSvcProvidersMap(long vpcOffId);
    
    List<? extends VpcOffering> listVpcOfferings(Long id, String name, String displayText, List<String> supportedServicesStr, 
            Boolean isDefault, String keyword, String state, Long startIndex, Long pageSizeVal);

    /**
     * @param offId
     * @return
     */
    public boolean deleteVpcOffering(long offId);

    /**
     * @param vpcOffId
     * @param vpcOfferingName
     * @param displayText
     * @param state
     * @return
     */
    public VpcOffering updateVpcOffering(long vpcOffId, String vpcOfferingName, String displayText, String state);

    /**
     * @param zoneId
     * @param vpcOffId
     * @param vpcOwnerId
     * @param vpcName
     * @param displayText
     * @param cidr
     * @return
     */
    public Vpc createVpc(long zoneId, long vpcOffId, long vpcOwnerId, String vpcName, String displayText, String cidr);

    /**
     * @param vpcId
     * @return
     */
    public boolean deleteVpc(long vpcId);

    /**
     * @param vpcId
     * @param vpcName
     * @param displayText
     * @return
     */
    public Vpc updateVpc(long vpcId, String vpcName, String displayText);

    /**
     * @param id
     * @param vpcName
     * @param displayText
     * @param supportedServicesStr
     * @param cidr
     * @param state TODO
     * @param accountName
     * @param domainId
     * @param keyword
     * @param startIndex
     * @param pageSizeVal
     * @param zoneId TODO
     * @param isRecursive TODO
     * @param listAll TODO
     * @param vpc
     * @return
     */
    public List<? extends Vpc> listVpcs(Long id, String vpcName, String displayText, 
            List<String> supportedServicesStr, String cidr, Long vpcOffId, String state, String accountName, Long domainId,
            String keyword, Long startIndex, Long pageSizeVal, Long zoneId, Boolean isRecursive, Boolean listAll);

    /**
     * @param vpcId
     * @return
     * @throws InsufficientCapacityException 
     * @throws ResourceUnavailableException 
     * @throws ConcurrentOperationException 
     */
    Vpc startVpc(long vpcId) throws ConcurrentOperationException, ResourceUnavailableException, InsufficientCapacityException;

}
