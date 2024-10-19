import { LightningElement, track, api } from 'lwc';
import sendQueryToApi from '@salesforce/apex/ComponentsalesforceCodeInterpreter.sendQueryToApi';
import createNewThread from '@salesforce/apex/ComponentsalesforceCodeInterpreter.createNewThread';
import endThreadHandle from '@salesforce/apex/ComponentsalesforceCodeInterpreter.endThreadHandle';
import getRes from '@salesforce/apex/ComponentsalesforceCodeInterpreter.getRes';
import checkRun from '@salesforce/apex/ComponentsalesforceCodeInterpreter.checkRun';
import getRunStep from '@salesforce/apex/ComponentsalesforceCodeInterpreter.getRunStep';
import getImageUrl from '@salesforce/apex/ComponentsalesforceCodeInterpreter.getImageUrl';

export default class OpenAIAssistant extends LightningElement {
    @track query = '';
    @track response = '';
    @track runID = '';
    @track initialData = '';
    @track conversation = '';
    @track convArray = [];
    @track waitingConvArray = [];
    @api assistantID;
    @api assistHeader;
    @api assistPlaceholder;
    @track imageUrl = '';
    @track textValue;
    @track cvID;
    
    isFirstExecution = true;

    connectedCallback() {
        this.createThread();
    }

    handleEnter(event){
        if(event.keyCode === 13){
            this.handleButtonClick();
        }
    }

    createThread() {
        createNewThread()
            .then(response => {
                this.initialData = response;
            })
            .catch(error => {
                this.initialData = 'Error in fetching initial data: ' + error.body.message;
            });
    }

    handleInputChange(event) {
        this.query = event.target.value;
    }

    endChatHandler(){
        if(this.initialData){
            endThreadHandle({ threadid: this.initialData})
            .then(response => {
                    if(response === true){
                        this.conversation = [];
                        this.convArray = [];
                        this.connectedCallback();
                    }
                })
                .catch(error => {
                    this.response = 'Error in sending query: ' + error.body.message;
                });
        }
    }

    handleButtonClick() {
        this.isFirstExecution = true;
        const button = this.template.querySelector('lightning-button');
        var qryMessage = this.query;
        this.query = null;
        button.disabled = true;
        if (qryMessage) {
            this.convArray.push({type: 'user', message : qryMessage, iconName: 'standard:avatar', iconAlt: 'UserIcon', isUser: true,isAssistant: false});
            this.conversation = this.convArray;
            sendQueryToApi({ query: qryMessage,  threadid: this.initialData, asstID: this.assistantID})
                .then(response => {
                    this.runID = response;
                    this.checkCompletionStatus();
                    this.addConvWaiting();
                })
                .catch(error => {
                    this.response = 'Error in sending query: ' + error.body.message;
                });
        } else {
            this.response = 'Query is empty';
        }
    }

    


    checkCompletionStatus() {
        setTimeout(() => {
            checkRun({ runId: this.runID, threadId: this.initialData })
                .then(secondResponse => {
                    if (secondResponse == 'completed') {
                        this.getThreadMessages(this.initialData);
                    } else {
                        this.getRunSteps();
                        this.checkCompletionStatus();
                    }
                })
                .catch(error => {
                    console.error('Error in second Apex call: ', error.body.message);
                });
        }, 2000);
    }

    getRunSteps(){
        getRunStep({ runId: this.runID, threadId: this.initialData })
                .then(secondResponse => {
                    if(secondResponse != null && secondResponse != ''){
                         if (this.isFirstExecution) {
                            this.conversation.pop();
                            this.isFirstExecution = false; 
                        }
                        if (this.convArray.length === 0 || this.convArray[this.convArray.length - 1].message !== secondResponse) {
                            this.convArray.push({type: 'assistant', message : secondResponse, iconName: 'standard:bot', iconAlt: 'Assistant', isUser: false, isAssistant: true});
                        }
                        this.conversation = this.convArray;
                    }
                    
                })
                .catch(error => {
                    console.error('Error in second Apex call: ', error.body.message);
                });
    }

    addConvWaiting(){
        this.waitingConvArray.push(
                                {
                                    type: 'assistant', 
                                    message : '........', 
                                    iconName: 'standard:bot', 
                                    iconAlt: 'Assistant', 
                                    isUser: false,
                                    isAssistant: true
                                }
                            );
        this.conversation.push(this.waitingConvArray[0]);
    }


    getThreadMessages(threadId) {
        getRes({ threadid: threadId, allOrOne: false})
                .then(response => {
                    this.textValue = response.textValue;
                    this.cvID = response.cvID;
                    this.conversation.pop();
                    this.convArray.push({type: 'assistant', message : this.textValue, iconName: 'standard:bot', iconAlt: 'Assistant', isUser: false,
                        isAssistant: true});
                    this.conversation = this.convArray;
                    if(this.cvID != null &&  this.cvID != ''){
                        getImageUrl({cvID : this.cvID })
                        .then(imageResponse  => {
                            this.imageUrl = imageResponse ;
                        })
                        .catch(error => {
                            this.conversation = 'Error in sending query: ' + error.body.message;
                        });
                    }
                    
                    const button = this.template.querySelector('lightning-button');
                    button.disabled = false;
                })
                .catch(error => {
                    this.conversation = 'Error in sending query: ' + error.body.message;
                });
    }


}