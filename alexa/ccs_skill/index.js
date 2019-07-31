const Alexa = require('ask-sdk-core');
var https = require('https');

// --[ SECTION 1 Parameters ] -------------------------------------------------------------------------------
const CCS_HOST_URL      = 'ccs5-demo.cisco.com'
const CCSTENANTPATH     = '/suite-idm/api/v1/tenants/';
const CCSCLOUDPATH      = '/cloudcenter-cloud-setup/api/v1/tenants/1/clouds';
const CCSAPPSPATH       = '/cloudcenter-ccm-backend/api/v2/apps'
const CCSCOSTPATH       = '/cloudcenter-shared-api/api/v1/costByProvider?cloudGroupId'

const CCS_ICON          = 'https://ccsalexa.s3.amazonaws.com/img/ccs_logo.png'
const CCS_CO_ICON       = 'https://ccsalexa.s3.amazonaws.com/img/ccs_co_icon.png'
const CCS_WM_ICON       = 'https://ccsalexa.s3.amazonaws.com/img/ccs_wm_icon.png'
const CCS_BKG_IMG       = 'https://ccsalexa.s3.amazonaws.com/img/ccs_background.png'
const SKILL_NAME        = 'CloudCenter Suite Skill'
const ICON_PATH         = 'https://ccsalexa.s3.amazonaws.com/img/'



var testingOnSim        = false; //flip to experience voice only skill on display device/simulator
var DEBUG               = true; // flip to activate debug logging 




// --[ SECTION 2 Custom Intent Handler ] ----------------------------------------------------------------------
// Custom Intent Request to handle the intents configured in the Interaction model. For each of 
// the intent you've configured, make sure you have a valid handler.

 
 // --[ Initial Request ]-------------------------------------------------
const LaunchRequestHandler = {
    canHandle(handlerInput) {
        return handlerInput.requestEnvelope.request.type === 'LaunchRequest';
    },
    handle(handlerInput) {
        const speechText = `Welcome to ${SKILL_NAME}`; 
        const attributes = handlerInput.attributesManager.getSessionAttributes();
        var reprompt = "You can ask me about cost, cloud and workloads";
        return showSkillIntro(speechText, reprompt, handlerInput);
    }
};


// --[ CostIntent ]-------------------------------------------------
const CostIntentHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
        && request.intent.name === 'CostIntent';
    },
    
   async handle(handlerInput) {
        var speechText          = 'Okay, here is the details.';
        var cloudCostArray      = [];
        const remoteResponse    = await httpGet(CCSCOSTPATH);
        
        // @todo - This cloud be place in a separate function
        for (var i=0; i < remoteResponse.details.length; i ++) {
            speechText += `${roundUp( remoteResponse.details[i].cost, 2)}  ${remoteResponse.currency} with ${remoteResponse.details[i].cloudFamily} <break time= "50ms"/>`;
            DEBUG && console.log('------------------------>' + speechText)
            cloudCostArray.push({ 
                "token": remoteResponse.details[i].cloudFamily,
                "textContent": new Alexa.PlainTextContentHelper()
                    .withPrimaryText(remoteResponse.details[i].cloudFamily)
                    .withSecondaryText(null)
                    .withTertiaryText(roundUp( remoteResponse.details[i].cost, 2) + ' ' +remoteResponse.currency ).getTextContent(),
                "image": imageCloudMaker("", remoteResponse.details[i].cloudFamily)
            })
            DEBUG && console.log('------------------------> Completed cycle ' + i)
        }
        DEBUG && console.log('------------------------> cloudCostArray is: ' + JSON.stringify(cloudCostArray) );
        return listTemplateMaker('ListTemplate1', handlerInput, cloudCostArray, 'Cost Information', speechText, CCS_BKG_IMG );
    }
};


// --[ CloudIntent ]-------------------------------------------------
const CloudIntentHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
        && request.intent.name === 'CloudIntent';
 
    },
    
   async handle(handlerInput) {
        var cloudArray = [];
        const remoteResponse = await httpGet(CCSCLOUDPATH);
        DEBUG && console.log('------------------------>' + remoteResponse.size);
        var speechText = `Okay. You have ${remoteResponse.clouds.length} clouds: `;
        // This coould be place in a separate function
        for (var i=0; i < remoteResponse.clouds.length; i ++) {
            speechText += `${remoteResponse.clouds[i].cloudFamily}, configured as ${remoteResponse.clouds[i].name}`;
            DEBUG && console.log('------------------------>' + speechText)
            cloudArray.push({ 
                "token": remoteResponse.clouds[i].cloudFamily,
                "textContent": new Alexa.PlainTextContentHelper()
                    .withPrimaryText(remoteResponse.clouds[i].cloudFamily)
                    .withSecondaryText(remoteResponse.clouds[i].name)
                    .withTertiaryText(null ).getTextContent(),
                "image": imageCloudMaker("", remoteResponse.clouds[i].cloudFamily)
            })
        }
        return listTemplateMaker('ListTemplate1', handlerInput, cloudArray, 'Cost Information', speechText, CCS_BKG_IMG );
    }
};


// --[ ApplicationIntent ]-------------------------------------------------
const ApplicationIntentHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
        && request.intent.name === 'applicationIntent';
 
    },
    
   async handle(handlerInput) {
        const response = await httpGet(CCSAPPSPATH);
        var speechText = `Okay. You have ${response.appsV2Responses.length} applications: `;
        DEBUG && console.log('------------------------>' + response.size)
        var applicationsArray = [];
        
        for (var i=0; i < response.appsV2Responses.length; i ++) {
            speechText += `${response.appsV2Responses[i].appName},`;
            DEBUG && console.log('------------------------>' + speechText)
            speechText += `${response.appsV2Responses[i].appName},\n`;
            applicationsArray.push({ 
                "token": response.appsV2Responses[i].appName,
                "textContent": new Alexa.PlainTextContentHelper()
                    .withPrimaryText(response.appsV2Responses[i].appName)
                    .withSecondaryText(null)
                    .withTertiaryText(null ).getTextContent(),
                "image": imageMaker("", CCS_WM_ICON)
            })
        }
        DEBUG && console.log('------------------------> applicationsArrayis: ' + JSON.stringify(applicationsArray) );
        return listTemplateMaker('ListTemplate1', handlerInput, applicationsArray, 'Application Information', speechText, CCS_BKG_IMG );
    }
};

// --[ ListTenantIntent ]-------------------------------------------------
const ListTenantIntentHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest'
        && request.intent.name === 'ListTenantIntent';
 
    },
    
   async handle(handlerInput) {
        const speechText = 'Here is the list of tenants';
        const response = await httpGet(CCSTENANTPATH);
        DEBUG && console.log('hello-------------------------------->' + response.length);
        return handlerInput.responseBuilder
            .speak(`Okay. Here is what I got back from my request. You have ${response.length} tenants`)
            .reprompt("What would you like?")
            .getResponse();
    }
};


// --[ SECTION 3 Default Alexa Intent Handler ] ----------------------------------------------------------------------
/**
 * Default Alexa Intent Handler 
 */
const HelpIntentHandler = {
    canHandle(handlerInput) {
        return handlerInput.requestEnvelope.request.type === 'IntentRequest'
            && handlerInput.requestEnvelope.request.intent.name === 'AMAZON.HelpIntent';
    },
    handle(handlerInput) {
        const speechText = 'You can say hello to me! How can I help?';

        return handlerInput.responseBuilder
            .speak(speechText)
            .reprompt(speechText)
            .getResponse();
    }
};
const CancelAndStopIntentHandler = {
    canHandle(handlerInput) {
        return handlerInput.requestEnvelope.request.type === 'IntentRequest'
            && (handlerInput.requestEnvelope.request.intent.name === 'AMAZON.CancelIntent'
                || handlerInput.requestEnvelope.request.intent.name === 'AMAZON.StopIntent');
    },
    handle(handlerInput) {
        const speechText = 'Goodbye!';
        return handlerInput.responseBuilder
            .speak(speechText)
            .getResponse();
    }
};
const SessionEndedRequestHandler = {
    canHandle(handlerInput) {
        return handlerInput.requestEnvelope.request.type === 'SessionEndedRequest';
    },
    handle(handlerInput) {
        // Any cleanup logic goes here.
        return handlerInput.responseBuilder.getResponse();
    }
};

// The intent reflector is used for interaction model testing and debugging.
// It will simply repeat the intent the user said. You can create custom handlers
// for your intents by defining them above, then also adding them to the request
// handler chain below.
const IntentReflectorHandler = {
    canHandle(handlerInput) {
        return handlerInput.requestEnvelope.request.type === 'IntentRequest';
    },
    handle(handlerInput) {
        const intentName = handlerInput.requestEnvelope.request.intent.name;
        const speechText = `You just triggered ${intentName}`;

        return handlerInput.responseBuilder
            .speak(speechText)
            //.reprompt('add a reprompt if you want to keep the session open for the user to respond')
            .getResponse();
    }
};

// Generic error handling to capture any syntax or routing errors. If you receive an error
// stating the request handler chain is not found, you have not implemented a handler for
// the intent being invoked or included it in the skill builder below.
const ErrorHandler = {
    canHandle() {
        return true;
    },
    handle(handlerInput, error) {
        console.log(`~~~~ Error handled: ${error.message}`);
        const speechText = `Sorry, I couldn't understand what you said. Please try again.`;

        return handlerInput.responseBuilder
            .speak(speechText)
            .reprompt(speechText)
            .getResponse();
    }
};

// This handler acts as the entry point for your skill, routing all request and response
// payloads to the handlers above. Make sure any new handlers or interceptors you've
// defined are included below. The order matters - they're processed top to bottom.
exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(
        LaunchRequestHandler,
        ListTenantIntentHandler,
        HelpIntentHandler,
        CancelAndStopIntentHandler,
        SessionEndedRequestHandler,
        CloudIntentHandler,
        CostIntentHandler,
        ApplicationIntentHandler,
        IntentReflectorHandler) // make sure IntentReflectorHandler is last so it doesn't override your custom intent handlers
    .addErrorHandlers(
        ErrorHandler)
    .lambda();


// --[ SECTION 4 Custom functions ] ----------------------------------------------------------------------
/**
 * 
 * @param {*} pSpeechOutput The text played by Alexa
 * @param {*} pReprompt The text reprompted by Alexa
 * @param {*} pHandlerInput The handler 
 */
function showSkillIntro(pSpeechOutput, pReprompt, pHandlerInput) {
    var speechOutput = pSpeechOutput || '';
    var reprompt = pReprompt
    var cardTitle = SKILL_NAME;

   
    if (supportsDisplay(pHandlerInput) && !testingOnSim) {
        DEBUG && console.log('Yup we have display');
        //Selectable text - need to remove it
        var actionText1 = 'CloudCenter Suite';
        var actionText2 = '<action value="quiz_token"><i>Item 2</i></action>';
        // this is just an example to show rich text
        var text = '<u><font size="7">CloudCenter Suite</font></u><br/><br/>Delivered with love by Cisco RMLAB';
        return bodyTemplateMaker('BodyTemplate3', pHandlerInput, CCS_ICON, cardTitle, text, null, null, speechOutput, reprompt, null, CCS_BKG_IMG, false);
    } else {
        const response = pHandlerInput.responseBuilder;
        return response
            .speak(speechOutput)
            .reprompt(reprompt)
            .getResponse();
    }
}

/**
 * 
 * @param {*} pBodyTemplateType The Alexa template you want to use
 * @param {*} pHandlerInput The handler
 * @param {*} pImg The icon used in the list
 * @param {*} pTitle Tne title of the template
 * @param {*} pText1 
 * @param {*} pText2 
 * @param {*} pText3 
 * @param {*} pOutputSpeech 
 * @param {*} pReprompt 
 * @param {*} pHint Hints should be used for optional content and to delight customers, and not for important information
 * @param {*} pBackgroundIMG The background image 
 * @param {*} pEndSession 
 */
function bodyTemplateMaker(pBodyTemplateType, pHandlerInput, pImg, pTitle, pText1, pText2, pText3, pOutputSpeech, pReprompt, pHint, pBackgroundIMG, pEndSession) {
    const response = pHandlerInput.responseBuilder;
    const image = imageMaker("", pImg);
    const richText = richTextMaker(pText1, pText2, pText3);
    const backgroundImage = imageMaker("", pBackgroundIMG);
    const title = pTitle;

    response.addRenderTemplateDirective({
        type: pBodyTemplateType,
        backButton: 'visible',
        image,
        backgroundImage,
        title,
        textContent: richText,
    });

    if (pHint)
        response.addHintDirective(pHint);

    if (pOutputSpeech)
        response.speak(pOutputSpeech);

    if (pReprompt)
        response.reprompt(pReprompt)

    if (pEndSession)
        response.withShouldEndSession(pEndSession);

    return response.getResponse();
}

function richTextMaker(pPrimaryText, pSecondaryText, pTertiaryText) {
    const myTextContent = new Alexa.RichTextContentHelper();

    if (pPrimaryText)
        myTextContent.withPrimaryText(pPrimaryText);

    if (pSecondaryText)
        myTextContent.withSecondaryText(pSecondaryText);

    if (pTertiaryText)
        myTextContent.withTertiaryText(pTertiaryText);

    return myTextContent.getTextContent();
}

// returns true if the skill is running on a device with a display (show|spot)
function supportsDisplay(handlerInput) {
	var hasDisplay =
	  handlerInput.requestEnvelope.context &&
	  handlerInput.requestEnvelope.context.System &&
	  handlerInput.requestEnvelope.context.System.device &&
	  handlerInput.requestEnvelope.context.System.device.supportedInterfaces &&
	  handlerInput.requestEnvelope.context.System.device.supportedInterfaces.Display
	return hasDisplay;
  }



//--[ Helper functions ]-------------------------------------------------

/**
 * 
 * @param {*} thePath the path of the request
 */
function httpGet(thePath) {
  return new Promise(((resolve, reject) => {
    process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;
    const CCS_USER_ID = "ADD_USER_ID";
    const CCS_API_KEY = "ADD_API_KEY";
    var ccOptions = {
      host: CCS_HOST_URL,
      port: 443,
      path: thePath,
      headers: {
          'Authorization': 'Basic ' + new Buffer(`${CCS_USER_ID}:${CCS_API_KEY}`).toString('base64'),
          'Content-Type': 'application/json Accept: application/json'
      }
    };
    
    const request = https.request(ccOptions, (response) => {
      let returnData = '';

      response.on('data', (chunk) => {
        returnData += chunk;
      });

      response.on('end', () => {
        resolve(JSON.parse(returnData));
      });

      response.on('error', (error) => {
        reject(error);
      });
    });
    request.end();
  }));
}

/**
 * 
 * @param {*} pListTemplateType the type of AWS template 
 * @param {*} pHandlerInput the Handler 
 * @param {*} pArray the formatted array
 * @param {*} pTitle the Title
 * @param {*} pOutputSpeech text play by Alexa
 * @param {*} pBackgroundIMG the background image
 */
function listTemplateMaker(pListTemplateType, pHandlerInput, pArray, pTitle, pOutputSpeech, pBackgroundIMG ) {
    const response = pHandlerInput.responseBuilder;
    const backgroundImage = imageMaker("", pBackgroundIMG);

    if (pOutputSpeech) {
        response.speak(pOutputSpeech);
        DEBUG && console.log('------------------------> found outpout speech: ' + pOutputSpeech);
    }

    response.addRenderTemplateDirective({
        type: pListTemplateType,
        backButton: 'hidden',
        backgroundImage,
        pTitle,
        listItems: pArray,
    });

    return response.getResponse();
}
/**
 * 
 * @param {*} pDesc 
 * @param {*} pSource 
 */
function imageMaker(pDesc, pSource) {
    const myImage = new Alexa.ImageHelper()
        .withDescription(pDesc)
        .addImageInstance(pSource)
        .getImage();

    return myImage;
}

/**
 * 
 * @param {*} pDesc 
 * @param {*} pSource 
 */
function imageCloudMaker(pDesc, pSource) {
    console.log("pDesc:" + pDesc + ', pSource:' + pSource);
    const myImage = new Alexa.ImageHelper()
        .withDescription(pDesc)
        .addImageInstance(ICON_PATH + pSource + '_icon.png')
        .getImage();

    return myImage;
}


/**
 * 
 * @param {*} num The number to round
 * @param {*} precision The number of decimal places to preserve
 */
function roundUp(num, precision) {
  precision = Math.pow(10, precision)
  return Math.ceil(num * precision) / precision
}

/**
 * 
 * @param {*} pName Name of the image
 * @param {*} pImageURL URL of the image
 * @param {*} pInfo Additional information releated to the image
 */
function createArrayValue(pName, pImageURL, pInfo) //object creation
{
    var value = {
        name: pName,
        imageURL: pImageURL,
        info: pInfo,
        token: pName + 'Token',
    };

    return value;
}

/**
 * This function will return text as PlainTextContent used in listTemplate
 * @param {*} pPrimaryText The Primary text used
 * @param {*} pSecondaryText The secondary text
 * @param {*} pTertiaryText he tertiary text
 */
function plainTextMaker(pPrimaryText, pSecondaryText, pTertiaryText) {
    const myTextContent = new Alexa.PlainTextContentHelper()
        .withPrimaryText(pPrimaryText)
        .withSecondaryText(pSecondaryText)
        .withTertiaryText(pTertiaryText)
        .getTextContent();

    return myTextContent;
}