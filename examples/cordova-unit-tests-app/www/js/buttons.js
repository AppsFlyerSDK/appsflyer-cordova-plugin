//Button Functions
let trackEventBtn = document.getElementById('logEvent');

if (trackEventBtn) {
    alert("Inapp button pressed")
    trackEventBtn.addEventListener('click', logEvent, false);
}

function logEvent(eventName, eventValues) {
    eventName = 'af_content_view';
    eventValues = {
        'af_content_id': 'id123',
        'af_currency': 'USD',
        'af_content_type': 'shoes',
        'af_revenue': '10',
    };
    window.plugins.appsFlyer.logEvent(eventName, eventValues, callBackFunction, callBackFunction);
}

function setHost() {
    let prefix = "foo"
    let name = "bar"
    window.plugins.appsflyer.setHost(prefix, name)
}

function callBackFunction(id) {
    alert('received: ' + id);
}