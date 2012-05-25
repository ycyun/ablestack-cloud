/*
 * Copyright (C) 2011 Citrix Systems, Inc.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.cloud.stack.models;

import com.google.gson.annotations.SerializedName;

/**
 * @author slriv
 *
 */
public class CloudStackOsType {
	@SerializedName(ApiConstants.ID)
	private String id;
	@SerializedName(ApiConstants.OS_CATEGORY_ID)
	private String osCategoryId;
	@SerializedName(ApiConstants.DESCRIPTION)
	private String description;

	/**
	 *  
	 */
	public CloudStackOsType() {
	}

	/**
	 * @return the id
	 */
	public String getId() {
		return id;
	}

	/**
	 * @return the osCategoryId
	 */
	public String getOsCategoryId() {
		return osCategoryId;
	}

	/**
	 * @return the description
	 */
	public String getDescription() {
		return description;
	}
}
