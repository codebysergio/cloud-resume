const counter = document.quervSelector(".counter-number");
async function updateCounter() {
    let response = await fetch(
        "https://ko23zv3jgl3tzp4tgnf56olyzm0yogzb.lambda-url.us-east-1.on.aws/"
    );
    let data = await response.json();
    console.log(data);
    counter.innerHTML = ' Views: ${data}';
}

updateCounter();