{
    "lookup-objects":[
        {
            "type":"answer-sequence",
            "name":"sf-hills",
            "content": {
                "options":[
                    {
                        "order":1,
                        "answer-text":"31",
                        "answer-id":"31hills",
                        "is-correct-answer":false
                    },
                    {
                        "order":2,
                        "answer-text":"43 (correct)",
                        "answer-id":"43hills",
                        "is-correct-answer":true
                    },
                    {
                        "order":3,
                        "answer-text":"61",
                        "answer-id":"61hills",
                        "is-correct-answer":false
                    }
                ]
            }
        },
        {
            "type":"answer-sequence",
            "name":"sf-bridges",
            "content": {
                "options":[
                    {
                        "order":1,
                        "answer-text":"Golden Gate Bridge (correct)",
                        "answer-id":"brooklynbridge",
                        "is-correct-answer":true
                    },
                    {
                        "order":2,
                        "answer-text":"Brooklyn Bridge",
                        "answer-id":"43hills",
                        "is-correct-answer":false
                    },
                    {
                        "order":3,
                        "answer-text":"London Bridge",
                        "answer-id":"londonbridge",
                        "is-correct-answer":false
                    }
                ]
            }
        },
        {
            "type":"answer-sequence",
            "name":"sf-size",
            "content": {
                "options":[
                    {
                        "order":1,
                        "answer-text":"7 square miles (correct)",
                        "answer-id":"7sqm",
                        "is-correct-answer":true
                    },
                    {
                        "order":2,
                        "answer-text":"14 square miles",
                        "answer-id":"14sqm",
                        "is-correct-answer":false
                    },
                    {
                        "order":3,
                        "answer-text":"21 square miles",
                        "answer-id":"21sqm",
                        "is-correct-answer":false
                    }
                ]
            }
        },
        {
            "type":"answer-sequence",
            "name":"sample-colors",
            "content": {
                "options":[
                    {
                        "order":1,
                        "answer-text":"Blue (correct)",
                        "answer-id":"blue",
                        "is-correct-answer":true
                    },
                    {
                        "order":2,
                        "answer-text":"Dog",
                        "answer-id":"dog",
                        "is-correct-answer":false
                    },
                    {
                        "order":3,
                        "answer-text":"Green (correct)",
                        "answer-id":"green",
                        "is-correct-answer":true
                    },
                    {
                        "order":4,
                        "answer-text":"Cat",
                        "answer-id":"cat",
                        "is-correct-answer":false
                    }
                ]
            }
        },
        {
            "type":"achievement-category",
            "name":"Sample",
            "content": {
            }
        }
    ],
    "learning-objects":[
        {
            "name" : "Resource Learning",
            "record-type" : "Resource",
            "duration" : 60,
            "description" : "Salesforce Developer force",
            "sync-progress" : false,
            "content" : {
                "name":"Resource Learning Sample",
                "resource-url":"https://developer.salesforce.com/?language=en",
                "training-params-url":true,
                "display-in-iframe":true,
                "description":null,
                "delegate-assignment-completion":false
            }
        },
        {
            "name" : "Resource Learning 2",
            "record-type" : "Resource",
            "duration" : 60,
            "description" : "Service cloud overview",
            "sync-progress" : false,
            "content" : {
                "name":"Resource Learning Sample 2",
                "resource-url":"https://www.youtube.com/embed/hwKFv9X1yhU",
                "training-params-url":true,
                "display-in-iframe":true,
                "description":null,
                "delegate-assignment-completion":false
            }
        },
        {
            "name" : "Task Learning",
            "record-type" : "Task",
            "duration" : 60,
            "description" : "Complete the Force.com Workbook",
            "sync-progress" : false,
            "content" : {
                "name":"Task Learning Sample",
                "resource-name":"Force.com workbook",
                "resource-url":"https://www.salesforce.com/us/developer/docs/workbook/index.htm",
                "training-params-url":true,
                "description":null
            }
        },
        {
            "name" : "Task Learning 2",
            "record-type" : "Task",
            "duration" : 60,
            "description" : "Complete the Service Cloud Workbook",
            "sync-progress" : false,
            "content" : {
                "name":"Task Learning Sample",
                "resource-name":"Service Cloud workbook",
                "resource-url":"https://www.salesforce.com/us/developer/docs/workbook_service_cloud/workbook_service_cloud.pdf",
                "training-params-url":true,
                "description":null
            }
        },
        {
            "name" : "Quiz Learning 1",
            "record-type" : "Quiz",
            "duration" : 60,
            "description" : "Sample Quiz",
            "sync-progress" : false,
            "content" : {
                "name":"Quiz Learning Sample",
                "passing-score":70.0,
                "max-attempts":20,
                "description":null,
                "question-lines" : [
                    {
                        "name" : "Page 1",
                        "order" : 1,
                        "description" :"Page 1 Description",
                        "questions" :[
                            {
                                "order" : 1,
                                "description" : "How many hills make up the San Francisco landscape?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-hills"
                            },
                            {
                                "order" : 2,
                                "description" : "Which of these famous bridges is located in San Francisco?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-bridges"
                            },
                            {
                                "order" : 3,
                                "description" : "How large is San Francisco?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-size"
                            }
                        ]
                    },
                    {
                        "name" : "Page 2",
                        "order" : 2,
                        "description" :"Page 2 Description",
                        "questions" :[
                            {
                                "order" : 1,
                                "description" : "Select the valid colors from the list:",
                                "type" : "SelectMultipleQuestion",
                                "answer-sequence" : "sample-colors"
                            },
                            {
                                "order" : 2,
                                "description" : "Are you happy to be here?",
                                "type" : "Boolean",
                                "correct-boolean" : "true"
                            }
                        ]
                    }
                ]
            }
        }
    ],
    "achievement-objects":[
        {
            "name" : "Sample Achievement",
            "type" : "Achievements",
            "achievement-category" : "Sample",
            "acquired-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo1.png\"></img>",
            "eligible-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo2.png\"></img>"
        },
        {
            "name" : "Sample Track Achievement",
            "type" : "Achievements",
            "achievement-category" : "Sample",
            "acquired-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo1.png\"></img>",
            "eligible-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo2.png\"></img>"
        }
    ],
    "plan-objects":[
        {
            "name" : "Sample Training Plan",
            "description" : "Sample Training Plan description",
            "status" : "Active",
            "enforce-sequence" : true,
            "enable-self-registration" : false,
            "self-registration-access" : null,
            "sections" : [
                {
                    "name" : "Section 1",
                    "order" : 1,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Resource Learning"
                        },
                        {
                            "order" : 2,
                            "learning" : "Task Learning"
                        }
                    ]
                },
                {
                    "name" : "Section 2",
                    "order" : 2,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Resource Learning 2"
                        },
                        {
                            "order" : 2,
                            "learning" : "Task Learning 2"
                        }
                    ]
                },
                {
                    "name" : "Section 3",
                    "order" : 3,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Quiz Learning 1"
                        }
                    ]
                }
            ],
            "achievements" : [
                {
                    "achievement" : "Sample Achievement",
                    "main-achievement" : true,
                    "section" : null
                }
            ]
        }
    ],
    "track-objects":[
        {
            "name" : "Sample Track",
            "description" : "Sample Track description",
            "status" : "Active",
            "order" : null,
            "background-image-url" : null,
            "text-color-url" : null,
            "background-color" : null,
            "achievement" : "Sample Track Achievement",
            "levels" : [
                {
                    "name" : "Level 1",
                    "order" : 1,
                    "description" : "Sample Level 1 description",
                    "items" : [
                        {
                            "order" : 1,
                            "plan" : "Sample Training Plan"
                        }
                    ]
                }
            ]
        }
    ]

}
