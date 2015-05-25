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
                        "answer-text":"43 (correcta)",
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
                        "answer-text":"Golden Gate Bridge (correcta)",
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
                        "answer-text":"7 millas cuadradas (correcta)",
                        "answer-id":"7sqm",
                        "is-correct-answer":true
                    },
                    {
                        "order":2,
                        "answer-text":"14 millas cuadradas",
                        "answer-id":"14sqm",
                        "is-correct-answer":false
                    },
                    {
                        "order":3,
                        "answer-text":"21 millas cuadradas",
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
                        "answer-text":"Azul (correcta)",
                        "answer-id":"blue",
                        "is-correct-answer":true
                    },
                    {
                        "order":2,
                        "answer-text":"Perro",
                        "answer-id":"dog",
                        "is-correct-answer":false
                    },
                    {
                        "order":3,
                        "answer-text":"Verde (correcta)",
                        "answer-id":"green",
                        "is-correct-answer":true
                    },
                    {
                        "order":4,
                        "answer-text":"Gato",
                        "answer-id":"cat",
                        "is-correct-answer":false
                    }
                ]
            }

        }
    ],
    "learning-objects":[
        {
            "name" : "Recurso de Aprendizaje",
            "record-type" : "Resource",
            "duration" : 60,
            "description" : "Salesforce Developer force",
            "sync-progress" : false,
            "content" : {
                "name":"Muestra de Recurso de Aprendizaje",
                "resource-url":"https://developer.salesforce.com/?language=en",
                "training-params-url":true,
                "display-in-iframe":true,
                "description":null,
                "delegate-assignment-completion":false
            }
        },
        {
            "name" : "Recurso de Aprendizaje 2",
            "record-type" : "Resource",
            "duration" : 60,
            "description" : "Service cloud",
            "sync-progress" : false,
            "content" : {
                "name":"Muestra de Recurso de Aprendizaje 2",
                "resource-url":"https://www.youtube.com/embed/hwKFv9X1yhU",
                "training-params-url":true,
                "display-in-iframe":true,
                "description":null,
                "delegate-assignment-completion":false
            }
        },
        {
            "name" : "Tarea",
            "record-type" : "Task",
            "duration" : 60,
            "description" : "Completar los ejercicios de Force.com",
            "sync-progress" : false,
            "content" : {
                "name":"Tarea de Muestra",
                "resource-name":"Workbook de Force.com",
                "resource-url":"https://www.salesforce.com/us/developer/docs/workbook/index.htm",
                "training-params-url":true,
                "description":null
            }
        },
        {
            "name" : "Tarea 2",
            "record-type" : "Task",
            "duration" : 60,
            "description" : "Completar los ejercicios de Service Cloud",
            "sync-progress" : false,
            "content" : {
                "name":"Tarea de Muestra",
                "resource-name":"Workbook de Service Cloud",
                "resource-url":"https://www.salesforce.com/us/developer/docs/workbook_service_cloud/workbook_service_cloud.pdf",
                "training-params-url":true,
                "description":null
            }
        },
        {
            "name" : "Evaluación 1",
            "record-type" : "Quiz",
            "duration" : 60,
            "description" : "Evaluación de Muestra",
            "sync-progress" : false,
            "content" : {
                "name":"Evaluación de Muestra",
                "passing-score":70.0,
                "max-attempts":20,
                "description":null,
                "question-lines" : [
                    {
                        "name" : "Página 1",
                        "order" : 1,
                        "description" :"Descripción Página 1",
                        "questions" :[
                            {
                                "order" : 1,
                                "description" : "¿Cuantas montañas puedes encontrar en San Francisco?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-hills"
                            },
                            {
                                "order" : 2,
                                "description" : "¿Cuál de los siguientes puentes está ubicado en San Francisco?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-bridges"
                            },
                            {
                                "order" : 3,
                                "description" : "¿Que tan grande es San Francisco?",
                                "type" : "SelectOneQuestion",
                                "answer-sequence" : "sf-size"
                            }
                        ]
                    },
                    {
                        "name" : "Página 2",
                        "order" : 2,
                        "description" :"Descripción Página 2",
                        "questions" :[
                            {
                                "order" : 1,
                                "description" : "Selecciona los colores de la lista:",
                                "type" : "SelectMultipleQuestion",
                                "answer-sequence" : "sample-colors"
                            },
                            {
                                "order" : 2,
                                "description" : "¿Estas feliz de estar aqui?",
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
            "name" : "Logro de Muestra",
            "type" : "Achievements",
            "acquired-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo1.png\"></img>",
            "eligible-image" : "<img alt=\"User-added image\" src=\"/resource/almond_uilib/img/sampleLogo2.png\"></img>"
        }
    ],
    "plan-objects":[
        {
            "name" : "Curso de muestra",
            "description" : "Descripción de curso de muestra",
            "status" : "Active",
            "enforce-sequence" : false,
            "enable-self-registration" : false,
            "self-registration-access" : null,
            "sections" : [
                {
                    "name" : "Sección 1",
                    "order" : 1,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Recurso de Aprendizaje"
                        },
                        {
                            "order" : 2,
                            "learning" : "Tarea"
                        }
                    ]

                },
                {
                    "name" : "Sección 2",
                    "order" : 2,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Recurso de Aprendizaje 2"
                        },
                        {
                            "order" : 2,
                            "learning" : "Tarea 2"
                        }
                    ]

                },
                {
                    "name" : "Sección 3",
                    "order" : 3,
                    "items" : [
                        {
                            "order" : 1,
                            "learning" : "Evaluación 1"
                        }
                    ]

                }
            ],
            "achievements" : [
                {
                    "achievement" : "Logro de Muestra",
                    "main-achievement" : true,
                    "section" : null
                }
            ]
        }
    ]

}
