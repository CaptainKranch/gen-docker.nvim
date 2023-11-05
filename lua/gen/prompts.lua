return {
    Generate = {prompt = "$input", replace = true},
    Summarize = {prompt = "Summarize the following text:\n$text"},
    Enhance_Grammar_Spelling = {
        prompt = "Modify the following text to improve grammar and spelling, just output the final text without additional quotes around it:\n$text",
        replace = true
    },
    Enhance_Wording = {
        prompt = "Modify the following text to use better wording, just output the final text without additional quotes around it:\n$text",
        replace = true
    },
    Make_Concise = {
        prompt = "Modify the following text to make it as simple and concise as possible, just output the final text without additional quotes around it:\n$text",
        replace = true
    },
    Make_List = {
        prompt = "Render the following text as a markdown list:\n$text",
        replace = true
    },
}
