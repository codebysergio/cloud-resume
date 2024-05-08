async function updateCounter() {
    try{
        const response = await fetch("https://a2asabsi7pi2mpzswfynfkk56a0syiwm.lambda-url.us-east-1.on.aws/");
        if(!response.ok){
            throw new error("not found");
        }
        const data = await response.json();
        console.log(data.body);
        const views = ("Views = ", data.body);
        document.getElementById("counter").innerHTML = views

    }
    catch(error){
        console.error(error);

    }
}

updateCounter();