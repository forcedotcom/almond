/*
Copyright (c) 2014, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public with sharing class LMS_ESAPI {

	public static void isAuthorizedToView(Map<Schema.sObjectType,List<String>> objectMap){
		for(Schema.sObjectType oType : objectMap.keySet()){
	        if(!ESAPI.accessController().isAuthorizedToView(oType,objectMap.get(oType))){
	        	throw new LMSException('View - Insufficent CRUD/FLS permissions, please contact your system administrator.');
	        }
		}
	}

	public static void isAuthorizedToCreate(Map<Schema.sObjectType,List<String>> objectMap){
		for(Schema.sObjectType oType : objectMap.keySet()){
	        if(!ESAPI.accessController().isAuthorizedToCreate(oType,objectMap.get(oType))){
	        	throw new LMSException('Create - Insufficent CRUD/FLS permissions, please contact your system administrator.');
	        }
		}
	}

	public static void isAuthorizedToUpdate(Map<Schema.sObjectType,List<String>> objectMap){
		for(Schema.sObjectType oType : objectMap.keySet()){
	        if(!ESAPI.accessController().isAuthorizedToUpdate(oType,objectMap.get(oType))){
	        	throw new LMSException('Update - Insufficent CRUD/FLS permissions, please contact your system administrator.');
	        }
		}
	}

	public static void isAuthorizedToDelete(List<Schema.sObjectType> sObjectTypes){
		for(Schema.sObjectType oType : sObjectTypes){
	        if(!ESAPI.accessController().isAuthorizedToDelete(oType)){
	        	throw new LMSException('Delete - Insufficent CRUD permissions, please contact your system administrator.');
	        }
		}
	}

}
