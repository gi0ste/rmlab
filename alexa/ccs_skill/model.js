{
    "interactionModel": {
        "languageModel": {
            "invocationName": "cloudcentersuite",
            "intents": [
                {
                    "name": "AMAZON.CancelIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.HelpIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.StopIntent",
                    "samples": []
                },
                {
                    "name": "ListTenantIntent",
                    "slots": [],
                    "samples": [
                        "get all tenants",
                        "get tenants",
                        "list all tenants",
                        "how many tenants are configured"
                    ]
                },
                {
                    "name": "AMAZON.NavigateHomeIntent",
                    "samples": []
                },
                {
                    "name": "CloudIntent",
                    "slots": [],
                    "samples": [
                        "tell me clouds ",
                        "which clouds are available",
                        "how many clouds we have "
                    ]
                },
                {
                    "name": "AddCloudRegionIntent",
                    "slots": [
                        {
                            "name": "cloudRegionName",
                            "type": "AMAZON.Region"
                        }
                    ],
                    "samples": [
                        "add region {cloudRegionName}"
                    ]
                },
                {
                    "name": "ApplicationIntent",
                    "slots": [],
                    "samples": [
                        "tell me more about applications",
                        "list applications"
                    ]
                },
                {
                    "name": "AMAZON.MoreIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.NavigateSettingsIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.NextIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.PageUpIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.PageDownIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.PreviousIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ScrollRightIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ScrollDownIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ScrollLeftIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ScrollUpIntent",
                    "samples": []
                },
                {
                    "name": "CostIntent",
                    "slots": [],
                    "samples": [
                        "show me the money",
                        "How much money have I spent this month",
                        "how much I spent this month"
                    ]
                }
            ],
            "types": [
                {
                    "name": "applicationNames",
                    "values": [
                        {
                            "name": {
                                "value": "WordPress"
                            }
                        },
                        {
                            "name": {
                                "value": "Ubuntu"
                            }
                        },
                        {
                            "name": {
                                "value": "Survivor"
                            }
                        },
                        {
                            "name": {
                                "value": "RedHat"
                            }
                        },
                        {
                            "name": {
                                "value": "OpenCart"
                            }
                        },
                        {
                            "name": {
                                "value": "Centos"
                            }
                        }
                    ]
                },
                {
                    "name": "cloudProviders",
                    "values": [
                        {
                            "name": {
                                "value": "GCP"
                            }
                        },
                        {
                            "name": {
                                "value": "Azure"
                            }
                        },
                        {
                            "name": {
                                "value": "AWS"
                            }
                        }
                    ]
                }
            ]
        }
    }
}