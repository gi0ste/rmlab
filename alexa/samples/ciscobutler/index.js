const Alexa = require('ask-sdk-core');
const axios = require('axios')
const shortid = require('shortid')
process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0';

// --[ SECTION 1 PARAMETERS USED FOR CONNECTIONS ] -------------------------------------------------------------------------------
const CCS_HOST_URL              = 'ADD_YOUR_CCS_HOST'
const CCS_CLOUD_PATH            = '/cloudcenter-cloud-setup/api/v1/tenants/1/clouds'
const CCS_DEPLOY_PATH           = '/cloudcenter-ccm-backend/api/v2/jobs'
const CCS_COST_PATH             = '/cloudcenter-shared-api/api/v1/costByProvider?cloudGroupId'
const CCS_USERNAME              = 'ADD_YOUR_CCS_USERNAME'
const CCS_USERNAME_APY_KEY      = 'ADD_YOUR_CCS_API_KEY'

const CWOM_HOST_URL             = 'ADD_YOUR_CWOM_HOST'
const CWOM_ACTIONS_LIST_URL     = '/markets/_0x3OYUglEd-gHc4L513yOA/actions/stats'
const CWOM_FULL_ACTIONS_LIST    = '/markets/_0x3OYUglEd-gHc4L513yOA/actions?limit=50&order_by=severity&ascending=true'
const CWOM_ACTION_STATS         = '/markets/_0x3OYUglEd-gHc4L513yOA/actions/stats'
const CWOM_USERNAME             = 'ADD_YOUR_CWOM_USERNAME'
const CWOM_USERNAME_APY_KEY     = 'ADD_YOUR_CWOM_PASSWORD'

var DEBUG                       = true; // flip to activate debug logging


// --[ Initial Request ]-------------------------------------------------
const LaunchRequestHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'LaunchRequest';
    },
    handle(handlerInput) {
        const speakOutput = 'Welcome, I am your Cisco Butler. As of today, I support Cloud Center Suite: so you can ask me about how many clouds are configured';
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// --[ SECTION 2 Custom Intent Handler ] ----------------------------------------------------------------------
// Custom Intent Request to handle the intents configured in the Interaction model. For each of
// the intent you've configured, make sure you have a valid handler.

// --[ CloudInfoIntent ]-------------------------------------------------
const CloudInfoIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest' &&
            Alexa.getIntentName(handlerInput.requestEnvelope) === 'CloudInfoIntent';
    },
    async handle(handlerInput) {
        try {
            const response = await makeGetRequest(CCS_HOST_URL + CCS_CLOUD_PATH, CCS_USERNAME, CCS_USERNAME_APY_KEY);
            var speechText = `Okay. You have ${response.clouds.length} clouds: `;
            for (var i = 0; i < response.clouds.length; i++) {
                speechText += `${response.clouds[i].cloudFamily}, configured as ${response.clouds[i].name},`;
            }
            return handlerInput.responseBuilder
                .speak(speechText)
                .withSimpleCard('Inspiration', speechText)
                .getResponse();
        } catch (error) {
            console.error(error);
        }
    }
};


// --[ ActionsIntent ]-------------------------------------------------
const ActionsIntentIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest' &&
            Alexa.getIntentName(handlerInput.requestEnvelope) === 'ActionsIntent';
    },
    async handle(handlerInput) {
        try {
            const response = await makePostRequest(CWOM_HOST_URL + CWOM_ACTION_STATS, CWOM_USERNAME, CWOM_USERNAME_APY_KEY, "{}");
            var speechText = `Okay. You have ${response[0].statistics[0].value} actions: wow you should have a look `;
            speechText += `You can have a one time Estimated Savings of ${response[0].statistics[1].value} USD `
            speechText += `and one time Estimated Cost of ${response[0].statistics[3].value} USD`
            console.log(`Speech Text: ${speechText}`)

            // var speechText = "yup"
            return handlerInput.responseBuilder
                .speak(speechText)
                .withSimpleCard('Inspiration', speechText)
                .getResponse();
        } catch (error) {
            console.error(error);
        }
    }
};


// --[ CostReportIntent ]-------------------------------------------------
const CostReportIntentHandler = {
    canHandle(handlerInput) {
        const request = handlerInput.requestEnvelope.request;
        return request.type === 'IntentRequest' &&
            request.intent.name === 'CostReportIntent';
    },

    async handle(handlerInput) {
        try {
            var speechText = 'Okay, here is the details.';
            var cloudCostArray = [];
            const remoteResponse = await makeGetRequest(CCS_HOST_URL + CCS_COST_PATH, CCS_USERNAME, CCS_USERNAME_APY_KEY);

            // @todo - This cloud be place in a separate function
            for (var i = 0; i < remoteResponse.details.length; i++) {
                speechText += `${roundUp( remoteResponse.details[i].cost, 2)}  ${remoteResponse.currency} with ${remoteResponse.details[i].cloudFamily} <break time= "50ms"/>`;
                DEBUG && console.log('------------------------>' + speechText)
                DEBUG && console.log('------------------------> Completed cycle ' + i)
            }

            DEBUG && console.log('------------------------> cloudCostArray is: ' + JSON.stringify(cloudCostArray));
            return handlerInput.responseBuilder
                .speak(speechText)
                .withSimpleCard('Inspiration', speechText)
                .getResponse();
        } catch (error) {
            console.error(error);
        }
    }
}

// --[ SECTION 3 Custom Functions ----------------------------------------------------------------------

const makeGetRequest = async (pURL, pUserName, pPassword) => {
  DEBUG && console.log("pURL:" + pURL)
  try {
    var options = {
            auth: {
                username: pUserName,
                password: pPassword
            }
        }
    const { data } = await axios.get('https://' + pURL, options);
    console.log("Data received: " + JSON.stringify(data, null, 2) )
    return data;
  } catch (error) {
    console.error('cannot fetch data', error);
  }
};


const makePostRequest = async (pURL, pUserName, pPassword, pData) => {
    console.log("pURL:" + pURL)
    try {
        var options = {
            auth: {
                username: pUserName,
                password: pPassword
            },
            headers: {
                'Content-Type': 'application/json'
            }
        }
        console.log(`===[ \nReady to make a POST to URL: ${pURL}, \nUsername: ${pUserName}, \nwith ${pPassword} password\n and with data ${pData}`)

        let res = await axios.post('https://' + pURL, pData, options);

        DEBUG && console.log(`Status code: ${res.status}`);
        DEBUG && console.log(`Status text: ${res.statusText}`);
        DEBUG && console.log(`Request method: ${res.request.method}`);
        DEBUG && console.log(`Path: ${res.request.path}`);
        DEBUG && console.log(`Date: ${res.headers.date}`);
        DEBUG && console.log(`Data: ${res.data}`);

        console.log("Data received: " + JSON.stringify(res.data, null, 2))
        return res.data;
    } catch (error) {
        console.error('cannot fetch data', error);
    }
};

/**
 *
 * @param {*} num The number to round
 * @param {*} precision The number of decimal places to preserve
 */
function roundUp(num, precision) {
  precision = Math.pow(10, precision)
  return Math.ceil(num * precision) / precision
}













// --[ SECTION 4 Default Alexa Intent Handler ] ----------------------------------------------------------------------

const HelpIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.HelpIntent';
    },
    handle(handlerInput) {
        const speakOutput = 'You can say hello to me! How can I help?';

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};
const CancelAndStopIntentHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest'
            && (Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.CancelIntent'
                || Alexa.getIntentName(handlerInput.requestEnvelope) === 'AMAZON.StopIntent');
    },
    handle(handlerInput) {
        const speakOutput = 'Goodbye!';
        return handlerInput.responseBuilder
            .speak(speakOutput)
            .getResponse();
    }
};
const SessionEndedRequestHandler = {
    canHandle(handlerInput) {
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'SessionEndedRequest';
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
        return Alexa.getRequestType(handlerInput.requestEnvelope) === 'IntentRequest';
    },
    handle(handlerInput) {
        const intentName = Alexa.getIntentName(handlerInput.requestEnvelope);
        const speakOutput = `You just triggered ${intentName}`;

        return handlerInput.responseBuilder
            .speak(speakOutput)
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
        console.log(`~~~~ Error handled: ${error.stack}`);
        const speakOutput = `Sorry, I had trouble doing what you asked. Please try again.`;

        return handlerInput.responseBuilder
            .speak(speakOutput)
            .reprompt(speakOutput)
            .getResponse();
    }
};

// The SkillBuilder acts as the entry point for your skill, routing all request and response
// payloads to the handlers above. Make sure any new handlers or interceptors you've
// defined are included below. The order matters - they're processed top to bottom.
exports.handler = Alexa.SkillBuilders.custom()
    .addRequestHandlers(
        LaunchRequestHandler,
        CloudInfoIntentHandler,
        ActionsIntentIntentHandler,
        CostReportIntentHandler,
        HelpIntentHandler,
        CancelAndStopIntentHandler,
        SessionEndedRequestHandler,
        IntentReflectorHandler, // make sure IntentReflectorHandler is last so it doesn't override your custom intent handlers
    )
    .addErrorHandlers(
        ErrorHandler,
    )
    .lambda();
