public class ComponentsalesforceCodeInterpreter {
    public static String API_KEY = Meta_Assistant__mdt.getInstance('Configs').OpenAI_API_Key__c;
    public static String OAIThreadURL = Meta_Assistant__mdt.getInstance('Configs').OpenAI_Assistant_Thread_EndPoint__c;
    private static final String OPENAI_API_URL = 'https://api.openai.com/v1/files/{file_id}/content';

    @AuraEnabled
    public static String createNewThread() {
        return sendHttpRequest(OAIThreadURL, 'POST', null, 200, 'Failed to create Thread. Status code: ', 'createNewThread','');
    }

    @AuraEnabled
    public static String sendQueryToApi(String query, String threadid, String asstID) {
        String runId = '';
        String endpoint = OAIThreadURL + '/' + threadid + '/messages';
        String requestBody = '{"role": "user", "content": "' + query + '"}';
        String msgID = sendHttpRequest(endpoint, 'POST', requestBody, 200, 'Not able to Run Assistant. Status code: ', 'sendQueryToApi','');
        if(String.isNotBlank(msgID)){
            runId = runAssistant(threadid, asstID);
        }
        return runId;
    }

    private static String runAssistant(String threadid, String asstID) {
        String runID = '';
        String endpoint = OAIThreadURL + '/' + threadid + '/runs';
        String requestBody = '{"assistant_id": "' + asstID + '"}';
        runID = sendHttpRequest(endpoint, 'POST', requestBody, 200, 'Failed to get response from API. Status code: ', 'runAssistant','');
        return runID;
    }

    @AuraEnabled
    public static String checkRun(String runId, String threadId) {
        String endpoint = OAIThreadURL + '/' + threadId + '/runs/' + runId;
        return sendHttpRequest(endpoint, 'GET', null, 200, 'Failed to check run status. Status code: ', 'checkRun','');
    }

    @AuraEnabled
    public static String getRunStep(String runId, String threadId) {
        String endpoint = OAIThreadURL + '/' + threadId + '/runs/' + runId + '/steps?order=desc&limit=1';
        String StepMessage = sendHttpRequest(endpoint, 'GET', null, 200, 'Failed to get run step. Status code: ', 'getRunStep',threadId);
        return StepMessage;
    }

    @AuraEnabled
    public static FileRespWrapper getRes(String threadid, boolean allOrOne) {
        String endpoint = allOrOne ? OAIThreadURL + '/' + threadid + '/messages' : OAIThreadURL + '/' + threadid + '/messages?limit=1';
        String response = sendHttpRequest(endpoint, 'GET', null, 200, 'Failed to get initial data from API. Status code: ', 'getRes','');
        return parseFileResponse(response);
    }

    @AuraEnabled
    public static String getImageUrl(String cvID) {
        ContentVersion contentVersion;
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        try {
            contentVersions = [SELECT Id, ContentDocumentId, VersionData, FileExtension FROM ContentVersion WHERE Id = :cvID LIMIT 1];
            if (contentVersions.isEmpty()) {
                throw new CalloutException('ContentVersion not found');
            }
            contentVersion = contentVersions[0];
            ContentDistribution cd = new ContentDistribution();
            cd.ContentVersionId = contentVersion.Id;
            cd.Name = 'Public Link';
            cd.PreferencesAllowOriginalDownload = true;
            cd.PreferencesAllowPDFDownload = true;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesLinkLatestVersion = true;
            insert cd;
        }catch (Exception e) {
            throw new CalloutException('Error occurred while Getting Image URL: ' + e.getMessage());
        }

        String base64Content = EncodingUtil.base64Encode(contentVersion.VersionData);
        String dataUriPrefix = getDataUriPrefix(contentVersion.FileExtension);
        return dataUriPrefix + base64Content;
    }

    @AuraEnabled
    public static String endThreadHandle(String threadid) {
        String endpoint = OAIThreadURL + '/' + threadid;
        String deleteStatus = sendHttpRequest(endpoint, 'DELETE', null, 200, 'Failed to Delete the Thread. Status code: ','endThreadHandle','');
        return deleteStatus;
    }

    private static String sendHttpRequest(String endpoint, String method, String body, Integer expectedStatusCode, String errorMessage, String methodName, String threadID) {
        String retVar = '';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('OpenAI-Beta', 'assistants=v2');
        request.setTimeout(120000);
        if (body != null) {
            request.setBody(body);
        }
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == expectedStatusCode) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if(methodName == 'createNewThread' || methodName == 'sendQueryToApi' || methodName == 'runAssistant'){
                    retVar = (String) responseMap.get('id');
                }else if(methodName == 'checkRun'){
                    retVar = (String) responseMap.get('status');
                }else if(methodName == 'getRunStep'){
                    List<Object> dataList = (List<Object>)responseMap.get('data');
                    for (Object dataItemObj : dataList) {
                        Map<String, Object> dataItem = (Map<String, Object>)dataItemObj;
                        Map<String, Object> stepDetails = (Map<String, Object>)dataItem.get('step_details');
                        String stepType = (String)stepDetails.get('type');
                        if (stepType == 'message_creation') {
                            Map<String, Object> messageCreation = (Map<String, Object>)stepDetails.get('message_creation');
                            String messageId = (String)messageCreation.get('message_id');
                            retVar = getRunStepMessage(threadID, messageId);
                        } else if (stepType == 'tool_calls') {
                            retVar = 'Executing and Interpreting Code.';
                        }
                    }
                }else if(methodName == 'getRes'){
                    retVar = response.getBody();
                }else if(methodName == 'endThreadHandle'){
                    retVar = responseMap.get('deleted').toString();
                }
                return retVar;
            } else {
                throw new CalloutException(errorMessage + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new CalloutException('Error occurred while sending request to API: ' + e.getMessage());
        }
    }

    private static String getRunStepMessage(String threadId, String messageID){
        String stepMessage = '';
        String endpoint = OAIThreadURL+'/'+threadId+'/messages/'+messageID;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        request.setHeader('OpenAI-Beta', 'assistants=v2');
        request.setTimeout(120000);
        try{
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getbody());
                    List<Object> contentList = (List<Object>) responseMap.get('content');
                    for (Object contentObj : contentList) {
                        Map<String, Object> contentMap = (Map<String, Object>) contentObj;
                        if (contentMap.get('type') == 'text') {
                            Map<String, Object> textMap = (Map<String, Object>) contentMap.get('text');
                            String textValue = (String) textMap.get('value');
                            stepMessage = textValue;

                        }
                    }
            }else {
                    throw new CalloutException('Failed to get initial data from API. Status code: ' + response.getStatusCode());
            }
        }catch (Exception e) {
            throw new CalloutException('Error occurred while Getting Step Messages: ' + e.getMessage());
        }
        return stepMessage;
    }

    private static FileRespWrapper parseFileResponse(String response) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        List<Object> dataList = (List<Object>) responseMap.get('data');
        String textValue = '';
        String fileId = '';
        String cvID = '';
        for (Object dataItem : dataList) {
            Map<String, Object> dataMap = (Map<String, Object>) dataItem;
            List<Object> contentList = (List<Object>) dataMap.get('content');
            List<Object> attachmentsList = (List<Object>) dataMap.get('attachments');
            if(attachmentsList.size() > 0){
                for (Object attachmentItem : attachmentsList) {
                    Map<String, Object> attachmentMap = (Map<String, Object>) attachmentItem;
                    fileId = (String) attachmentMap.get('file_id');
                }
                for (Object contentItem : contentList) {
                    Map<String, Object> contentMap = (Map<String, Object>) contentItem;
                    if ('text'.equals(contentMap.get('type'))) {
                        Map<String, Object> textMap = (Map<String, Object>) contentMap.get('text');
                        textValue = (String) textMap.get('value');
                    }
                }
                cvID = fetchFileContent(fileId);
            }else {
                for (Object contentItem : contentList) {
                    Map<String, Object> contentMap = (Map<String, Object>) contentItem;
                    if ('text'.equals(contentMap.get('type'))) {
                        Map<String, Object> textMap = (Map<String, Object>) contentMap.get('text');
                        textValue = (String) textMap.get('value');
                    }
                }
            }
            
        }
        return new FileRespWrapper(textValue, cvID);
    }


    private static String fetchFileContent(String fileId) {
        String cvID = '';
        String fURL = '';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(OPENAI_API_URL.replace('{file_id}', fileId));
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + API_KEY);
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Blob fileContent = response.getBodyAsBlob();
                cvID = saveFileInSalesforce(fileContent, fileId);
                return cvID;
            } else {
                return '';
            }
        } catch (Exception e) {
            throw new CalloutException('Error occurred while Saving the File: ' + e.getMessage());
        }
    }

    private static String saveFileInSalesforce(Blob fileContent, String fileName) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName +'.png';
        cv.VersionData = fileContent;
        cv.FirstPublishLocationId = UserInfo.getUserId();
        cv.NetworkId = '0DBJ1000000XZByOAO'; 
        cv.IsMajorVersion = true;
        insert cv;
        return cv.Id;
    }

    private static String getDataUriPrefix(String fileExtension) {
        if ('jpg'.equals(fileExtension) || 'jpeg'.equals(fileExtension)) {
            return 'data:image/jpeg;base64,';
        } else if ('png'.equals(fileExtension)) {
            return 'data:image/png;base64,';
        } else {
            return 'data:image;base64,';
        }
    }

    public class FileRespWrapper {
        @AuraEnabled public String textValue;
        @AuraEnabled public String cvID;

        public FileRespWrapper(String textValue, String cvID) {
            this.textValue = textValue;
            this.cvID = cvID;
        }
    }
}